------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- test bench for IF Stage (IF)
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

entity tb_if_stage is
--  Port ( );
end tb_if_stage;

architecture sim of tb_if_stage is
    constant clk_period : time       := 10 ns;
    signal clk          : std_logic  := '0';
    signal rst          : std_logic  := '1';
    
    signal IF_STAGE     :  Inst_PC_N := EMPTY_Inst_PC_N;
    
begin
    UUT: entity work.IF_STAGE 
        port map ( clk      => clk,
                   reset    => rst,
   
                   IF_STAGE => IF_STAGE
                );

    -- Clock generation only
    clk_process : process
    begin
        while now < 2000000 ns loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;
    
    process
 
    begin 
        -- Hold reset for two clock cycles
        rst <= '1';
        wait for clk_period * 2;
        rst <= '0';
        
        -- Wait enough cycles to see PC and instructions advance
        wait for clk_period * 20;

        -- Optionally finish simulation
        report "Simulation finished." severity note;
        wait;
    end process;

end sim;
