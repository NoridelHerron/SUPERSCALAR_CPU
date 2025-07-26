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
signal re_reg         : Inst_PC        := EMPTY_Inst_PC;
signal re_val         : EX_CONTENT     := EMPTY_EX_CONTENT;
signal is_busy        : HAZ_SIG        := NONE_h;
signal reset_stall    : std_logic      := '0';
--signal B_TO_A         : std_logic      := '0';

begin
    process (EX_val)
    variable mem_stall_v : HAZ_SIG := NONE_h;
    begin
        if (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) and
           (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
           mem_stall_v := REL_A_WH;
        elsif (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) and
              (EX_val.B.cntrl.mem /= MEM_READ or EX_val.B.cntrl.mem /= MEM_WRITE) then
            mem_stall_v := REL_A_NH;
        elsif (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
            mem_stall_v := REL_B;
        else
            mem_stall_v := NONE_h;
        end if;
        
        if reset_stall = '1' then
            mem_stall <= NONE_h;
            is_busy   <= NONE_h;
          --  B_TO_A    <= '1';
        else
            mem_stall <= mem_stall_v;
            is_busy   <= mem_stall_v;
        end if;
    end process;

    process(clk, reset)
    variable reg_v          : Inst_PC_N      := EMPTY_Inst_PC_N;
    variable reg_content_v  : EX_CONTENT_N   := EMPTY_EX_CONTENT_N;
    variable re_reg_v       : Inst_PC        := EMPTY_Inst_PC;
    variable re_val_v       : EX_CONTENT     := EMPTY_EX_CONTENT;
    variable reOrder_v      : std_logic      := '0';
    begin
        if reset = '1' then  
            reg_v         := EMPTY_Inst_PC_N;
            reg_content_v := EMPTY_EX_CONTENT_N;

        -- Not checking the validity of instruction because I don't think I need to check it anymore
        -- since the previous registers will hold it already. However this my change after I observe the 
        -- wafeform of the integrated system
        elsif rising_edge(clk) then
            reg_v         := EX;
            reg_content_v := EX_val;
            reOrder_v     := '0';
            
            if reOrder = '1' and (reg_content_v.A.cntrl.mem /= MEM_READ or reg_content_v.A.cntrl.mem /= MEM_WRITE)  then
                reOrder_v       := '0'; 
                reg_v.A         := re_reg;
                reg_content_v.A := re_val;
                reg_v.B         := EX.A;
                reg_content_v.B := EX_val.A;
                reset_stall     <= '1';
                
            elsif reOrder = '1' and (reg_content_v.A.cntrl.mem = MEM_READ or reg_content_v.A.cntrl.mem = MEM_WRITE)  then
                reOrder_v       := '0'; 
                reg_v.A         := re_reg;
                reg_content_v.A := re_val;
                reg_v.B         := reg_v.B;
                reg_content_v.B := reg_content.B;
            
            elsif is_busy = REL_A_WH then   
                reOrder_v        := '1';
                re_reg_v         := reg_v.B;
                re_val_v         := EX_val.B;
                reg_v.B.is_valid := INVALID;
            else
                -- default
            end if;
        end if;    
        reg         <= reg_v;
        reg_content <= reg_content_v;
        reOrder     <= reOrder_v;
        re_reg      <= re_reg_v;
        re_val      <= re_val_v;
    end process;

    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;

end Behavioral;
