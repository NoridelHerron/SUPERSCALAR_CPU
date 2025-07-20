------------------------------------------------------------------------------
-- Noridel Herron
-- 6/8/2025
-- Verify Decoder
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


entity tb_decoder is
end tb_decoder;

architecture sim of tb_decoder is

    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '1';
    signal instruction          : std_logic_vector(DATA_WIDTH-1 downto 0) := NOP;
    signal ID_content           : Decoder_Type := EMPTY_DECODER;
    signal expected_content     : Decoder_Type := EMPTY_DECODER;
    constant clk_period         : time := 10 ns;
begin

    UUT : entity work.DECODER port map (
        ID         => instruction,    
        ID_content => ID_content
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
    variable imm12  : std_logic_vector(IMM12_WIDTH-1 downto 0) := ZERO_12bits;
    variable imm20  : std_logic_vector(IMM20_WIDTH-1 downto 0) := ZERO_20bits;
    
    variable total_tests                             : integer      := 20000;
    variable temp_instr                              : std_logic_vector(DATA_WIDTH-1 downto 0) := NOP;
    variable temp                                    : Decoder_Type := EMPTY_DECODER; 
    
    -- randomized used for generating values
    variable rand_real                               : real;
    variable seed1, seed2                            : positive     := 12345;
    -- Keep track test
    variable pass, fail, fail_op, fail_f3, fail_f7   : integer      := 0;
    variable fail_rd, fail_rs1, fail_rs2, fail_U_AU  : integer      := 0;
    variable fail_imm12, fail_imm20                  : integer      := 0;
    variable fail_R, fail_I, fail_L, fail_U_L        : integer      := 0;
    variable fail_S, fail_E, fail_B, fail_J, fail_JR : integer      := 0;
    variable R, IM, L, U_L, U_AU, S, E, B, J         : integer      := 0;
    variable JR, def_pass, def_fail                  : integer      := 0;
    
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        for i in 1 to total_tests loop
  
            -- This will cover all instructions in riscv
            uniform(seed1, seed2, rand_real);
            if rand_real < 0.02    then temp.op := ECALL;     
            elsif rand_real < 0.04 then temp.op := U_AUIPC;
            elsif rand_real < 0.06 then temp.op := U_LUI;
            elsif rand_real < 0.08 then temp.op := JALR;
            elsif rand_real < 0.1  then temp.op := LOAD;
            elsif rand_real < 0.2  then temp.op := S_TYPE;
            elsif rand_real < 0.3  then temp.op := JAL;
            elsif rand_real < 0.6  then temp.op := B_TYPE;
            elsif rand_real < 0.8  then temp.op := I_IMME;
            else temp.op := R_TYPE;
            end if;
            
            uniform(seed1, seed2, rand_real);
            temp.rd := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));

            uniform(seed1, seed2, rand_real);
            temp.rs1 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));

            uniform(seed1, seed2, rand_real);
            temp.rs2 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));

            uniform(seed1, seed2, rand_real);
            temp.funct3 := std_logic_vector(to_unsigned(integer(rand_real * 8.0), 3));

            uniform(seed1, seed2, rand_real);
            temp.funct7 := std_logic_vector(to_unsigned(integer(rand_real * 128.0), 7));
            
            temp.imm12    := ZERO_12bits;
            temp.imm20    := ZERO_20bits;

            -- Adjust fields for types
            case temp.op is
                when R_TYPE =>
                    if temp.funct3 = "000" or temp.funct3 = "101" then
                        if rand_real > 0.5 then
                            temp.funct7 := ZERO_7bits;
                        else
                            temp.funct7 := THIRTY_TWO;
                        end if;
                    end if;
                    
                when I_IMME =>    
                    if temp.funct3 = "101" then
                        if rand_real > 0.5 then
                            temp.funct7 := ZERO_7bits;
                        else
                            temp.funct7 := THIRTY_TWO;
                        end if;
                    end if; 
                    temp.imm12  := temp.funct7 & temp.rs2;
                    
                when LOAD =>    
                    temp.funct3 := "010"; -- lw for 32 bits    
                    temp.imm12  := temp.funct7 & temp.rs2;
                    
                when JALR | ECALL => 
                    temp.imm12  := temp.funct7 & temp.rs2;
                    
                when S_TYPE => 
                    temp.imm12  := temp.funct7 & temp.rd;
                
                when B_TYPE =>
                    imm12        := temp.funct7 & temp.rd; 
                    temp.imm12   := imm12(11) & imm12(0) & imm12(10 downto 5) & imm12(4 downto 1);      
                    if temp.funct3 = "010" or temp.funct3 = "011" then
                        if rand_real > 0.5 then
                            temp.funct3 := ZERO_3bits;
                        else
                            temp.funct3 := "001";
                        end if;
                    end if;  
                
                when U_LUI | U_AUIPC =>  
                    temp.imm20  := temp.funct7 & temp.rs2 & temp.rs1 & temp.funct3;   

                when JAL =>  
                    temp.imm20 := temp.funct7(6) & temp.rs1 & temp.funct3 & 
                                  temp.rs2(0) & temp.funct7(5 downto 0) & temp.rs2(4 downto 1);       
                    
                when others => temp := EMPTY_DECODER;
                    
            end case;
            
            -- Build instruction word
            temp_instr := temp.funct7 & temp.rs2 & temp.rs1 & temp.funct3 & temp.rd & temp.op;
            instruction       <= temp_instr;
   
            case temp.op is
                when R_TYPE     => 
                when I_IMME | LOAD | JALR | ECALL =>  
                    temp.funct7 := ZERO_7bits;
                    temp.rs2    := ZERO_5bits;
                when S_TYPE | B_TYPE   => 
                    temp.funct7 := ZERO_7bits;
                    temp.rd     := ZERO_5bits;   
                when JAL | U_LUI | U_AUIPC  =>  
                    temp.funct7 := ZERO_7bits;
                    temp.rs1    := ZERO_5bits; 
                    temp.rs2    := ZERO_5bits; 
                    temp.funct3 := ZERO_7bits; 
                when others => temp := EMPTY_DECODER;
            end case;

            expected_content  <= temp;

            wait until rising_edge(clk);  -- Decoder captures input
            wait for 1 ns;                -- Let ID_content settle

            -- Compare fields
            if temp.funct7 = ID_content.funct7 and temp.rs2 = ID_content.rs2 and temp.rs1 = ID_content.rs1 and 
               temp.funct3 = ID_content.funct3 and temp.rd = ID_content.rd and temp.op = ID_content.op and
               temp.imm12 = ID_content.imm12 and temp.imm20 = ID_content.imm20 then
                pass := pass + 1;
                case temp.op is
                        when R_TYPE     => R    := R + 1; 
                        when I_IMME     => IM   := IM + 1; 
                        when LOAD       => L    := L + 1; 
                        when S_TYPE     => S    := S + 1;   
                        when B_TYPE     => B    := B + 1;  
                        when JAL        => J    := J + 1;      
                        when JALR       => JR   := JR + 1;   
                        when U_LUI      => U_L  := U_L + 1; 
                        when U_AUIPC    => U_AU := U_AU + 1;
                        when ECALL      => E    := E + 1;
                        when others => def_pass := def_pass + 1;
                    end case;
            else
                fail := fail + 1;
                if temp.funct7 /= ID_content.funct7 then fail_f7    := fail_f7 + 1; end if;
                if temp.rs2    /= ID_content.rs2    then fail_rs2   := fail_rs2 + 1; end if;
                if temp.rs1    /= ID_content.rs1    then fail_rs1   := fail_rs1 + 1; end if;
                if temp.funct3 /= ID_content.funct3 then fail_f3    := fail_f3 + 1; end if;
                if temp.rd     /= ID_content.rd     then fail_rd    := fail_rd + 1; end if;
                if temp.op     /= ID_content.op     then fail_op    := fail_op + 1; end if;
                if temp.imm12  /= ID_content.imm12  then fail_imm12 := fail_imm12 + 1; end if; 
                if temp.imm20  /= ID_content.imm20  then fail_imm20 := fail_imm20 + 1; end if; 
              end if;            
 
            wait for 10 ns;
        end loop;

        -- Summary report
        report "======= TEST SUMMARY =======" severity note;
        report "Total tests: " & integer'image(total_tests)     severity note;
        report "Passed:      " & integer'image(pass)            severity note;
        report "Failed:      " & integer'image(fail)            severity note;

        -- Keep track if I cover all the possible instruction
        report "R_TYPE NUM_TEST:    " & integer'image(R)        severity note;
        report "I_IMME NUM_TEST:    " & integer'image(IM)       severity note;
        report "LOAD NUM_TEST:      " & integer'image(L)        severity note;
        report "S_TYPE NUM_TEST:    " & integer'image(S)        severity note;
        report "B_TYPE NUM_TEST:    " & integer'image(B)        severity note;
        report "JAL NUM_TEST:       " & integer'image(J)        severity note;
        report "JALR NUM_TEST:      " & integer'image(JR)       severity note;
        report "U_LUI NUM_TEST:     " & integer'image(U_L)      severity note;
        report "U_AUIPC NUM_TEST:   " & integer'image(U_AU)     severity note;
        report "ECALL NUM_TEST:     " & integer'image(E)        severity note;
        report "DEFAULT NUM_TEST:   " & integer'image(def_pass) severity note;
        
        -- Narrow down bugs
        report "OP Fails:     " & integer'image(fail_op)         severity note;
        report "RD Fails:     " & integer'image(fail_rd)         severity note;
        report "F3 Fails:     " & integer'image(fail_f3)         severity note;
        report "RS1 Fails:    " & integer'image(fail_rs1)        severity note;
        report "RS2 Fails:    " & integer'image(fail_rs2)        severity note;
        report "F7 Fails:     " & integer'image(fail_f7)         severity note; 
        report "imm12 Fails:  " & integer'image(fail_imm12)      severity note; 
        report "imm20 Fails:  " & integer'image(fail_imm20)      severity note; 
        wait;
    end process;

end sim;