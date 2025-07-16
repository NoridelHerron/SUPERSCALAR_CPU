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
    Port ( 
            clk         : in  std_logic; 
            reset       : in  std_logic;
            if_ipcv     : out Inst_PC_N;
            id_ipcv     : out Inst_PC_N;
            id_value    : out DECODER_N_INSTR;
            id_cntrl    : out control_Type_N;
            id_haz      : out HDU_OUT_N;      
            id_datas    : out REG_DATAS;
            idex_ipcv   : out Inst_PC_N; 
            idex_value  : out DECODER_N_INSTR;
            idex_cntrl  : out control_Type_N;  
            idex_datas  : out REG_DATAS;
            ex_value    : out EX_CONTENT_N;
            exmem_ipcv  : out Inst_PC_N; 
            exmem_value : out EX_CONTENT_N;
            exmem_cntrl : out control_Type_N;  
            mem_value   : out std_logic_vector(DATA_WIDTH-1 downto 0); 
            memwb_ipcv  : out Inst_PC_N; 
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
signal id_ex_haz     : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal id_ex_datas   : REG_DATAS          := EMPTY_REG_DATAS;
signal ex_val        : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal exmem_reg     : Inst_PC_N          := EMPTY_Inst_PC_N;
signal ex_mem_val    : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal ex_mem_c      : control_Type_N     := EMPTY_control_Type_N;
signal ex_mem_rc     : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR;
signal memwb_reg     : Inst_PC_N          := EMPTY_Inst_PC_N;
signal mem_wb_val    : MEM_CONTENT_N      := EMPTY_MEM_CONTENT_N;
signal mem_wb_rc     : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR;
signal mem_c         : CONTROL_SIG        := NONE_c;
signal wb_val        : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;

signal mem_val_in    : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
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
        EX_MEM   => ex_mem_rc,
        MEM_WB   => mem_wb_rc,
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
        haz_in      => haz,
        datas_in    => datas,
        -- outputs
        id_ex_stage => idex_reg,
        id_ex       => id_ex_val,
        id_ex_c     => id_ex_c,
        haz_out     => id_ex_haz,
        datas_out   => id_ex_datas
    );
    
-------------------------------------------------------
-------------------- EX STAGE -------------------------
-------------------------------------------------------
    U_EX : entity work.ex_stage port map (
            EX_MEM   => ex_mem_val,
            WB       => wb_val,
            ID_EX    => id_ex_val,
            reg      => id_ex_datas,
            Forw     => id_ex_haz,
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
        EX_content     => ex_val,
        ex_control     => id_ex_c,
        -- outputs
        EX_MEM         => exmem_reg,
        EX_MEM_content => ex_mem_val,
        ex_c           => ex_mem_c
    ); 
    
    process (ex_mem_val, ex_mem_c)
    begin
        ex_mem_rc.A.rd    <= ex_mem_val.A.rd;
        ex_mem_rc.A.cntrl <= ex_mem_c.A;
        ex_mem_rc.B.rd    <= ex_mem_val.B.rd;
        ex_mem_rc.B.cntrl <= ex_mem_c.B;
    end process;
    
-------------------------------------------------------
-------------------- MEM STAGE -------------------------
-------------------------------------------------------
-- Not sure with this combinational yet, still thinking. 
-- I need to see the waveform first before I decide what to do in this stage.
    process(exmem_reg, ex_mem_val)
    begin
        if exmem_reg.A.is_valid = valid then
            mem_val_in <= ex_mem_val.A.alu.result;
            mem_c      <= ex_mem_c.A.mem;
        end if;
    end process;
    
    U_MEM : entity work.MEM_STA port map (
            clk      => clk,
            ex_mem   => mem_val_in,
            ex_mem_c => mem_c,
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
           ex_cntrl       => ex_mem_c,
           -- inputs from mem stage
           memA_result    => mem_val_out,
           -- outputs
           mem_wb         => memwb_reg,
           mem_wb_content => mem_wb_val
        );  
        
    process (mem_wb_val)
    begin
        mem_wb_rc.A.rd        <= mem_wb_val.A.rd;
        mem_wb_rc.A.cntrl.mem <= mem_wb_val.A.me;
        mem_wb_rc.A.cntrl.wb  <= mem_wb_val.A.we;
        mem_wb_rc.A.rd        <= mem_wb_val.B.rd;
        mem_wb_rc.A.cntrl.mem <= mem_wb_val.B.me;
        mem_wb_rc.A.cntrl.wb  <= mem_wb_val.B.we;
    end process;  
    
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
idex_ipcv   <= idex_reg;
idex_value  <= id_ex_val;
idex_cntrl  <= id_ex_c;
idex_datas  <= id_ex_datas;
ex_value    <= ex_val;
exmem_ipcv  <= ex_mem_reg; 
exmem_value <= ex_mem_val; 
exmem_cntrl <= ex_mem_c;   
mem_value   <= mem_val_out; 
memwb_ipcv  <= memwb_reg; 
memwb_value <= mem_wb_val; 
wb_value    <= wb_val; 

end Behavioral;
