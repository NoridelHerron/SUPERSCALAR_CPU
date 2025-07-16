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
use work.MyFunctions.all;

entity tb_mem_wb is
--  Port ( );
end tb_mem_wb;

architecture sim of tb_mem_wb is

constant clk_period      : time              := 10 ns;
signal clk               : std_logic         := '0';
signal rst               : std_logic         := '1';

-- inputs from ex_mem register (actual and expected)
signal exmem             : Inst_PC_N         := init_Inst_PC_N;
signal exmem_exp         : Inst_PC_N         := init_Inst_PC_N;
signal exmem_content     : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;
signal exmem_content_exp : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;
signal exmem_control     : control_Type_N    := EMPTY_control_Type_N;
signal exmem_control_exp : control_Type_N    := EMPTY_control_Type_N;

-- from inputs mem_stage (actual and expected)
signal memA              : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal memA_exp          : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

-- outputs
signal memwb             : Inst_PC_N         := init_Inst_PC_N;
signal memwb_exp         : Inst_PC_N         := init_Inst_PC_N;
signal memwb_content     : MEM_CONTENT_N     := EMPTY_MEM_CONTENT_N;
signal memwb_content_exp : MEM_CONTENT_N     := EMPTY_MEM_CONTENT_N;



begin
     UUT : entity work.MEM_WB port map (
       clk            => clk,
       reset          => rst,
       ex_mem         => exmem,
       exmem_content  => exmem_content,
       ex_cntrl       => exmem_control,
       memA_result    => memA,
       mem_wb         => memwb,  
       mem_wb_content => memwb_content
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
    variable rand, rand2     : real;
    variable seed1, seed2    : positive        := 12345;
    variable exmem_v         : Inst_PC_N         := init_Inst_PC_N;
    variable exmem_content_v : EX_CONTENT_N      := EMPTY_EX_CONTENT_N;
    variable exmem_control_v : control_Type_N    := EMPTY_control_Type_N;

    variable memA_v          : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    variable memwb_v         : Inst_PC_N         := init_Inst_PC_N;
    variable memwb_content_v : MEM_CONTENT_N     := EMPTY_MEM_CONTENT_N;

    variable total_tests   : integer            := 20000;
    -- Keep track test
    variable pass, fail     : integer   := 0;
    -- Narrow down bugs
    variable f_e, f_ec, f_ctrl, f_mA, f_mB, f_m, f_mc : integer   := 0;
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period * 2;
        
        for i in 1 to total_tests loop  
            wait for clk_period / 4; 
            uniform(seed1, seed2, rand);
            exmem_v.A.instr := instr_gen(rand);
            uniform(seed1, seed2, rand2);
            exmem_v.B.instr := instr_gen(rand2);
            
            -- Increment pc
            exmem_v.A.pc       := std_logic_vector(unsigned(exmem.A.pc) + 8); 
            exmem_v.B.pc       := std_logic_vector(unsigned(exmem_v.A.pc) + 4); 
           
            
            exmem_v.A.is_valid := VALID;
            exmem_v.B.is_valid := VALID;
            
            -- generate data
            -- A
            uniform(seed1, seed2, rand);  exmem_content_v.A.alu.result := get_32bits_val(rand);
                                          exmem_content_v.A.rd := std_logic_vector(to_unsigned(integer(rand * 32.0), 5));
            uniform(seed1, seed2, rand2); memA_v := get_32bits_val(rand2);
            
            if rand < 0.5 then 
                exmem_control_v.A.mem := MEM_READ;
            else
                exmem_control_v.A.mem := NONE_c;
            end if;
            
            if exmem_control_v.A.mem = MEM_READ then
                exmem_control_v.A.wb := REG_WRITE;
            elsif rand2 < 0.5 then 
                exmem_control_v.A.wb := NONE_c;
            else
                exmem_control_v.A.wb := REG_WRITE;
            end if;
    
            -- B
            uniform(seed1, seed2, rand);  exmem_content_v.B.alu.result := get_32bits_val(rand);
                                          exmem_content_v.B.rd := std_logic_vector(to_unsigned(integer(rand2 * 32.0), 5));
            
            if rand < 0.5 then 
                exmem_control_v.B.mem := MEM_READ;
            else
                exmem_control_v.B.mem := NONE_c;
            end if;
            
            if exmem_control_v.B.mem = MEM_READ then
                exmem_control_v.B.wb := REG_WRITE;
            elsif rand2 < 0.5 then 
                exmem_control_v.B.wb := NONE_c;
            else
                exmem_control_v.B.wb := REG_WRITE;
            end if;
 
            -- actual input assignment
            exmem           <= exmem_v;
            exmem_content   <= exmem_content_v;
            exmem_control   <= exmem_control_v;
            memA            <= memA_v;
            
            -- expected input assignment
            exmem_exp           <= exmem_v;
            exmem_content_exp   <= exmem_content_v;
            exmem_control_exp   <= exmem_control_v;
            memA_exp            <= memA_v;
            
            -- EXPECTED output assignments
            if rst = '1' then
                memwb_exp         <= EMPTY_Inst_PC_N;
                memwb_content_exp <= EMPTY_MEM_CONTENT_N;
                
            else
                wait until rising_edge(clk);
                memwb_exp         <= exmem_v;
                -- A
                memwb_content_exp.A.alu <= exmem_content_exp.A.alu.result;
                memwb_content_exp.A.rd  <= exmem_content_exp.A.rd;
                memwb_content_exp.A.mem <= memA_exp;
                memwb_content_exp.A.we  <= exmem_control_exp.A.wb;
                memwb_content_exp.A.me  <= exmem_control_exp.A.mem;
                -- B
                memwb_content_exp.B.alu <= exmem_content_exp.B.alu.result;
                memwb_content_exp.B.rd  <= exmem_content_exp.B.rd;
                memwb_content_exp.B.mem <= (others => '0');
                memwb_content_exp.B.we  <= exmem_control_exp.B.wb;
                memwb_content_exp.B.me  <= exmem_control_exp.B.mem;

            end if;
        
            -- Let the result settle down
             wait until rising_edge(clk);
            
            -- Keep track the test
            if exmem = exmem_exp and exmem_content = exmem_content_exp and exmem_control = exmem_control_exp and
               memA = memA_exp and memwb = memwb_exp and memwb_content = memwb_content_exp then
                pass := pass +1;
            else
                fail := fail + 1;
 
            end if;
     
        end loop;
        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)  severity note;
        report "Passed:      " & integer'image(pass)         severity note;
        report "Failed:      " & integer'image(fail)     severity note;
        
        wait;
    end process;
end sim;
