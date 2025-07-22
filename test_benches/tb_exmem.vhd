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
use work.instruction_generator.all;
--use work.decoder_function.all;
use work.MyFunctions.all;

entity tb_exmem is
--  Port ( );
end tb_exmem;

architecture sim of tb_exmem is

constant clk_period         : time              := 10 ns;
signal clk                  : std_logic         := '0';
signal rst                  : std_logic         := '1';
signal ex                   : Inst_PC_N         := init_Inst_PC_N;
signal ex_exp               : Inst_PC_N         := init_Inst_PC_N;
signal ex_content           : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;
signal ex_content_exp       : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;
signal ex_mem               : Inst_PC_N         := init_Inst_PC_N;
signal ex_mem_exp           : Inst_PC_N         := init_Inst_PC_N;
signal ex_mem_content       : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;
signal ex_mem_content_exp   : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;

begin
     UUT : entity work.EX_TO_MEM port map (
        clk             => clk,
        reset           => rst,
        EX              => ex,
        EX_content      => ex_content,
        EX_MEM          => ex_mem,
        EX_MEM_content  => ex_mem_content
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
    variable rand, rand2  : real;
    variable seed1, seed2 : positive        := 12345;
    variable actual       : Inst_PC_N       := init_Inst_PC_N;
    variable content_v    : EX_CONTENT_N    := EMPTY_EX_CONTENT_N; 
    
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
            actual.A.instr := instr_gen(rand);
            uniform(seed1, seed2, rand2);
            actual.B.instr := instr_gen(rand2);
            
            -- Increment pc
            actual.A.pc       := std_logic_vector(unsigned(ex.A.pc) + 8); 
            actual.B.pc       := std_logic_vector(unsigned(actual.A.pc) + 4); 
           
            -- Determine if the instruction is valid or not.
            -- Helped me check if the instruction will not be release if it is invalid
            if    rand < 0.9 then
                actual.A.is_valid := VALID;
            else 
                actual.A.is_valid := INVALID;
            end if;
            
            if    rand2  < 0.9 then
                actual.B.is_valid := VALID;
            else 
                actual.B.is_valid := INVALID;
            end if; 
            
            -- generate data
            uniform(seed1, seed2, rand);
            uniform(seed1, seed2, rand2);
            content_v.A.operand.A := get_32bits_val(rand);
            content_v.A.operand.B := get_32bits_val(rand2);
            uniform(seed1, seed2, rand);
            uniform(seed1, seed2, rand2);
            content_v.B.operand.A := get_32bits_val(rand);
            content_v.B.operand.B := get_32bits_val(rand2);
            
            content_v.A.alu.result  := get_32bits_val(rand);
            content_v.B.alu.result  := get_32bits_val(rand2);
            
            content_v.A.S_data      := get_32bits_val(rand);
            content_v.B.S_data      := get_32bits_val(rand2);
            
            content_v.A.rd          := std_logic_vector(to_unsigned(integer(rand * 32.0), 5));
            content_v.B.rd          := std_logic_vector(to_unsigned(integer(rand2 * 32.0), 5));
            
            content_v.A.cntrl       := Get_Control(actual.A.instr(6 downto 0));
            content_v.B.cntrl       := Get_Control(actual.B.instr(6 downto 0));

            if rand < 0.2 then
                content_v.A.alu.operation := ALU_ADD;  
                content_v.B.alu.operation := ALU_SUB;  
            elsif rand < 0.3 then 
                content_v.A.alu.operation := ALU_SUB;
                content_v.B.alu.operation := ALU_ADD; 
            elsif rand < 0.4 then 
                content_v.A.alu.operation := ALU_XOR;
                content_v.B.alu.operation := ALU_SLL;
            elsif rand < 0.5 then 
                content_v.A.alu.operation := ALU_OR;
                content_v.B.alu.operation := ALU_ADD;
            elsif rand < 0.6 then 
                content_v.A.alu.operation := ALU_AND;
                content_v.B.alu.operation := ALU_ADD;
            elsif rand < 0.5 then 
                content_v.A.alu.operation := ALU_SLL;
                content_v.B.alu.operation := ALU_ADD;
            elsif rand < 0.6 then 
                content_v.A.alu.operation := ALU_SRL;
                content_v.B.alu.operation := ALU_SUB;
            elsif rand < 0.7 then 
                content_v.A.alu.operation := ALU_SRA;
                content_v.B.alu.operation := ALU_SUB;
            elsif rand < 0.8 then 
                content_v.A.alu.operation := ALU_SLT;
                content_v.B.alu.operation := ALU_SUB;
            elsif rand < 0.9 then 
                content_v.A.alu.operation := ALU_SLTU;
                content_v.B.alu.operation := ALU_SUB;
            else
                content_v.A.alu.operation := NONE;
                content_v.B.alu.operation := NONE;
            end if;

            if content_v.A.alu.operation = ALU_ADD or content_v.A.alu.operation = ALU_SUB then
                if rand < 0.5 then
                    content_v.A.alu.C := Cf;
                else
                    content_v.A.alu.C := NONE;
                end if;
                if rand2 < 0.5 then
                    content_v.A.alu.V := V;
                else
                    content_v.A.alu.V := NONE;
                end if;
            else
                content_v.A.alu.C := NONE;
                content_v.A.alu.V := NONE;
            end if;
            
            if content_v.B.alu.operation = ALU_ADD or content_v.B.alu.operation = ALU_SUB then
                if rand < 0.5 then
                    content_v.B.alu.C := Cf;
                else
                    content_v.B.alu.C := NONE;
                end if;
                if rand2 < 0.5 then
                    content_v.B.alu.V := V;
                else
                    content_v.B.alu.V := NONE;
                end if;
            else
                content_v.B.alu.C := NONE;
                content_v.B.alu.V := NONE;
            end if;
            
            if content_v.A.alu.result = ZERO_32bits then
                content_v.A.alu.Z := Z;
            else
                content_v.A.alu.Z := NONE;
            end if;
            
            if content_v.B.alu.result = ZERO_32bits then
                content_v.B.alu.Z := Z;
            else
                content_v.B.alu.Z := NONE;
            end if;
            
            if content_v.A.alu.result(31) = '1' then
                content_v.A.alu.N := N;
            else
                content_v.A.alu.N := NONE;
            end if;
            
            if content_v.B.alu.result(31) = '1' then
                content_v.B.alu.N := N;
            else
                content_v.B.alu.N := NONE;
            end if;
            
            -- actual input assignment
            ex         <= actual;
            ex_content <= content_v;
            
            -- expected input assignment
            ex_exp         <= actual;
            ex_content_exp <= content_v;
            
 
        -- EXPECTED output assignments
            if rst = '1' then
                ex_mem_exp         <= EMPTY_Inst_PC_N;
                ex_mem_content_exp <= EMPTY_EX_CONTENT_N; 
            else
                ex_mem_exp         <= ex_exp;
                ex_mem_content_exp <= ex_content_exp; 
            end if;
            
            -- Let the result settle down
            wait until rising_edge(clk);
            
            -- Keep track the test
            if ex = ex_exp and ex_content = ex_content_exp and ex_mem = ex_mem_exp and
               ex_mem_content = ex_mem_content_exp then
                pass := pass +1;
            else
                fail := fail + 1;
 
            end if;
     
        end loop;
        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)  severity note;
        report "Passed:      " & integer'image(pass)         severity note;
        report "Failed:      " & integer'image(fail)         severity note;
        
        wait;
    end process;
end sim;
