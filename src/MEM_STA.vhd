----------------------------------------------------------------------------------
-- Noridel Herron
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all; 

entity MEM_STA is 
    Port (   
            clk       : in  std_logic; 
            data_in   : in  std_logic_vector(DATA_WIDTH-1 downto 0);   
            ex_mem    : in  std_logic_vector(DATA_WIDTH-1 downto 0);   
            ex_mem_c  : in  CONTROL_SIG;   
            -- Outputs to MEM/WB pipeline register
            mem       : out std_logic_vector(DATA_WIDTH-1 downto 0)  
          );
end MEM_STA;

architecture Behavioral of MEM_STA is

signal mem_address : std_logic_vector(LOG2DEPTH - 1 downto 0) := (others => '0');

begin

    -- Extract address bits [11:2] for word-aligned access
    mem_address <= ex_mem(LOG2DEPTH + 1 downto 2);

    -- Memory instance
    memory_block : entity work.DATA_MEM
        port map (
                    clk         => clk,
                    cntrl       => ex_mem_c,
                    address     => mem_address,
                    write_data  => data_in,
                    read_data   => mem
                );
   
end Behavioral;
