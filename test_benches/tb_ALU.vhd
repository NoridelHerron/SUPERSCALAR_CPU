
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

entity tb_ALU is
end tb_ALU;

architecture sim of tb_ALU is

    constant clk_period         : time := 10 ns;
    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '1';
    signal input                : ALU_in  := EMPTY_ALU_in;
    signal output               : ALU_out := EMPTY_ALU_out;
    signal exp_out              : ALU_out := EMPTY_ALU_out;
    
begin
    UUT: entity work.ALU port map (input, output);

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
        -- For generated value
        variable rand_real : real;
        variable seed1 : positive := 42;
        variable seed2 : positive := 24;
        variable rand_A, rand_B : integer;
        variable rand_f3 : integer;
        
        -- Expected result
        variable expected   : ALU_out := EMPTY_ALU_out;
        -- for C Flag
        variable sum_ext, sub_ext : unsigned(32 downto 0);
        
        variable total_tests : integer := 20000;
        -- Keep track of the tests
        variable fail_add, fail_sub, fail_sll, fail_slt, fail_sltu  : integer := 0;
        variable fail_xor, fail_srl, fail_sra, fail_or, fail_and    : integer := 0;
        variable pass, fail, fail_Z, fail_N, fail_V, fail_C         : integer := 0;
    begin 
    
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        for i in 1 to total_tests loop
 
            uniform(seed1, seed2, rand_real);
            if rand_real < 0.1 then
                rand_A := 0; rand_B := 0;
            else
                uniform(seed1, seed2, rand_real);
                rand_A := integer(rand_real * real(MAX));
                uniform(seed1, seed2, rand_real);
                rand_B := integer(rand_real * real(MAX));
            end if;
            
            uniform(seed1, seed2, rand_real);
            rand_f3 := integer(rand_real * 8.0);
            if rand_f3 > 7 then rand_f3 := 0; end if;  -- make sure value doesn't exceed 7
            
            -- For case 0 and 5 since there's two options
            if rand_f3 = 0 or rand_f3 = 5 then
                uniform(seed1, seed2, rand_real);
                if rand_real > 0.5 then
                    input.f7 <= ZERO_7bits;
                else
                    input.f7 <= THIRTY_TWO;
                end if;
            else
                input.f7 <= ZERO_7bits;
            end if;
            
            -- Value assignment for the unit
            input.A <= std_logic_vector(to_signed(rand_A, DATA_WIDTH));
            input.B <= std_logic_vector(to_signed(rand_B, DATA_WIDTH)); 
            input.f3 <= std_logic_vector(to_unsigned(rand_f3, 3));
            
            wait until rising_edge(clk); 
            
            expected.V := NONE; 
            expected.C := NONE; 
            case rand_f3 is
                when 0 =>  -- ADD/SUB
                    if input.f7 = ZERO_7bits then
                        sum_ext := resize(unsigned(to_unsigned(rand_A, DATA_WIDTH)), DATA_WIDTH+1) + 
                                   resize(unsigned(to_unsigned(rand_B, DATA_WIDTH)), DATA_WIDTH+1);
                        expected.result     := std_logic_vector(sum_ext(DATA_WIDTH-1 downto 0));
                        expected.operation  := ALU_ADD;
                        if sum_ext(DATA_WIDTH) = '1' then 
                            expected.C := Cf; 
                        else 
                            expected.C := NONE; 
                        end if;                      
                        
                        if ((input.A(DATA_WIDTH - 1) = input.B(DATA_WIDTH - 1)) and 
                           (expected.result(DATA_WIDTH - 1) /= input.A(DATA_WIDTH - 1))) then
                            expected.V := V; 
                        else 
                            expected.V := NONE; 
                        end if;
                        
                    else
                        sub_ext := resize(unsigned(to_unsigned(rand_A, DATA_WIDTH)), DATA_WIDTH+1) - 
                                   resize(unsigned(to_unsigned(rand_B, DATA_WIDTH)), DATA_WIDTH+1);
                        expected.result     := std_logic_vector(sub_ext(31 downto 0));
                        expected.operation  := ALU_SUB;
 
                        if sub_ext(DATA_WIDTH) = '0' then 
                            expected.C := Cf;  -- No borrow → C = 1
                        else 
                            expected.C := NONE;  -- Borrow → C = 0
                        end if;
                    
                        if ((input.A(DATA_WIDTH - 1) /= input.B(DATA_WIDTH - 1)) and 
                           (expected.result(DATA_WIDTH - 1) /= input.A(DATA_WIDTH - 1))) then
                            expected.V := V; 
                        else 
                            expected.V := NONE; 
                        end if;
 
                    end if;   
                    
                when 1 => -- SLL
                    expected.result := std_logic_vector(shift_left(unsigned(to_unsigned(rand_A,DATA_WIDTH)), 
                                       to_integer(unsigned(to_unsigned(rand_B,DATA_WIDTH)(4 downto 0))))); 
                    expected.operation  := ALU_SLL;
                    
                when 2 => -- SLT
                    if signed(to_signed(rand_A,32)) < signed(to_signed(rand_B,DATA_WIDTH)) then 
                        expected.result := (DATA_WIDTH-1 downto 1 => '0') & '1'; 
                        expected.operation  := ALU_SLT; 
                    else
                        expected := EMPTY_ALU_out;
                    end if;
                    
                when 3 => -- SLTU
                    if unsigned(to_unsigned(rand_A,32)) < unsigned(to_unsigned(rand_B,DATA_WIDTH)) then 
                        expected.result := (DATA_WIDTH-1 downto 1 => '0') & '1'; 
                        expected.operation  := ALU_SLTU;
                    else
                        expected := EMPTY_ALU_out;
                    end if;
       
                when 4 => -- XOR
                    expected.result := std_logic_vector(unsigned(to_unsigned(rand_A,DATA_WIDTH)) xor unsigned(to_unsigned(rand_B,DATA_WIDTH)));
                    expected.operation  := ALU_XOR;
                   
                when 5 => -- SRL/SRA
                    if input.f7 = ZERO_7bits then 
                        expected.result := std_logic_vector(shift_right(unsigned(to_unsigned(rand_A,DATA_WIDTH)), 
                                           to_integer(unsigned(to_unsigned(rand_B,DATA_WIDTH)(4 downto 0)))));
                        expected.operation  := ALU_SRL;
                    else 
                        expected.result := std_logic_vector(shift_right(signed(to_signed(rand_A,DATA_WIDTH)), 
                                           to_integer(unsigned(to_unsigned(rand_B,DATA_WIDTH)(SHIFT_WIDTH-1 downto 0)))));
                        expected.operation  := ALU_SRA;                   
                    end if;
                   
                when 6 =>  -- OR 
                    expected.result := std_logic_vector(unsigned(to_unsigned(rand_A,DATA_WIDTH)) or unsigned(to_unsigned(rand_B,DATA_WIDTH)));
                    expected.operation  := ALU_OR;

                when 7 => -- AND
                    expected.result := std_logic_vector(unsigned(to_unsigned(rand_A,DATA_WIDTH)) and unsigned(to_unsigned(rand_B,DATA_WIDTH)));
                    expected.operation  := ALU_AND;
                    
                when others => null;
            end case;

            if expected.result = ZERO_32bits then expected.Z := Z; else expected.Z := NONE; end if;
            if expected.result(DATA_WIDTH-1) = '1' then expected.N := N; else expected.N := NONE; end if;
             
            exp_out <= expected;
            
            -- Keep track the number of pass or fail
            if output.result = expected.result and output.Z = expected.Z and
               output.N = expected.N and output.V = expected.V and output.C = expected.C 
               and output.operation = expected.operation then
                pass := pass + 1;
            else
                fail := fail + 1;
                if output.Z /= expected.Z then 
                    fail_Z := fail_Z + 1;  
                    assert false report "Z flag mismatch" severity warning; 
                end if;
                
                if output.N /= expected.N then fail_N := fail_N + 1; end if;
                    
                if input.f3 = ZERO_3bits then
                    if output.V /= expected.V then fail_V := fail_V + 1; end if;
                    if output.C /= expected.C then fail_C := fail_C + 1; end if;
                end if;
                
                case input.f3 is
                    when FUNC3_ADD_SUB => 
                        if input.f7 = ZERO_7bits then 
                            fail_add := fail_add + 1; 
                        else 
                            fail_sub := fail_sub + 1; 
                        end if;
                    when FUNC3_SLL => fail_sll := fail_sll + 1;
                    when FUNC3_SLT => fail_slt := fail_slt + 1;
                    when FUNC3_SLTU => fail_sltu := fail_sltu + 1;
                    when FUNC3_XOR => fail_xor := fail_xor + 1;
                    when FUNC3_SRL_SRA => 
                        if input.f7 = ZERO_7bits then 
                            fail_srl := fail_srl + 1; 
                        else 
                            fail_sra := fail_sra + 1; 
                        end if;
                    when FUNC3_OR => fail_or := fail_or + 1;
                    when FUNC3_AND => fail_and := fail_and + 1;
                    when others => null;
                end case;
            end if;

        end loop;
        
        -- Summary report
        report "----------------------------------------------------";
        report "ALU Randomized Test Summary:";
        report "Total Tests      : " & integer'image(total_tests);
        report "Total Passes     : " & integer'image(pass);
        report "Total Failures   : " & integer'image(fail);
        report "Fails per Operation:";
        report "ADD  fails: " & integer'image(fail_add);
        report "SUB  fails: " & integer'image(fail_sub);
        report "SLL  fails: " & integer'image(fail_sll);
        report "SLT  fails: " & integer'image(fail_slt);
        report "SLTU fails: " & integer'image(fail_sltu);
        report "XOR  fails: " & integer'image(fail_xor);
        report "SRL  fails: " & integer'image(fail_srl);
        report "SRA  fails: " & integer'image(fail_sra);
        report "OR   fails: " & integer'image(fail_or);
        report "AND  fails: " & integer'image(fail_and);
        report "Flag Failures:";
        report "Z flag fails : " & integer'image(fail_Z);
        report "N flag fails : " & integer'image(fail_N);
        report "V flag fails : " & integer'image(fail_V);
        report "C flag fails : " & integer'image(fail_C);
        report "----------------------------------------------------";

        wait;
    end process;
end sim;