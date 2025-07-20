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

constant clk_period : time := 10 ns;
signal clk          : std_logic := '0';
signal rst          : std_logic := '1';
signal isEnable     : std_logic := '0';

signal counter      : integer   := 0;
signal Forw         : HDU_OUT_N             := EMPTY_HDU_OUT_N;  
signal act_result   : EX_OPERAND_N          := EMPTY_EX_OPERAND_N; 
signal exp_result   : EX_OPERAND_N          := EMPTY_EX_OPERAND_N; 
signal EX_MEM       : EX_CONTENT_N          := EMPTY_EX_CONTENT_N; 
signal MEM_WB       : WB_CONTENT_N_INSTR    := EMPTY_WB_CONTENT_N_INSTR; 
signal ID_EX        : DECODER_N_INSTR       := EMPTY_DECODER_N_INSTR; 
signal reg_val      : REG_DATAS             := EMPTY_REG_DATAS; 

begin
    
    UUT : entity work.Forw_Unit 
    generic map ( ENABLE_FORWARDING => false )  -- isEnable must be the same with this when true isEnable = '1' else '0'
    port map (
        EX_MEM      => EX_MEM,
        WB          => MEM_WB,
        ID_EX       => ID_EX,
        reg         => reg_val,
        Forw        => Forw,
        operands    => act_result
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
    variable r_EX_MEM, r_WB, reg, r_imm12, r_imm20 : real;
    variable rand, r_op                            : real;
    variable seed1, seed2                          : positive           := 12345;
    variable total_tests, def                      : integer            := 20000;
    variable pass, fail, fail_o1A, fail_o1B        : integer            := 0; -- Keep track test
    variable fail_o2A, fail_o2B                    : integer            := 0; -- Keep track test
    variable EX_MEM_v                              : EX_CONTENT_N       := EMPTY_EX_CONTENT_N; 
    variable MEM_WB_v                              : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;
    variable ID_EX_v                               : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
    variable reg_v                                 : REG_DATAS          := EMPTY_REG_DATAS;
    variable Forw_v                                : HDU_OUT_N          := EMPTY_HDU_OUT_N;  
    variable operA                                 : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA;
    variable operB                                 : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA;
    variable exp_result_v                          : EX_OPERAND_N       := EMPTY_EX_OPERAND_N;  
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        for i in 1 to total_tests loop
            -- GENERATE value for possible source operands based on forwarding status
            uniform(seed1, seed2, r_EX_MEM); EX_MEM_v.A.alu.result  := get_32bits_val(r_EX_MEM); 
            uniform(seed1, seed2, r_EX_MEM); EX_MEM_v.B.alu.result  := get_32bits_val(r_EX_MEM); 
            uniform(seed1, seed2, r_WB);     MEM_WB_v.A.data        := get_32bits_val(r_WB); 
            uniform(seed1, seed2, r_WB);     MEM_WB_v.B.data        := get_32bits_val(r_WB); 
            uniform(seed1, seed2, reg);      reg_v.one.A            := get_32bits_val(reg); 
            uniform(seed1, seed2, reg);      reg_v.one.B            := get_32bits_val(reg);  
            uniform(seed1, seed2, reg);      reg_v.two.A            := get_32bits_val(reg); 
            uniform(seed1, seed2, reg);      reg_v.two.B            := get_32bits_val(reg); 
            
          --  uniform(seed1, seed2, r_imm20);  ID_EX_v.A.imm20        := get_imm20_val(r_imm20);
          --  uniform(seed1, seed2, r_imm20);  ID_EX_v.B.imm20        := get_imm20_val(r_imm20);
            
            -- GENERATE opcode value for operand B of 1st and 2nd instructions just in case no forwarding is needed
            uniform(seed1, seed2, r_op);     ID_EX_v.A.op     := get_op(r_op);
            uniform(seed1, seed2, r_op);     ID_EX_v.B.op     := get_op(r_op);
            
            if ID_EX_v.A.op = S_TYPE or ID_EX_v.A.op = LOAD or ID_EX_v.A.op = I_IMME then
                uniform(seed1, seed2, r_imm12);  ID_EX_v.A.imm12 := get_imm12_val(r_imm12); 
            else
                ID_EX_v.A.imm12 := ZERO_32bits;
            end if;
            
            if ID_EX_v.B.op = S_TYPE or ID_EX_v.B.op = LOAD or ID_EX_v.B.op = I_IMME then
                uniform(seed1, seed2, r_imm12);  ID_EX_v.B.imm12 := get_imm12_val(r_imm12);
            else
                ID_EX_v.A.imm12 := ZERO_32bits;
            end if;
            
            
            -- GENERATE forwarding status
            uniform(seed1, seed2, rand); Forw_v.A.forwA       := get_forwStats (rand);
            uniform(seed1, seed2, rand); Forw_v.A.forwB       := get_forwStats (rand);
            uniform(seed1, seed2, rand); Forw_v.B.forwA       := get_forwStats (rand);
            uniform(seed1, seed2, rand); Forw_v.B.forwB       := get_forwStats (rand);

            -- Generate intra-dependency status between instruction A and B of the same cycle
            uniform(seed1, seed2, rand);
            if    rand < 0.1 then 
                Forw_v.B.forwA    := FORW_FROM_A; 
            else 
                Forw_v.B.forwA    := NONE_h; 
            end if;
            
            uniform(seed1, seed2, rand);
            if    rand < 0.1 then 
                Forw_v.B.forwB    := FORW_FROM_A; 
            else 
                Forw_v.B.forwB    := NONE_h; 
            end if;
            
            -- Get the expected output (see MyFuntions.vhd and MyFuntions_body.vhd)
            exp_result_v := get_operands ( isEnable, EX_MEM_v, MEM_WB_v, ID_EX_v, reg_v, Forw_v ); 
            
            -- Assign inputs
            Forw        <= Forw_v;
            EX_MEM      <= EX_MEM_v;
            MEM_WB      <= MEM_WB_v;
            ID_EX       <= ID_EX_v;
            reg_val     <= reg_v;
            counter     <= i;
            
            exp_result  <= exp_result_v;
           -- wait until rising_edge(clk);  
            -- Compare fields
            if act_result.one = exp_result.one and act_result.two = exp_result.two then
                pass := pass + 1; 
            else
                if Forw_v.B.forwA = FORW_FROM_A then
                    pass := pass + 1;  
                else
                    if act_result.one.A /= exp_result.one.A then
                        report "fail_o1A: " & integer'image(i);
                        fail_o1A := fail_o1A + 1;
                    end if;
                    
                    if act_result.one.B /= exp_result.one.B then
                        report "fail_o1B: " & integer'image(i);
                        fail_o1B := fail_o1B + 1;
                    end if;
                    
                    if Forw_v.B.forwB = FORW_FROM_A then 
                        pass := pass + 1;
                    else     
                        if act_result.two.A /= exp_result.two.A then
                            report "fail_o2A: " & integer'image(i);
                            fail_o2A := fail_o2A + 1;
                        end if;
                        
                        if act_result.two.B /= exp_result.two.B then
                            report "fail_o2B: " & integer'image(i);
                            fail_o2B := fail_o2B + 1;
                        end if;
                    end if;
                    fail := fail + 1;
                end if; 
            end if;            
 
            wait for 10 ns;
        end loop;

        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)     severity note;
        report "Passed:      " & integer'image(pass)            severity note;
        report "Failed:      " & integer'image(fail)            severity note;
        report "fail_o1A:    " & integer'image(fail_o1A)        severity note;
        report "fail_o1B:    " & integer'image(fail_o1B)        severity note;
        report "fail_o2A:    " & integer'image(fail_o2A)        severity note;
        report "fail_o2B:    " & integer'image(fail_o2B)        severity note;

        wait;
    end process;

end sim;