------------------------------------------------------------------------------
-- Noridel Herron
-- 6/20/2025
-- testbench 2 for ex stage
-- this is for closely monitoring the specific cases. 
-- The tb_ex_stage.sv is for catching edge cases
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

entity tb_ex_stage is
   -- Port ( );
end tb_ex_stage;

architecture Behavioral of tb_ex_stage is

signal clk                           : std_logic := '0';
signal rst                           : std_logic := '1';

signal ID_EX     : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR; 
signal reg       : REG_DATAS          := EMPTY_REG_DATAS; 
signal EX_MEM    : EX_CONTENT_N       := EMPTY_EX_CONTENT_N; 
signal EX_MEM_c1 : control_Type       := EMPTY_control_Type;
signal EX_MEM_c2 : control_Type       := EMPTY_control_Type;
signal WB        : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR; 
signal Forw      : HDU_OUT_N          := EMPTY_HDU_OUT_N;    
signal ex_out    : EX_CONTENT_N       := EMPTY_EX_CONTENT_N; 
signal expected  : EX_CONTENT_N       := EMPTY_EX_CONTENT_N; 
constant clk_period                 : time := 10 ns;

begin

UUT : entity work.ex_stage port map (
       EX_MEM   => EX_MEM, 
       WB       => WB, 
       ID_EX    => ID_EX, 
       reg      => reg, 
       Forw     => Forw, 
       ex_out   => ex_out
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
    variable temp_EX_MEM   : EX_CONTENT_N       := EMPTY_EX_CONTENT_N; 
    variable temp_WB       : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR; 
    variable temp_ID_EX    : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR; 
    variable temp_reg      : REG_DATAS          := EMPTY_REG_DATAS;  
    variable temp_Forw     : HDU_OUT_N          := EMPTY_HDU_OUT_N;    
    variable temp_ex_out   : EX_CONTENT_N       := EMPTY_EX_CONTENT_N; 
    variable E_c1, E_c2    : control_Type       := EMPTY_control_Type;
    variable operands      : EX_OPERAND_N       := EMPTY_EX_OPERAND_N;  
    -- randomized used for generating values
    variable rand1, rand2  : real;
    variable rd, rs1, rs2  : real;
    variable seed1, seed2  : positive     := 12345;
    -- Keep track test
    variable pass, fail    : integer      := 0;
    variable faA, frA, foA, fsA, faB, frB, foB, fsB : integer := 0;

    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        for i in 1 to total_tests loop

            -- This will cover all instructions in riscv
            uniform(seed1, seed2, rand1);
            uniform(seed1, seed2, rs1);
            uniform(seed1, seed2, rs2);
            uniform(seed1, seed2, rd);
            temp_ID_EX.A := get_decoded_val(rand1, rs1, rs2, rd);

            uniform(seed1, seed2, rand2);
            uniform(seed1, seed2, rs1);
            uniform(seed1, seed2, rs2);
            uniform(seed1, seed2, rd);
            temp_ID_EX.B := get_decoded_val(rand1, rs1, rs2, rd);
            
            uniform(seed1, seed2, rand1); temp_reg.one.A := get_32bits_val(rand1);
            uniform(seed1, seed2, rand2); temp_reg.one.B := get_32bits_val(rand2);
            uniform(seed1, seed2, rand1); temp_reg.two.A := get_32bits_val(rand1);
            uniform(seed1, seed2, rand2); temp_reg.two.B := get_32bits_val(rand2);
            
            -- Since FORW_FROM_A only occur in 2nd instruction, 
            -- this will make sure my customized function will not return FORW_FROM_A and instruction A
            uniform(seed1, seed2, rand1); temp_Forw.A.forwA := get_forwStats(rand1);
            while temp_Forw.A.forwA = FORW_FROM_A loop
                uniform(seed1, seed2, rand1); 
                temp_Forw.A.forwA := get_forwStats(rand1);
            end loop;
            
            uniform(seed1, seed2, rand1); temp_Forw.A.forwB := get_forwStats(rand1);
            while temp_Forw.A.forwB = FORW_FROM_A loop
                uniform(seed1, seed2, rand1); 
                temp_Forw.A.forwB := get_forwStats(rand1);
            end loop;
            uniform(seed1, seed2, rand1); temp_Forw.A.stall := get_stall (temp_ID_EX.A.op, rand1);
            while temp_Forw.A.stall /= A_STALL and temp_Forw.A.stall /= B_STALL 
                  and temp_Forw.A.stall /= NONE_h loop
                uniform(seed1, seed2, rand1); 
                temp_Forw.A.stall := get_stall (temp_ID_EX.A.op, rand1);
            end loop;
            
            uniform(seed1, seed2, rand2); temp_Forw.B.forwA := get_forwStats(rand2);
            uniform(seed1, seed2, rand2); temp_Forw.B.forwB := get_forwStats(rand2);
            uniform(seed1, seed2, rand2); temp_Forw.B.stall := get_stall (temp_ID_EX.B.op, rand2);
            
            expected    <= temp_EX_MEM;
            wait until rising_edge(clk);  

            temp_EX_MEM.A.rd  := ID_EX.A.rd;
            temp_EX_MEM.B.rd  := ID_EX.B.rd;
            E_c1              := Get_Control(ID_EX.A.op);
            E_c2              := Get_Control(ID_EX.B.op);
            
            temp_WB.A.data    := EX_MEM.A.alu.result;
            temp_WB.B.data    := EX_MEM.B.alu.result;
            temp_WB.A.rd      := EX_MEM.A.rd;
            temp_WB.B.rd      := EX_MEM.B.rd;
            temp_WB.A.we      := EX_MEM_c1.wb;
            temp_WB.B.we      := EX_MEM_c2.wb;
            
            operands          := get_operands ( temp_EX_MEM, temp_WB, temp_ID_EX, temp_reg, temp_Forw );
            temp_EX_MEM.A.alu := get_alu_res (temp_ID_EX.A.funct3, temp_ID_EX.A.funct7, operands.one.A, operands.one.B);
            temp_EX_MEM.B.alu := get_alu_res (temp_ID_EX.B.funct3, temp_ID_EX.B.funct7, operands.two.A, operands.two.B);
            
            temp_ex_out.A.operand := operands.one;
            temp_ex_out.A.S_data  := operands.S_data1;
            temp_ex_out.A.alu     := temp_EX_MEM.A.alu;
            temp_ex_out.A.rd      := temp_EX_MEM.A.rd;
            temp_ex_out.B.operand := operands.two;
            temp_ex_out.B.S_data  := operands.S_data2;
            temp_ex_out.B.alu     := temp_EX_MEM.B.alu;
            temp_ex_out.B.rd      := temp_EX_MEM.B.rd;
            
            Forw        <= temp_Forw;
            ID_EX       <= temp_ID_EX;
            reg         <= temp_reg;
            EX_MEM      <= temp_EX_MEM;  
            EX_MEM_c1   <= E_c1;
            EX_MEM_c2   <= E_c2;
            WB          <= temp_WB; 
            
            
            wait until rising_edge(clk);  
            wait for 1 ns;                
            
            if expected = ex_out then
                pass := pass + 1;
            else
                fail := fail + 1;
                if expected.A.operand /= ex_out.A.operand then
                    foA := foA + 1;
                end if;
                
                if expected.A.S_data /= ex_out.A.S_data then
                    fsA := fsA + 1;
                end if;
                
                if expected.A.alu /= ex_out.A.alu then
                    faA := faA + 1;
                end if;
                
                if expected.A.rd /= ex_out.A.rd then
                    frA := frA + 1;
                end if;
                
                if expected.B.operand /= ex_out.B.operand then
                    foB := foB + 1;
                end if;
                
                if expected.B.S_data /= ex_out.B.S_data then
                    fsB := fsB + 1;
                end if;
                
                if expected.B.alu /= ex_out.B.alu then
                    faB := faB + 1;
                end if;
                
                if expected.B.rd /= ex_out.B.rd then
                    frB := frB + 1;
                end if;
            end if;

        end loop;
        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)     severity note;
        report "Passed:      " & integer'image(pass)            severity note;
        report "Failed:      " & integer'image(fail)            severity note;
        report "======= A =======" severity note;
        report "OPERAND:     " & integer'image(foA)             severity note;
        report "ALU:         " & integer'image(faA)             severity note;
        report "RD:          " & integer'image(frA)             severity note;
        report "S_data:      " & integer'image(fsA)             severity note;
        report "======= B =======" severity note;
        report "OPERAND:     " & integer'image(foB)             severity note;
        report "ALU:         " & integer'image(faB)             severity note;
        report "RD:          " & integer'image(frB)             severity note;
        report "S_data:      " & integer'image(fsB)             severity note;
        wait;
    end process;


end Behavioral;
