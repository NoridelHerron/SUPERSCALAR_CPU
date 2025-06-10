------------------------------------------------------------------------------
-- Noridel Herron
-- 6/10/2025
-- Extracts opcode, registers, function codes, and immediate values from a 32-bit instruction. 
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

entity tb_control_signal is
--  Port ( );
end tb_control_signal;

architecture sim of tb_control_signal is

signal clk       : std_logic    := '0';
signal rst       : std_logic    := '1';
signal opcode    : std_logic_vector(OPCODE_WIDTH-1 downto 0) := ZERO_7bits; 
signal actual    : control_Type := EMPTY_control_Type;
signal expected  : control_Type := EMPTY_control_Type;

constant clk_period         : time := 10 ns;

begin
    
    UUT : entity work.control_gen port map (
        opcode     => opcode,
        ctrl_sig   => actual
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
    variable total_tests    : integer      := 20000;
    variable rand_real      : real;
    variable seed1, seed2   : positive     := 42;
    variable temp           : control_Type := EMPTY_control_Type;
    variable temp_op        : std_logic_vector(OPCODE_WIDTH-1 downto 0) := ZERO_7bits;
    
    -- keep track 
    variable pass, fail, fail_t, fail_a, fail_m, fail_w : integer      := 0;

    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;

        for i in 1 to total_tests loop
            -- This will cover 6 types of instructions in riscv
            uniform(seed1, seed2, rand_real);

            if rand_real < 0.1     then temp_op := JAL;   
            elsif rand_real < 0.2  then temp_op := LOAD;
            elsif rand_real < 0.3  then temp_op := S_TYPE;
            elsif rand_real < 0.5  then temp_op := B_TYPE;
            elsif rand_real < 0.75 then temp_op := I_IMME;
            else temp_op := R_TYPE;
            end if;
            
            temp.target := NONE;
            temp.alu    := IMM;
            temp.mem    := NONE;
            temp.wb     := REG_WRITE;    
            
            case temp_op is
                when R_Type =>   
                    temp.target := ALU_REG;
                    temp.alu    := RS2;
                    
                when I_IMME => 
                    temp.target := ALU_REG;
                    
                when LOAD   =>
                    temp.target := MEM_REG;
                    temp.mem    := MEM_READ;
                    
                when S_TYPE =>
                    temp.target := MEM_REG;
                    temp.mem    := MEM_WRITE;
                    
                when B_TYPE =>
                    temp.alu    := RS2;
                    temp.wb     := NONE;
                    temp.target := BRANCH;
                    
                when JAL =>
                    temp.target := JUMP;
                    temp.alu    := NONE; 
                when others => temp := EMPTY_control_Type;
            end case;
            
            opcode    <= temp_op;
            expected  <= temp;
            
            wait until rising_edge(clk); 
            wait for 1 ns;
            
            if actual.target = expected.target and actual.alu = expected.alu and
               actual.mem = expected.mem and actual.wb = expected.wb then
               pass := pass + 1;
            else
               fail := fail + 1;
               
               -- Narrow down bugs
               if actual.target = expected.target then
                    fail_t := fail_t + 1;
               end if;
               
               if actual.alu = expected.alu then
                    fail_a := fail_a + 1;
               end if;
               
               if actual.mem = expected.mem then
                    fail_m := fail_m + 1;
               end if;
               
               if actual.wb = expected.wb then
                    fail_w := fail_w + 1;
               end if; 
            end if;    
                   
        wait for clk_period;  
        end loop;
        
        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)  severity note;
        report "Passed:      " & integer'image(pass)         severity note;
        report "Failed:      " & integer'image(fail)         severity note;
        
        -- Narrow down bugs
        report "target_sig Fails:  " & integer'image(fail_t)  severity note;
        report "alu_sig Fails:     " & integer'image(fail_a)  severity note;
        report "mem_sig Fails:     " & integer'image(fail_m)  severity note;
        report "wb_sig Fails:      " & integer'image(fail_w)  severity note;
        
        wait;
    end process;

end sim;
