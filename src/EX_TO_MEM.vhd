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

entity EX_TO_MEM is
    Port ( 
            clk            : in  std_logic; 
            reset          : in  std_logic;  -- added reset input
            EX             : in  Inst_PC_N;
            EX_content     : in  EX_CONTENT_N;
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

signal reg         : Inst_PC_N      := EMPTY_Inst_PC_N;
signal reg_content : EX_CONTENT_N   := EMPTY_EX_CONTENT_N;
signal reg_control : control_Type_N := EMPTY_control_Type_N;

begin
    process(clk, reset)
    begin
        if reset = '1' then  
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;
            reg_control <= EMPTY_control_Type_N;
        -- Not checking the validity of instruction because I don't think I need to check it anymore
        -- since the previous registers will hold it already. However this my change after I observe the 
        -- wafeform of the integrated system
        elsif rising_edge(clk) then
            reg         <= EX;
            if EX_content.A.cntrl.mem = MEM_READ or EX_content.A.cntrl.mem = MEM_WRITE then
                reg_content <= EX_content;
            elsif EX_content.B.cntrl.mem = MEM_READ or EX_content.B.cntrl.mem = MEM_WRITE then
                reg_content.A <= EX_content.B;
                reg_content.B <= EX_content.A;
            else
                reg_content <= EX_content;
            end if;   
        end if;    
    end process;

    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;

end Behavioral;
