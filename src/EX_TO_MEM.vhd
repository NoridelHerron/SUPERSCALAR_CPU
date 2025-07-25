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
            EX_val         : in  EX_CONTENT_N;
            mem_stall      : out HAZ_SIG;
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

signal reg            : Inst_PC_N      := EMPTY_Inst_PC_N;
signal reg_content    : EX_CONTENT_N   := EMPTY_EX_CONTENT_N;
signal reOrder        : std_logic      := '0';
signal normalFlow     : std_logic      := '0';
signal re_reg         : Inst_PC        := EMPTY_Inst_PC;
signal re_val         : EX_CONTENT     := EMPTY_EX_CONTENT;

begin
    process(clk, reset)
    begin
        if reset = '1' then  
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;

        -- Not checking the validity of instruction because I don't think I need to check it anymore
        -- since the previous registers will hold it already. However this my change after I observe the 
        -- wafeform of the integrated system
        elsif rising_edge(clk) then
            if reOrder = '1' then
                reOrder        <= '0';
                mem_stall      <= NONE_H;
                reg.A          <= re_reg;
                reg_content.A  <= re_val;
                reg.B          <= EX.A;
                reg_content.B  <= EX_val.A;
                
            elsif (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) and
               (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
                reg.A          <= EX.A;
                reg_content.A  <= EX_val.A;
                mem_stall      <= REL_A_WH;
                reOrder        <= '1';
                re_reg         <= EX.B;
                re_val         <= EX_val.B;

            elsif (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) and
                  (EX_val.B.cntrl.mem /= MEM_READ or EX_val.B.cntrl.mem /= MEM_WRITE) then
                mem_stall   <= REL_A_NH;
                reg         <= EX;
                reg_content <= EX_val;
                
            elsif (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
                mem_stall   <= REL_B;
                reg         <= EX;
                reg_content <= EX_val;
                
            else
                mem_stall  <= NONE_h;
                reg         <= EX;
                reg_content <= EX_val;
            end if;

        end if;    
    end process;

    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;

end Behavioral;
