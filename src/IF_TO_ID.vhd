------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- IF_ID Register
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

entity IF_TO_ID is
    Port (
           clk       : in  std_logic; 
           reset     : in  std_logic; 
           haz       : in  HDU_OUT_N; 
           mem_stall : in  HAZ_SIG; 
           if_stage  : in  Inst_PC_N;
           if_id     : out Inst_PC_N  
          );
end IF_TO_ID;

architecture Behavioral of IF_TO_ID is

signal reg          : Inst_PC_N := EMPTY_Inst_PC_N;
signal reOrder      : std_logic := '0';
signal re_stage_reg  : Inst_PC  := EMPTY_Inst_PC;

begin

    process(clk, reset)
    variable temp : Inst_PC_N := EMPTY_Inst_PC_N; 
    begin
        if reset = '1' then  
            reg <= EMPTY_Inst_PC_N;
            
        elsif rising_edge(clk) then
            if mem_stall = REL_A_WH then
                reg.A        <= if_stage.A; 
                reOrder      <= '1';
            else  
                if reOrder = '1' then
                    reg.A        <= if_stage.A; 
                    re_stage_reg <= if_stage.B;   
                    reOrder      <= '0';
                else
                    if if_stage.A.is_valid = VALID then  
                        reg.A <= if_stage.A; 
                        --We need to check the validity inside A because, in an in-order pipeline, we can't allow instruction B to proceed if it's invalid.
                        if if_stage.B.is_valid = VALID then  
                            reg.B <= if_stage.B;
                        end if;  
                    end if; 
               end if; 
            end if;
        end if;
    end process;

    -- Assign output
    if_id <= reg;

end Behavioral;
