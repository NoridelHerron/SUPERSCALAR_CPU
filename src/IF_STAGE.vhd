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
signal pc_fetch        : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
signal instr_fetched   : Inst_N     := NOP_Inst_N;
signal instr_fetched_h : Inst_N     := NOP_Inst_N;

signal temp_reg        : Inst_PC_N  := EMPTY_Inst_PC_N;
signal after_reset     : std_logic  := '0';
signal is_ready        : std_logic  := '0';  
signal is_stall_again  : std_logic  := '0';  

begin
   -- Instantiate the Unit
    U_ROM : entity work.rom_wrapper port map (
        clk    => clk,
        pc     => pc_fetch,
        instr  => instr_fetched
    );

    
    -- Pc need to be updated on rising edge
    process(clk)
    variable is_check : std_logic                               := '0';
    variable pc       : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
    variable instr_v  : Inst_N                                  := NOP_Inst_N;
    begin
        -- reset everything to 0 and set is_valid to invalid
        if reset = '1' then
            temp_reg    <= EMPTY_Inst_PC_N;
            after_reset <= '1'; 
            
        elsif rising_edge(clk) then
        
            if pc_fetch = ZERO_32bits then
                temp_reg.A.is_valid <= INVALID; 
                temp_reg.B.is_valid <= INVALID;
            else
                temp_reg.A.is_valid <= VALID; 
                temp_reg.B.is_valid <= VALID;
            end if;
            
            if is_ready = '0' and (haz.B.stall = AB_BUSY or haz.A.stall = A_STALL or haz.A.stall = B_STALL
                or haz.B.stall = A_STALL or haz.B.stall = B_STALL or haz.B.stall = STALL_FROM_A) then
                is_ready        <= '1';
                instr_fetched_h <= instr_fetched;
                if haz.B.stall = STALL_FROM_A then
                    is_stall_again <= '1';
                else
                    is_stall_again <= '0';
                end if; 
                
            elsif is_ready = '1' then
                if is_stall_again = '0' then
                    is_ready         <= '0';
                    pc_fetch         <= std_logic_vector(unsigned(pc_fetch) + 8); 
                    temp_reg.A.pc    <= pc_fetch; 
                    temp_reg.B.pc    <= std_logic_vector(unsigned(pc_fetch) + 4);
                    temp_reg.A.instr <= instr_fetched_h.A; 
                    temp_reg.B.instr <= instr_fetched_h.B; 
                else
                    is_stall_again <= '0';
                end if;
            else 
                is_ready         <= '0'; 
                pc_fetch         <= std_logic_vector(unsigned(pc_fetch) + 8); 
                temp_reg.A.pc    <= pc_fetch; 
                temp_reg.B.pc    <= std_logic_vector(unsigned(pc_fetch) + 4);
                temp_reg.A.instr <= instr_fetched.A; 
                temp_reg.B.instr <= instr_fetched.B; 
                
            end if;
        end if;
    end process;
    
    -- Output assignment
    IF_STAGE <= temp_reg;
    
end Behavioral;