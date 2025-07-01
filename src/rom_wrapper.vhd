-----------------------------------------------------------------------------
-- Noridel Herron
-- 7/1/2025
-- Execute Stage (EX)
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;

entity rom_wrapper is
    Port ( 
            clk   : in  std_logic;
            pc    : in  PC_N;
            instr : out Inst_N
         );
end rom_wrapper;

architecture Behavioral of rom_wrapper is

    component rom 
        port (
                clk    : in  std_logic;
                addr1  : in  std_logic_vector(9 downto 0);
                addr2  : in  std_logic_vector(9 downto 0);
                instr1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
                instr2 : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );    
    end component;
    
begin

    u_rom: rom port map (
            clk    => clk,
            addr1  => pc.A(11 downto 2),
            addr2  => pc.B(11 downto 2),
            instr1 => instr.A,
            instr2 => instr.B
    );

end Behavioral;
