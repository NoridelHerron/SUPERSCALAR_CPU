-----------------------------------------------------------------------------
-- Noridel Herron
-- 7/1/2025
-- IF Stage (IF)
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

entity IF_stage is
    Port ( clk       : in  std_logic; 
           reset     : in  std_logic;
           haz       : in  HDU_OUT_N;
           is_send   : in  HAZ_SIG;
           IF_STAGE  : out Inst_PC_N 
    );
end IF_stage;

architecture Behavioral of IF_stage is

-- Internal signals declaration and initialization
signal pc_fetch      : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
signal pc_current    : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
signal instr_reg     : Inst_N     := NOP_Inst_N;
signal instr_fetched : Inst_N     := NOP_Inst_N;

signal temp_reg      : Inst_PC_N  := EMPTY_Inst_PC_N;
signal after_reset   : std_logic  := '0';
signal is_memHAZ     : HAZ_SIG    := NONE_h;

begin
    
    -- Instantiate the Unit
    U_ROM : entity work.rom_wrapper port map (
        clk    => clk,
        pc     => pc_fetch,
        instr  => instr_fetched
    );
    
    -- Pc need to be updated on rising edge
    process(clk)
    begin
        -- reset everything to 0 and set is_valid to invalid
        if reset = '1' then
            pc_fetch    <= ZERO_32bits;
            pc_current  <= pc_fetch; 
            temp_reg    <= EMPTY_Inst_PC_N;
            after_reset <= '1';    
            
        elsif rising_edge(clk) then
            if is_send = SEND_BOTH then
                if pc_current = ZERO_32bits then
                    -- This will cause the instruction to be invalid during the first cycle after reset due to memory delay.
                    temp_reg.A.is_valid <= INVALID; 
                    temp_reg.B.is_valid <= INVALID;
                else
                    temp_reg.A.is_valid <= VALID; 
                    temp_reg.B.is_valid <= VALID;
                end if;
                -- fetched instruction from U_ROM
                instr_reg           <= instr_fetched;
                -- increment pcs
                pc_fetch            <= std_logic_vector(unsigned(pc_fetch) + 8); 
                temp_reg.A.pc       <= pc_current; 
                temp_reg.B.pc       <= std_logic_vector(unsigned(pc_current) + 4);
                -- Assigned fetched instruction
                temp_reg.A.instr    <= instr_reg.A; 
                temp_reg.B.instr    <= instr_reg.B; 
                is_memHAZ           <= NONE_h;
            end if; 
            pc_current <= pc_fetch;    
  
        end if;
    end process;
    
    -- Output assignment
    IF_STAGE <= temp_reg;
    
end Behavioral;
