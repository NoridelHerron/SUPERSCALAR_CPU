
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all; 

entity tb_adder is
--  Port ( );
end tb_adder;

architecture sim of tb_adder is

constant clk_period  : time := 10 ns;
signal clk          : std_logic := '0';
signal rst          : std_logic := '1';
signal act_output   : ALU_add_sub := EMPTY_ALU_add_sub;
signal exp_output   : ALU_add_sub := EMPTY_ALU_add_sub;
signal A, B         : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;

begin
    
    UUT: entity work.adder port map (A, B, act_output);
    
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
    variable rand_real              : real;
    variable seed1, seed2           : positive  := 42;
    variable rand_A, rand_B         : integer   := 0; 
    variable TOTAL_TESTS            : integer   := 20000;
    variable sum_ext                : unsigned(DATA_WIDTH downto 0);
    variable expected               : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
    variable pass, fail             : integer   := 0;
   
    begin
    
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
    for i in 1 to TOTAL_TESTS loop
        
        uniform(seed1, seed2, rand_real);
        if rand_real < 0.1 then
            rand_A := 0;
            rand_B := 0;
        elsif rand_real < 0.2 then
            rand_A := -1;
            rand_B := -1;
        elsif rand_real < 0.3 then
            rand_A := -1;
            uniform(seed1, seed2, rand_real);
            rand_B := integer(rand_real * real(MAX));
        elsif rand_real < 0.4 then
            rand_B := -1;
            uniform(seed1, seed2, rand_real);
            rand_A := integer(rand_real * real(MAX));
        else
            uniform(seed1, seed2, rand_real);
            rand_A := integer(rand_real * real(MAX));
            uniform(seed1, seed2, rand_real);
            rand_B := integer(rand_real * real(MAX));
        end if;
        
        A <= std_logic_vector(to_unsigned(rand_A, DATA_WIDTH));
        B <= std_logic_vector(to_unsigned(rand_B, DATA_WIDTH));    

        sum_ext     := resize(unsigned(to_unsigned(rand_A, DATA_WIDTH)), 33) + 
                       resize(unsigned(to_unsigned(rand_B, DATA_WIDTH)), 33);
        expected    := std_logic_vector(sum_ext(31 downto 0)); 
        
        exp_output.CB      <= sum_ext(DATA_WIDTH);
        exp_output.result  <= expected;
        
        wait for 1 ns;              
        
        if act_output.result = exp_output.result and act_output.CB = exp_output.CB then
            pass := pass + 1;
            
        else
            fail := fail + 1;
        end if;
    end loop;
    
    report "----------------------------------------------------";
    report "ALU Randomized Test Summary:";
    report "Total Tests      : " & integer'image(TOTAL_TESTS);
    report "Total Passes     : " & integer'image(pass);
    report "Total Fails      : " & integer'image(fail);
    report "----------------------------------------------------";
    
    wait;
end process;

end sim;
