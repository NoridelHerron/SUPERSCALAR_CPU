-----------------------------------------------------------------------------------
-- Noridel Herron
-- half-Adder for ALU
-- 4/25/2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder is
    Port ( 
            A, B    : in  std_logic; --input
            Co, S   : out std_logic -- output
          );
end half_adder;

architecture logic of half_adder is

begin

    S  <= A xor B;  -- Sum
	Co <= A and B; -- Carry out

end logic;
