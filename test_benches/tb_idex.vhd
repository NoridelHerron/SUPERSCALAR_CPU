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
use work.decoder_function.all;
use work.MyFunctions.all;

entity tb_idex is
--  Port ( );
end tb_idex;

architecture sim of tb_idex is

constant clk_period     : time              := 10 ns;
signal clk              : std_logic         := '0';
signal rst              : std_logic         := '1';
signal id               : Inst_PC_N         := init_Inst_PC_N;
signal id_exp           : Inst_PC_N         := init_Inst_PC_N;
signal id_content       : DECODER_N_INSTR   := EMPTY_DECODER_N_INSTR; 
signal id_content_exp   : DECODER_N_INSTR   := EMPTY_DECODER_N_INSTR; 
signal id_control       : control_Type_N    := EMPTY_control_Type_N; 
signal id_control_exp   : control_Type_N    := EMPTY_control_Type_N; 
signal haz              : HDU_OUT_N         := EMPTY_HDU_OUT_N;
signal haz_exp          : HDU_OUT_N         := EMPTY_HDU_OUT_N;
signal data_in          : REG_DATAS         := EMPTY_REG_DATAS; 
signal data_in_exp      : REG_DATAS         := EMPTY_REG_DATAS; 
signal id_ex            : Inst_PC_N         := EMPTY_Inst_PC_N; 
signal id_ex_exp        : Inst_PC_N         := EMPTY_Inst_PC_N; 
signal idex_content     : DECODER_N_INSTR   := EMPTY_DECODER_N_INSTR; 
signal idex_content_exp : DECODER_N_INSTR   := EMPTY_DECODER_N_INSTR; 
signal idex_control     : control_Type_N    := EMPTY_control_Type_N; 
signal idex_control_exp : control_Type_N    := EMPTY_control_Type_N; 
signal haz_out          : HDU_OUT_N         := EMPTY_HDU_OUT_N;
signal haz_out_exp      : HDU_OUT_N         := EMPTY_HDU_OUT_N;
signal data_out         : REG_DATAS         := EMPTY_REG_DATAS; 
signal data_out_exp     : REG_DATAS         := EMPTY_REG_DATAS; 

begin
    UUT : entity work.ID_EX port map (
        clk         => clk,
        reset       => rst,
        id_stage    => id,
        id          => id_content, 
        id_c        => id_control,
        haz_in      => haz,
        datas_in    => data_in,
        id_ex_stage => id_ex,
        id_ex       => idex_content,
        id_ex_c     => idex_control,
        haz_out     => haz_out,
        datas_out   => data_out
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
    variable id_content_v : DECODER_N_INSTR := EMPTY_DECODER_N_INSTR; 
    variable id_control_v : control_Type_N  := EMPTY_control_Type_N; 
    variable haz_v        : HDU_OUT_N       := EMPTY_HDU_OUT_N;
    variable data_in_v    : REG_DATAS       := EMPTY_REG_DATAS; 
    
    variable total_tests   : integer            := 20000;
    -- Keep track test
    variable pass, fail     : integer   := 0;
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period * 2;
        
        for i in 1 to total_tests loop
            -- Generate instructions
            uniform(seed1, seed2, rand);
            actual.A.instr := instr_gen(rand);
            uniform(seed1, seed2, rand2);
            actual.B.instr := instr_gen(rand2);
            
            -- Increment pc
            actual.A.pc       := std_logic_vector(unsigned(id.A.pc) + 8); 
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
            
            -- decode instructions
            id_content_v.A := decode(actual.A.instr);
            id_content_v.B := decode(actual.B.instr);
            
            -- get control signals
            id_control_v.A := Get_Control(id_content_v.A.op);
            id_control_v.B := Get_Control(id_content_v.B.op);
            
            -- Generate hazards
            if rand < 0.2 then
                haz_v.A.forwA := EX_MEM_A;
                haz_v.A.forwB := MEM_WB_A;
            elsif rand < 0.4 then
                haz_v.A.forwA := EX_MEM_B;
                haz_v.A.forwB := NONE_h;
            elsif rand < 0.6 then
                haz_v.A.forwA := MEM_WB_A;
                haz_v.A.forwB := EX_MEM_A;
            elsif rand < 0.7 then
                haz_v.A.forwA := MEM_WB_B;
                haz_v.A.forwB := NONE_h;
            else
                haz_v.A.forwA := NONE_h;
                haz_v.A.forwB := MEM_WB_B;
            end if;
            
            if rand < 0.1 then
                haz_v.A.stall := A_STALL;
            elsif rand < 0.15 then
                haz_v.A.stall := B_STALL;
            else
                haz_v.A.stall := NONE_h;
            end if; 
            
            if rand2 < 0.2 then
                haz_v.B.forwA := EX_MEM_A;
                haz_v.B.forwB := MEM_WB_A;
            elsif rand2 < 0.4 then
                haz_v.B.forwA := EX_MEM_B;
                haz_v.B.forwB := NONE_h;
            elsif rand2 < 0.6 then
                haz_v.B.forwA := MEM_WB_A;
                haz_v.B.forwB := EX_MEM_A;
            elsif rand2 < 0.7 then
                haz_v.B.forwA := MEM_WB_B;
                haz_v.B.forwB := NONE_h;
            else
                haz_v.B.forwA := NONE_h;
                haz_v.B.forwB := MEM_WB_B;
            end if;
            
            if rand2 < 0.1 then
                haz_v.B.stall := A_STALL;
            elsif rand2 < 0.15 then
                haz_v.B.stall := B_STALL;
            else
                haz_v.B.stall := NONE_h;
            end if; 
            
            -- generate data
            data_in_v.one.A := get_32bits_val(rand);
            data_in_v.one.B := get_32bits_val(rand2);
            uniform(seed1, seed2, rand);
            uniform(seed1, seed2, rand2);
            data_in_v.two.A := get_32bits_val(rand);
            data_in_v.two.B := get_32bits_val(rand2);
            
            -- actual inputs assignment
            id          <= actual;
            id_content  <= id_content_v;
            id_control  <= id_control_v;
            haz         <= haz_v;
            data_in     <= data_in_v;
            
            -- expected inputs assignment
            id_exp          <= actual;
            id_content_exp  <= id_content_v;
            id_control_exp  <= id_control_v;
            haz_exp         <= haz_v;
            data_in_exp     <= data_in_v;
     
            -- EXPECTED output assignments
            if rst = '1' then
                id_ex_exp           <= EMPTY_Inst_PC_N;
                idex_content_exp    <= EMPTY_DECODER_N_INSTR;
                idex_control_exp    <= EMPTY_control_Type_N;
                haz_out_exp         <= EMPTY_HDU_OUT_N;
                data_out_exp        <= EMPTY_REG_DATAS;

            elsif id_exp.A.is_valid = VALID then
                id_ex_exp.A         <= id_exp.A;
                idex_content_exp.A  <= id_content_exp.A;
                idex_control_exp.A  <= id_control_exp.A;
                haz_out_exp.A       <= haz_exp.A;
                data_out_exp.one    <= data_in_exp.one;
                
                if id_exp.B.is_valid = VALID then
                    id_ex_exp.B         <= id_exp.B;
                    idex_content_exp.B  <= id_content_exp.B;
                    idex_control_exp.B  <= id_control_exp.B;
                    haz_out_exp.B       <= haz_exp.B;
                    data_out_exp.two    <= data_in_exp.two;
                end if;
            end if;
            
            -- Let the result settle down
            wait until rising_edge(clk);
            
            -- Keep track the test
            if id = id_exp and id_content = id_content_exp and id_control = id_control_exp and
               haz = haz_exp and data_in = data_in_exp and id_ex = id_ex_exp and 
               idex_content = idex_content_exp and idex_control = idex_control_exp and 
               haz_out = haz_out_exp and data_out = data_out_exp then
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
