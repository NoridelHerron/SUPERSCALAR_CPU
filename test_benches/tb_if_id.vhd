------------------------------------------------------------------------------
-- Noridel Herron
-- 7/3/2025
-- testbench for IF_TO_ID reg
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

entity tb_if_id is
   -- Port ( );
end tb_if_id;

architecture Behavioral of tb_if_id is

signal clk       : std_logic := '0';
signal rst       : std_logic := '1';
signal if_stage  : Inst_PC_N := init_Inst_PC_N;
signal if_exp    : Inst_PC_N := init_Inst_PC_N;
signal if_id     : Inst_PC_N := EMPTY_Inst_PC_N; 
signal if_id_exp : Inst_PC_N := EMPTY_Inst_PC_N; 

constant clk_period                 : time := 10 ns;

begin

UUT : entity work.IF_TO_ID port map (
        clk      => clk,
       reset     => rst,
       if_stage  => if_stage,
       if_id     => if_id
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
    variable total_tests   : integer            := 20000;
    
    -- randomized used for generating values
    variable rand, rand2    : real;
    variable seed1, seed2   : positive  := 12345;
    variable actual         : Inst_PC_N := init_Inst_PC_N;
    variable expected       : Inst_PC_N := init_Inst_PC_N;
    variable exp_out        : Inst_PC_N := EMPTY_Inst_PC_N;
    -- Keep track test
    variable pass, fail     : integer   := 0;
    -- Narrow down the bugs variables
    variable fin, fout      : integer   := 0;
    variable fip, fii, fiv  : integer   := 0;
    variable fop, foi, fov  : integer   := 0;

    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period * 2;
       
        for i in 1 to total_tests loop
            
            -- Generate random value
            uniform(seed1, seed2, rand);
            uniform(seed1, seed2, rand2);
            
            -- ACTUAL input assignment
            -- Generate instructions
            actual.A.instr    := instr_gen(rand);
            actual.B.instr    := instr_gen(rand2);
            
            -- Increment pc
            actual.A.pc       := std_logic_vector(unsigned(if_stage.A.pc) + 8); 
            actual.B.pc       := std_logic_vector(unsigned(actual.A.pc) + 4); 
           
            -- Determine if the instruction is valid or not.
            -- Helped me check if the instruction will not be release if it is invalid
            if    rand < 0.7 then
                actual.A.is_valid := VALID;
            else 
                actual.A.is_valid := INVALID;
            end if;
            
            if    rand2  < 0.7 then
                actual.B.is_valid := VALID;
            else 
                actual.B.is_valid := INVALID;
            end if;
 
            -- EXPECTED input assignment
            expected.A.is_valid := actual.A.is_valid;
            expected.B.is_valid := actual.B.is_valid;
            expected.A.instr    := actual.A.instr;
            expected.B.instr    := actual.B.instr;
            expected.A.pc       := std_logic_vector(unsigned(if_exp.A.pc) + 8); 
            expected.B.pc       := std_logic_vector(unsigned(expected.A.pc) + 4); 
            
            -- ACTUAL
            if_stage.A.pc       <= actual.A.pc;
            if_stage.B.pc       <= actual.B.pc;
            if_stage.A.instr    <= actual.A.instr;
            if_stage.B.instr    <= actual.B.instr;
            if_stage.A.is_valid <= actual.A.is_valid;
            if_stage.B.is_valid <= actual.B.is_valid;
            
            -- EXPECTED
            if_exp.A.pc         <= expected.A.pc;
            if_exp.B.pc         <= expected.B.pc;
            if_exp.A.instr      <= actual.A.instr;
            if_exp.B.instr      <= actual.B.instr;
            if_exp.A.is_valid   <= expected.A.is_valid;
            if_exp.B.is_valid   <= expected.B.is_valid;       
            
            -- EXPECTED output assignments
            if if_exp.A.is_valid = VALID then
                exp_out.A := if_exp.A;  
                
                if if_exp.B.is_valid = VALID then
                    exp_out.B := if_exp.B; 
                else
                    exp_out.B := if_exp.B; 
                    exp_out.B.is_valid := HOLD;
                    
                end if;
            else
                exp_out            := if_exp;
                exp_out.A.is_valid := HOLD;
                exp_out.B.is_valid := HOLD;
            end if;
  
            if_id_exp  <= exp_out;
            
            -- Let the result settle down
            wait until rising_edge(clk);
            
            -- Keep track the test
            if if_stage = if_exp and if_id = if_id_exp then
                pass := pass +1;
            else
                fail := fail + 1;
                -- If fail the nested logic will help narrow down the bugs
                if if_stage /= if_exp then
                    fin := fin + 1;
                    if if_stage.A.pc /= if_exp.A.pc or if_stage.B.pc /= if_exp.B.pc then
                        fip := fip + 1;
                    end if;
                    if if_stage.A.instr /= if_exp.A.instr or if_stage.B.instr /= if_exp.B.instr then
                        fii := fii + 1;
                    end if;
                    if if_stage.A.is_valid /= if_exp.A.is_valid or if_stage.B.is_valid /= if_exp.B.is_valid then
                        fiv := fiv + 1;
                    end if;
                end if;
                
                if if_id /= if_id_exp then
                    fout := fout + 1;
                    if if_id.A.pc /= if_id_exp.A.pc or if_id.B.pc /= if_id_exp.B.pc then
                        fop := fop + 1;
                    end if;
                    if if_id.A.instr /= if_id_exp.A.instr or if_id.B.instr /= if_id_exp.B.instr then
                        foi := foi + 1;
                    end if;
                    if if_id.A.is_valid /= if_id_exp.A.is_valid or if_id.B.is_valid /= if_id_exp.B.is_valid then
                        fov := fov + 1;
                    end if;
                end if;
            end if;
            
        end loop;
        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)  severity note;
        report "Passed:      " & integer'image(pass)         severity note;
        if fail /= 0 then 
            report "Failed:      " & integer'image(fail)     severity note;
            if fin /= 0 then
                report "======= INPUT =======" severity note;
                report "Failed: in   " & integer'image(fin)  severity note;
                if fip /= 0 then
                    report "Failed: pc          " & integer'image(fip)  severity note;
                end if;
                if fii /= 0 then
                    report "Failed: instruction " & integer'image(fii)  severity note;
                end if;
                if fiv /= 0 then
                    report "Failed: is_valid    " & integer'image(fiv)  severity note;
                end if;
                report "======================" severity note;
            end if;
            if fout /= 0 then
                report "======= OUTPUT =======" severity note;
                report "Failed: out  " & integer'image(fout) severity note;
                if fop /= 0 then
                    report "Failed: pc          " & integer'image(fop)  severity note;
                end if;
                if foi /= 0 then
                    report "Failed: instruction " & integer'image(foi)  severity note;
                end if;
                if fov /= 0 then
                    report "Failed: is_valid    " & integer'image(fov)  severity note;
                end if;
            end if;
        end if;
        wait;
    end process;

end Behavioral;
