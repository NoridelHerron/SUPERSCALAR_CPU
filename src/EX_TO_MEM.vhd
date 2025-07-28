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
            mem_haz        : out HAZ_SIG;
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

signal reg         : Inst_PC_N    := EMPTY_Inst_PC_N;
signal reg_content : EX_CONTENT_N := EMPTY_EX_CONTENT_N;
signal is_memHaz   : HAZ_SIG      := NONE_h;

begin
    process(EX, EX_val)
    begin
        if (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) or 
           (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
           is_memHaz <= REL_A_STALL_B;
           mem_haz   <= REL_A_STALL_B;
     
        elsif (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) or 
           (EX_val.B.cntrl.mem /= MEM_READ or EX_val.B.cntrl.mem /= MEM_WRITE) then
           is_memHaz   <= REL_A_NS;
           mem_haz     <= REL_A_NS;
           
        elsif (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
           is_memHaz   <= REL_B;
           mem_haz     <= REL_B;
           
        else
           is_memHaz   <= REL_A_NS;
           mem_haz     <= REL_A_NS;
        end if;
    end process;
    
    process(clk, reset)
    variable reg_v         : Inst_PC_N      := EMPTY_Inst_PC_N;
    variable reg_content_v : EX_CONTENT_N   := EMPTY_EX_CONTENT_N;
    begin
        if reset = '1' then  
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;
        -- Not checking the validity of instruction because I don't think I need to check it anymore
        -- since the previous registers will hold it already. However this my change after I observe the 
        -- wafeform of the integrated system
        elsif rising_edge(clk) then
            if is_memHaz = REL_A_STALL_B then
                reg.A          <= EX.A;
                reg_content.A  <= EX_val.A;
                reg.B.is_valid <= INVALID;
            else
                reg         <= reg_v;
                reg_content <= reg_content_v;
            end if;    
        end if;  
    end process;

    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;

end Behavioral;
