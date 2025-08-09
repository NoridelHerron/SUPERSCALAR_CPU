
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 


entity DATA_MEM is
		--Generic( LOG2DEPTH : natural := integer(ceil(log2(real(DEPTH)))));
    Port(
          clk        : in  std_logic; -- Clock input, used to trigger synchronous writes
          cntrl      : in  CONTROL_SIG;                    
          address    : in  std_logic_vector(LOG2DEPTH-1 downto 0); -- 10-bit address (1024 words)
          write_data : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- 32-bit input - the data to write to memory
          read_data  : out std_logic_vector(DATA_WIDTH-1 downto 0) --  32-bit output - the data being read
         );
end DATA_MEM;

architecture Behavioral of DATA_MEM is
-- Declare the memory_array and initialize each element to 0
type memory_array is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0); 
signal mem : memory_array := (others => (others => '0')); 

begin
    process(clk)
    begin
        -- Triggered on the rising edge of the clock
        if rising_edge(clk) then
            if cntrl = MEM_WRITE then               
                mem(to_integer(unsigned(address))) <= write_data;
            end if;
        end if;
    end process;
    
    -- Combinational
    process(cntrl, address)
    begin
        if cntrl = MEM_READ then
            read_data <= mem(to_integer(unsigned(address)));
        else
            read_data <= (others => '0');
        end if;
    end process;
end Behavioral;