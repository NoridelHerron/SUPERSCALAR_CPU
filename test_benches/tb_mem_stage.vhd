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
signal write_in     : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
signal ex_mem       : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
signal ex_mem_c     : CONTROL_SIG                             := NONE_c;   
signal mem          : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
signal mem_exp      : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 

type memory_array is array (1023 to 0) of std_logic_vector(31 downto 0);
signal exp_mem : memory_array := (others => (others => '0'));

begin
    UUT : entity work.MEM_STA port map (
        clk      => clk,
        write_in => write_in,
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
    variable write_in_v     : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits; 
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
            uniform(seed1, seed2, rand); ex_mem_v   := get_32bits_val(rand);
            uniform(seed1, seed2, rand); write_in_v := get_32bits_val(rand);
            
            if rand < 0.5 then
                ex_mem_cv := MEM_WRITE;
            elsif rand < 0.95 then
                ex_mem_cv := MEM_READ;
            else
                ex_mem_cv := NONE_c;
            end if;
            
            if ex_mem_cv = MEM_WRITE then
                exp_mem(to_integer(unsigned(ex_mem_v(11 downto 2)))) <= write_in_v;
                mem_exp <= ZERO_32bits; 
            else
                mem_exp <= exp_mem(to_integer(unsigned(ex_mem_v(11 downto 2))));
            end if;
            
            -- input assignment
            ex_mem   <= ex_mem_v;
            ex_mem_c <= ex_mem_cv;
            write_in <= write_in_v;
            
            wait until rising_edge(clk);
            if mem = mem_exp then
                pass := pass + 1;
            else
                fail := fail + 1;
            end if;
            
        end loop;
        
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)     severity note;
        if pass = total_tests then 
            report "Passed:      " & integer'image(pass)            severity note;
        else
            report "Failed:      " & integer'image(fail)  severity note;
        end if;
    end process;

end sim;