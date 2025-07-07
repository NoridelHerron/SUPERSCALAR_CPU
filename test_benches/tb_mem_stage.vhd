------------------------------------------------------------------------------
-- Noridel Herron
-- 7/7/2025
-- testbench for Ex/MEM register
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all; 
use work.MyFunctions.all;

entity tb_mem_stage is
--  Port ( );
end tb_mem_stage;

architecture sim of tb_mem_stage is

constant clk_period : time                                    := 10 ns;
signal clk          : std_logic                               := '0';
signal rst          : std_logic                               := '1';
signal ex_mem       : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
--signal ex_mem_exp   : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
signal ex_mem_c     : CONTROL_SIG                             := NONE_c;   
--signal ex_mem_c_exp : CONTROL_SIG                             := NONE_c;   
signal mem          : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
--signal mem_exp      : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 

begin
    UUT : entity work.MEM_STA port map (
        clk      => clk,
        reset    => rst,
        ex_mem   => ex_mem,
        ex_mem_c => ex_mem_c,
        mem      => mem
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
    -- randomized used for generating values
    variable rand           : real;
    variable seed1, seed2   : positive                                := 12345;
    variable ex_mem_v       : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
    variable ex_mem_cv      : CONTROL_SIG                             := NONE_c;   
    
    variable total_tests   : integer            := 20000;
    -- Keep track test
    variable pass, fail     : integer   := 0;
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period * 2;
        
        for i in 1 to total_tests loop   
            uniform(seed1, seed2, rand);
            ex_mem_v := get_32bits_val(rand);
            
            if rand < 0.5 then
                ex_mem_cv := MEM_WRITE;
            elsif rand < 0.95 then
                ex_mem_cv := MEM_READ;
            else
                ex_mem_cv := NONE_c;
            end if;
            
            -- input assignment
            ex_mem   <= ex_mem_v;
            ex_mem_c <= ex_mem_cv;
            
            wait until rising_edge(clk);
        end loop;
    end process;

end sim;
