library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.ENUM_T.all;

entity WB is
    Port (
        MEM_WB   : in MEM_CONTENT_N;
        WB_OUT   : out WB_CONTENT_N_INSTR
    );
end WB;

architecture Behavioral of WB is
begin
    process(MEM_WB)
    begin

        -- Instruction A write-back stage
        if MEM_WB.A.we = REG_WRITE then
            if MEM_WB.A.me = MEM_READ then
                WB_OUT.A.data <= MEM_WB.A.res1;
            else
                WB_OUT.A.data <= MEM_WB.A.res2;
            end if;
        end if;

        WB_OUT.A.rd <= MEM_WB.A.rd;
        WB_OUT.A.we <= MEM_WB.A.we;

        -- Instruction B write-back stage
        if MEM_WB.B.we = REG_WRITE then 
            if MEM_WB.B.me = MEM_READ then
                WB_OUT.B.data <= MEM_WB.B.res1;
            else
                WB_OUT.B.data <= MEM_WB.B.res2;
            end if;
        end if;

        WB_OUT.B.rd <= MEM_WB.B.rd;
        WB_OUT.B.we <= MEM_WB.B.we;

    end process;

end Behavioral;