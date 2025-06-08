----------------------------------------------------------------------------------
-- Noridel Herron
-- Half-Subtractor for ALU
-- 6/8/2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_subtractor is
    Port ( 
           X, Y     : in std_logic; 
           Bout, D  : out std_logic
          ); 
end half_subtractor;

architecture logic of half_subtractor is

begin

    Bout <= (not X) and Y; 
    D <= X xor Y; 

end logic;
