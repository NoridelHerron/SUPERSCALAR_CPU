-----------------------------------------------------------------------------
-- Noridel Herron
-- 7/8/2025
-- Top
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;
--use work.MyFunctions.all;

entity main is  
    generic ( ENABLE_FORWARDING : boolean := true);
    Port ( 
            clk         : in  std_logic; 
            reset       : in  std_logic;
            if_ipcv     : out Inst_PC_N;
            id_ipcv     : out Inst_PC_N;
            id_value    : out DECODER_N_INSTR;
            id_cntrl    : out control_Type_N;
            id_haz      : out HDU_OUT_N;      
            id_datas    : out REG_DATAS;
            ex_ipcv     : out Inst_PC_N; 
            idex_value  : out DECODER_N_INSTR;
            idex_cntrl  : out control_Type_N;  
            idex_datas  : out REG_DATAS;
            ex_value    : out EX_CONTENT_N;
            memory_haz  : out HAZ_SIG; 
            mem_ipcv    : out Inst_PC_N; 
            exmem_value : out EX_CONTENT_N;  
            mem_value   : out std_logic_vector(DATA_WIDTH-1 downto 0); 
            wb_ipcv     : out Inst_PC_N; 
            memwb_value : out MEM_CONTENT_N;
            wb_value    : out WB_CONTENT_N_INSTR      
        );
end main;

architecture Behavioral of main is

signal if_reg        : Inst_PC_N          := EMPTY_Inst_PC_N;
signal ifid_reg      : Inst_PC_N          := EMPTY_Inst_PC_N;
signal id            : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal id_c          : control_Type_N     := EMPTY_control_Type_N;
signal haz           : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal datas         : REG_DATAS          := EMPTY_REG_DATAS;
signal idex_reg      : Inst_PC_N          := EMPTY_Inst_PC_N;
signal id_ex_val     : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal id_ex_c       : control_Type_N     := EMPTY_control_Type_N;
signal id_ex_datas   : REG_DATAS          := EMPTY_REG_DATAS;
signal ex_val        : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal ex_val_pass   : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal exmem_reg     : Inst_PC_N          := EMPTY_Inst_PC_N;
signal ex_mem_val    : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal memwb_reg     : Inst_PC_N          := EMPTY_Inst_PC_N;
signal mem_wb_val    : MEM_CONTENT_N      := EMPTY_MEM_CONTENT_N;
signal wb_val        : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;

signal mem_haz       : HAZ_SIG                                 := NONE_h;
signal mem_val_in    : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
signal mem_addr_in   : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
signal isLwOrSw      : CONTROL_SIG                             := NONE_c;
signal mem_val_out   : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;

begin
-------------------------------------------------------
-------------------- IF STAGE -------------------------
-------------------------------------------------------
    U_IF : entity work.IF_STAGE port map (
        clk      => clk,
        reset    => reset,
        -- output
        IF_STAGE => if_reg
    );
-------------------------------------------------------
------------------ IF/ID register ---------------------
-------------------------------------------------------
    U_IF_ID : entity work.IF_TO_ID port map (
        clk      => clk,
        reset    => reset,
        mem_haz  => mem_haz,
        if_stage => if_reg,
        -- output
        if_id    => ifid_reg
    );
-------------------------------------------------------
-------------------- ID STAGE -------------------------
-------------------------------------------------------
    U_ID : entity work.ID_STAGE port map (
        clk      => clk,
        instr1   => ifid_reg.A.instr,    
        instr2   => ifid_reg.B.instr,
        ID_EX    => id_ex_val,
        ID_EX_c  => id_ex_c,
        EX_MEM   => ex_mem_val,
        MEM_WB   => mem_wb_val,
        WB       => wb_val,
        -- outputs
        ID       => id,
        cntrl    => id_c,
        haz      => haz,
        datas    => datas
    );
    
-------------------------------------------------------
------------------ ID/EX register ---------------------
-------------------------------------------------------
    U_ID_EX : entity work.ID_EX port map (
        clk         => clk,
        reset       => reset,
        id_stage    => ifid_reg,
        id          => id,
        id_c        => id_c,
        datas_in    => datas,
        mem_haz     => mem_haz,
        -- outputs
        id_ex_stage => idex_reg,
        id_ex       => id_ex_val,
        id_ex_c     => id_ex_c,
        datas_out   => id_ex_datas
    );
    
-------------------------------------------------------
-------------------- EX STAGE -------------------------
-------------------------------------------------------
    U_EX : entity work.ex_stage 
    generic map ( ENABLE_FORWARDING => isFORW_ON )
    port map (
            EX_MEM   => ex_mem_val,
            WB       => wb_val,
            ID_EX    => id_ex_val,
            ID_EX_c  => id_ex_c,
            reg      => id_ex_datas,
            Forw     => haz, 
            -- output
            ex_out   => ex_val
        );  
        
-------------------------------------------------------
------------------ EX/MEM register ---------------------
-------------------------------------------------------
    U_EX_MEM : entity work.EX_TO_MEM port map (
        clk            => clk,
        reset          => reset,
        EX             => idex_reg,
        EX_val         => ex_val,
        -- outputs
        mem_haz        => mem_haz,
        EX_MEM         => exmem_reg,
        EX_MEM_content => ex_mem_val
    ); 
    
-------------------------------------------------------
-------------------- MEM STAGE -------------------------
-------------------------------------------------------
    process (ex_mem_val, mem_haz)
    begin
        case mem_haz is
            when REL_A_STALL_B | REL_A_NS => 
                mem_addr_in <= ex_mem_val.A.alu.result;
                mem_val_in  <= ex_mem_val.A.S_data;
                isLwOrSw    <= ex_mem_val.A.cntrl.mem;
            when REL_B =>
                mem_addr_in <= ex_mem_val.B.alu.result;
                mem_val_in  <= ex_mem_val.B.S_data;
                isLwOrSw    <= ex_mem_val.B.cntrl.mem;
            when others => null;  
        end case;
    end process;

    U_MEM : entity work.MEM_STA port map (
            clk      => clk,
            data_in  => mem_val_in,
            ex_mem   => mem_addr_in,
            ex_mem_c => isLwOrSw,
            -- Outputs to MEM/WB pipeline register
            mem      => mem_val_out
        );  
 
 -------------------------------------------------------
------------------ MEM/WB register ---------------------
------------------------------------------------------- 
    -- NOTE: VENKATEST
    -- This is a temporary version of the mem_wb register. I'm still waiting for your version as promised-I just wanted to begin testing the signal propagation.
    U_MEM_WB : entity work.MEM_WB port map (
           clk            => clk,
           reset          => reset,
           -- inputs from ex_mem register
           ex_mem         => exmem_reg,
           exmem_content  => ex_mem_val,
           mem_haz        => mem_haz,
           -- inputs from mem stage
           memA_result    => mem_val_out,
           -- outputs
           mem_wb         => memwb_reg,
           mem_wb_content => mem_wb_val
        );  
 
    -------------------------------------------------------
    -------------------- WB STAGE -------------------------
    -------------------------------------------------------
    U_WB : entity work.WB port map (
            MEM_WB   => mem_wb_val,
            WB_OUT   => wb_val 
        );          
    
-- ASSIGN OUTPUTS
if_ipcv     <= if_reg;
id_ipcv     <= ifid_reg;
id_value    <= id;
id_cntrl    <= id_c;
id_haz      <= haz;
id_datas    <= datas;
ex_ipcv     <= idex_reg;
idex_value  <= id_ex_val;
idex_cntrl  <= id_ex_c;
idex_datas  <= id_ex_datas;
ex_value    <= ex_val;
mem_ipcv    <= exmem_reg; 
exmem_value <= ex_mem_val;   
mem_value   <= mem_val_out; 
wb_ipcv     <= memwb_reg; 
memwb_value <= mem_wb_val; 
wb_value    <= wb_val; 

end Behavioral;
