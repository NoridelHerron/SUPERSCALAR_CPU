------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- ID_EX Register
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

entity ID_EX is
    Port ( 
            clk         : in  std_logic; 
            reset       : in  std_logic; 
            haz         : in  HDU_OUT_N;
            id_stage    : in  Inst_PC_N;
            id          : in  DECODER_N_INSTR;   
            id_c        : in  control_Type_N;
            datas_in    : in  REG_DATAS;
           -- is_memBusy  : out HAZ_SIG;
            id_ex_stage : out Inst_PC_N;  
            id_ex       : out DECODER_N_INSTR;
            id_ex_c     : out control_Type_N;
            datas_out   : out REG_DATAS 
         );
end ID_EX;

architecture Behavioral of ID_EX is

signal id_ex_stage_reg  : Inst_PC_N        := EMPTY_Inst_PC_N;
signal id_reg           : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR;
signal id_reg_c         : control_Type_N   := EMPTY_control_Type_N;
signal datas_reg        : REG_DATAS        := EMPTY_REG_DATAS;

signal B_stage_reg      : Inst_PC          := EMPTY_Inst_PC;
signal B_id_reg         : DECODER_Type     := EMPTY_DECODER;
signal B_id_reg_c       : control_Type     := EMPTY_control_Type;
signal B_datas_reg      : REG_DATA_PER     := EMPTY_REG_DATA_PER;

signal is_memHAZ        : HAZ_SIG          := NONE_h;
signal is_done          : std_logic        := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then
            id_ex_stage_reg <= EMPTY_Inst_PC_N;
            id_reg          <= EMPTY_DECODER_N_INSTR;
            id_reg_c        <= EMPTY_control_Type_N;
            datas_reg       <= EMPTY_REG_DATAS;
            is_done         <= '0';
            
        elsif rising_edge(clk) then
           -- if id_ex_stage_reg.isMemBusy = MEM_A then
             --   id_ex_stage_reg.B <= B_stage_reg;
              --  id_reg.B          <= B_id_reg;
             --   id_reg_c.B        <= B_id_reg_c;
             --   datas_reg.two     <= B_datas_reg; 
                
               -- id_ex_stage_reg.isMemBusy  <= MEM_B;
              --  id_ex_stage_reg.A.is_valid <= INVALID;
                
            if is_done = '0' and haz.B.stall = AB_BUSY then
                id_ex_stage_reg.A <= id_stage.A;
                id_reg.A          <= id.A;
                id_reg_c.A        <= id_c.A;
                datas_reg.one     <= datas_in.one; 
                
                B_stage_reg <= id_stage.B;
                B_id_reg    <= id.B;
                B_id_reg_c  <= id_c.B;
                B_datas_reg <= datas_in.two; 
                
                id_ex_stage_reg.isMemBusy  <= MEM_A;
                id_ex_stage_reg.B.is_valid <= INVALID;
                is_done                    <= '1';
                
             else 
                is_done         <= '0';
                id_ex_stage_reg <= id_stage;
                id_reg          <= id;
                id_reg_c        <= id_c;
                datas_reg       <= datas_in; 
                
                if is_done = '1' and id_ex_stage_reg.isMemBusy = MEM_A then
                    id_ex_stage_reg.isMemBusy  <= MEM_B;
                    id_ex_stage_reg.A.is_valid <= INVALID;
                    
                elsif haz.B.stall = REL_A then
                    id_ex_stage_reg.isMemBusy  <= REL_A;
                    
                elsif haz.B.stall = REL_B then
                    id_ex_stage_reg.isMemBusy  <= REL_B;
                    
                else
                    id_ex_stage_reg.isMemBusy  <= NONE_h;
                end if;
             end if;
        end if;
    end process;

    -- Assign outputs
    id_ex_stage <= id_ex_stage_reg;
    id_ex       <= id_reg;
    id_ex_c     <= id_reg_c;
    datas_out   <= datas_reg;
end Behavioral;