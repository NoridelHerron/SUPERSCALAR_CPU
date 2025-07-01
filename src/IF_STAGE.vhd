-----------------------------------------------------------------------------
-- Noridel Herron
-- 7/1/2025
-- IF Stage (IF)
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;
use work.MyFunctions.all;

entity IF_stage is
    Port ( clk             : in  std_logic; 
           reset           : in  std_logic;
           IF_STAGE        : out Inst_PC_N 
    );
end IF_stage;

architecture Behavioral of IF_stage is

-- Internal signals declaration and initialization
signal pc_fetch      : pc_N       := EMPTY_PC_N;
signal pc_current    : pc_N       := EMPTY_PC_N;
signal instr_reg     : Inst_N     := EMPTY_Inst_N;
signal instr_fetched : Inst_N     := EMPTY_Inst_N;
signal temp_reg      : Inst_PC_N  := EMPTY_Inst_PC_N;

begin
    
    -- Instantiate the Unit
    U_ROM : entity work.rom_wrapper port map (
        clk    => clk,
        addr1  => pc_fetch.A,
        addr2  => pc_fetch.B,
        instr1 => instr_fetched.A,
        instr2 => instr_fetched.B
    );
    
    -- Pc need to be updated on rising edge
    process(clk)
    begin
        -- reset everything to 0 and set is_valid to invalid
        if reset = '1' then
            pc_fetch        <= EMPTY_PC_N;
            pc_current      <= pc_fetch; 
            temp_reg        <= EMPTY_Inst_PC_N;
            
        elsif rising_edge(clk) then
            if temp_reg.A.is_valid then   
                instr_reg           <= instr_fetched;
                pc_fetch.A          <= std_logic_vector(unsigned(pc_fetch.A) + 8);
                pc_fetch.B          <= std_logic_vector(unsigned(pc_fetch.A) + 4);
                pc_current          <= pc_fetch;
                temp_reg.A.pc       <= pc_current.A;
                temp_reg.B.pc       <= pc_current.B;
                temp_reg.A.instr    <= instr_reg.A; 
                temp_reg.A.instr    <= instr_reg.B; 
             end if;
        end if;
    end process;
    
    -- Output assignment
    IF_STAGE <= temp_reg;
    
end Behavioral;
