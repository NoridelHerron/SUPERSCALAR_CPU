------------------------------------------------------------------------------
-- Noridel Herron
-- 6/13/2025
-- test bench for Forwarding unit
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

entity tb_Forw is
--  Port ( );
end tb_Forw;

architecture sim of tb_Forw is

signal clk          : std_logic := '0';
signal rst          : std_logic := '1';

signal EX_MEM       : EX_CONTENT_N_INSTR; 
signal WB           : WB_CONTENT_N_INSTR;
signal ID_EX        : DECODER_N_INSTR;
signal reg          : REG_DATAS;
signal Forw         : HDU_OUT_N;   
signal result       : EX_OPERAND_N;

constant clk_period : time := 10 ns;
    
begin
    
    UUT : entity work.Forw_Unit port map (
        EX_MEM      => EX_MEM,
        WB          => WB,
        ID_EX       => ID_EX,
        reg         => reg,
        Forw        => Forw,
        operands    => result
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
    variable r_EX_MEM_A, r_EX_MEM_B, r_WB_A, r_WB_B : real;
    variable reg1A, reg1B, reg2A, reg2B             : real;
    variable r_imm_A, r_imm_B, r_op_A, r_op_B       : real;
    variable seed1, seed2                           : positive  := 12345;
    variable total_tests                            : integer   := 20000;
    variable pass, fail                             : integer   := 0; -- Keep track test
    variable EX_MEM_v                               : EX_CONTENT_N_INSTR; 
    variable WB_v                                   : WB_CONTENT_N_INSTR;
    variable ID_EX_v                                : DECODER_N_INSTR;
    variable reg_v                                  : REG_DATAS;
    variable Forw_v                                 : HDU_OUT_N;   
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        for i in 1 to total_tests loop
            -- This will cover all instructions in riscv
           
           
           
            wait until rising_edge(clk);  -- Decoder captures input
            wait for 1 ns;                -- Let ID_content settle

            -- Compare fields
            if actual_res = expected_res then
                pass := pass + 1; 
            else
                fail := fail + 1;
            end if;            
 
            wait for 10 ns;
        end loop;

        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)     severity note;
        report "Passed:      " & integer'image(pass)            severity note;
        report "Failed:      " & integer'image(fail)            severity note;

        wait;
    end process;

end sim;