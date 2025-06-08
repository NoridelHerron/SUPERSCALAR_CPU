----------------------------------------------------------------------------------
-- Noridel Herron
-- FullAdder for ALU
-- 4/25/2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    port (
            A, B, Ci    : in  std_logic; --input
            Co, S       : out std_logic -- output
          );
end full_adder;

architecture logic of full_adder is

begin

    S  <= A xor B xor Ci; -- Sum
	Co <= (A and B) or (A and Ci) or (B and Ci); -- Carry out

end logic;
