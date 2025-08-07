------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- EX_TO_MEM Register (with Stall Tracking)
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;

entity EX_TO_MEM is
    Port ( 
            clk            : in  std_logic; 
            reset          : in  std_logic;  
            EX             : in  Inst_PC_N;
            EX_val         : in  EX_CONTENT_N; 
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

    signal reg           : Inst_PC_N    := EMPTY_Inst_PC_N;
    signal reg_content   : EX_CONTENT_N := EMPTY_EX_CONTENT_N;
    signal is_memHaz     : HAZ_SIG      := NONE_h;
begin
    
    process(clk, reset)
    begin
        if reset = '1' then
            -- reset everything
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;

        elsif rising_edge(clk) then
            if EX.A.is_valid = VALID then
                reg.A         <= EX.A;
                reg_content.A <= EX_val.A;
            else
                reg.A.is_valid <= INVALID;
                reg_content.A  <= EMPTY_EX_CONTENT;
            end if;
            
            if EX.B.is_valid = VALID then
                reg.B         <= EX.B;
                reg_content.B <= EX_val.B;
            else
                reg.B.is_valid <= INVALID;
                reg_content.B  <= EMPTY_EX_CONTENT;
            end if;
    
        end if;
    end process;

    -- Output assignments
    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;

end Behavioral;