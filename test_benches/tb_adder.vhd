
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ALU_Pkg.all;
use work.enum_types.all;

entity tb_adder is
--  Port ( );
end tb_adder;

architecture sim of tb_adder is

signal A, B     : std_logic_vector(DATA_WIDTH-1 downto 0);
signal output   : ALU_out;

begin
    
    UUT: entity work.adder port map (A, B, output);
    
    process
    variable rand_real              : real;
    variable seed1, seed2           : positive  := 42;
    variable rand_A, rand_B         : integer   := 0; 
    variable TOTAL_TESTS            : integer   := 10000;
    variable sum_ext                : unsigned(DATA_WIDTH downto 0);

   -- variable sum_ext                : std_logic_vector(DATA_WIDTH downto 0) := (others => '0');
    variable expected : ALU_out     := EMPTY_ALU_out;
    variable pass, fail             : integer   := 0;
    variable fail_res, fail_Z       : integer   := 0;
    variable fail_V, fail_N, fail_C : integer   := 0;
begin
    for i in 1 to TOTAL_TESTS loop
  
        uniform(seed1, seed2, rand_real);
        if rand_real > 0.75 then
            rand_A := 0;
            rand_B := 0;
        elsif rand_real > 0.5 then
            rand_A := -1;
            rand_B := -1;
        else
            uniform(seed1, seed2, rand_real);
            rand_A := integer(rand_real * real(MAX));
            uniform(seed1, seed2, rand_real);
            rand_B := integer(rand_real * real(MAX));
        end if;
        
        A <= std_logic_vector(to_unsigned(rand_A, DATA_WIDTH));
        B <= std_logic_vector(to_unsigned(rand_B, DATA_WIDTH));
        
        wait for 10 ns;

        sum_ext := resize(unsigned(to_unsigned(rand_A, DATA_WIDTH)), 33) + 
                   resize(unsigned(to_unsigned(rand_B, DATA_WIDTH)), 33);
        expected.result := std_logic_vector(sum_ext(31 downto 0));
        
        if sum_ext(DATA_WIDTH) = '1' then expected.C := Cf; else expected.C := NONE; end if;
        if expected.result(DATA_WIDTH-1) = '1' then expected.N := N; else expected.N := NONE; end if;
        if expected.result = ZERO_32bits then expected.Z := Z; else expected.Z := NONE; end if;
        if ((rand_A < 0 and rand_B < 0 and to_integer(signed(expected.result)) >= 0) or
            (rand_A > 0 and rand_B > 0 and to_integer(signed(expected.result)) < 0)) then
            expected.V := V;
        else
            expected.V := NONE;
        end if;
        
        if output.result = expected.result and output.Z = expected.Z and
           output.N = expected.N and output.V = expected.V and output.C = expected.C then
            pass := pass + 1;
        else
            fail := fail + 1;
            if output.result /= expected.result then fail_res := fail_res + 1; assert false report "Result mismatch" severity warning; end if;
            if output.Z /= expected.Z then fail_Z := fail_Z + 1; assert false report "Z flag mismatch" severity warning; end if;
            if output.N /= expected.N then fail_N := fail_N + 1; assert false report "N flag mismatch" severity warning; end if;
            if output.V /= expected.V then fail_V := fail_V + 1; assert false report "V flag mismatch" severity warning; end if;
            if output.C /= expected.C then fail_C := fail_C + 1; assert false report "C flag mismatch" severity warning; end if;
        end if;
    end loop;
    
    report "----------------------------------------------------";
    report "ALU Randomized Test Summary:";
    report "Total Tests      : " & integer'image(TOTAL_TESTS);
    report "Total Passes     : " & integer'image(pass);
    report "Total Failures   : " & integer'image(fail);
    report "Flag Failures:";
    report "Z flag fails : " & integer'image(fail_Z);
    report "N flag fails : " & integer'image(fail_N);
    report "V flag fails : " & integer'image(fail_V);
    report "C flag fails : " & integer'image(fail_C);
    report "----------------------------------------------------";
    
    wait;
end process;

end sim;
