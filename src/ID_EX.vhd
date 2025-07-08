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
            clk             : in  std_logic; 
            reset           : in  std_logic; 
            id_stage        : in  Inst_PC_N;
            id              : in  DECODER_N_INSTR;   
            id_c            : in  control_Type_N;
            haz_in          : in  HDU_OUT_N;       -- output from hdu
            datas_in        : in  REG_DATAS;
            id_ex_stage     : out Inst_PC_N;  
            id_ex           : out DECODER_N_INSTR;
            id_ex_c         : out control_Type_N;
            haz_out         : out HDU_OUT_N;       -- output from hdu
            datas_out       : out REG_DATAS 
         );
end ID_EX;

architecture Behavioral of ID_EX is

signal id_ex_stage_reg  : Inst_PC_N        := EMPTY_Inst_PC_N;
signal id_reg           : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR;
signal id_reg_c         : control_Type_N   := EMPTY_control_Type_N;
signal haz_reg          : HDU_OUT_N        := EMPTY_HDU_OUT_N;
signal datas_reg        : REG_DATAS        := EMPTY_REG_DATAS;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            id_ex_stage_reg <= EMPTY_Inst_PC_N;
            id_reg          <= EMPTY_DECODER_N_INSTR;
            id_reg_c        <= EMPTY_control_Type_N;
            haz_reg         <= EMPTY_HDU_OUT_N;
            datas_reg       <= EMPTY_REG_DATAS;
            
        elsif rising_edge(clk) then    
            if id_stage.A.is_valid = VALID then
                id_ex_stage_reg.A <= id_stage.A;
                id_reg.A          <= id.A;
                id_reg_c.A        <= id_c.A;
                haz_reg.A         <= haz_in.A;
                datas_reg.one     <= datas_in.one; 
                
                if id_stage.B.is_valid = VALID then  
                    id_ex_stage_reg.B <= id_stage.B;
                    id_reg.B          <= id.B;
                    id_reg_c.B        <= id_c.B;
                    haz_reg.B         <= haz_in.B;
                    datas_reg.two     <= datas_in.two; 
                end if;   
            end if;
        end if;
    end process;

    -- Assign outputs
    id_ex_stage <= id_ex_stage_reg;
    id_ex       <= id_reg;
    id_ex_c     <= id_reg_c;
    haz_out     <= haz_reg;
    datas_out   <= datas_reg;

end Behavioral;
