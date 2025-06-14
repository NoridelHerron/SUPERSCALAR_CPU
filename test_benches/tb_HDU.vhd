------------------------------------------------------------------------------
-- Noridel Herron
-- 6/13/2025
-- Detects data hazards
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

entity tb_HDU is
--  Port ( );
end tb_HDU;

architecture sim of tb_HDU is

signal clk                      : std_logic := '0';
signal rst                      : std_logic := '1';

signal actual_in                : HDU_in           := EMPTY_HDU_in;
signal actual_res               : HDU_OUT_N        := EMPTY_HDU_OUT_N;

signal whole_ID                 : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
signal ID                       : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR;
signal ID_EX                    : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
signal EX_MEM                   : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
signal MEM_WB                   : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
signal expected_res             : HDU_OUT_N := EMPTY_HDU_OUT_N;
constant clk_period             : time := 10 ns;
    
begin
    
    UUT : entity work.HDU port map (
        H       => actual_in,    
        result  => actual_res
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
    
    variable temp_rs1A, temp_rs2A   : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := ZERO_5bits;
    variable temp_rs1B, temp_rs2B   : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := ZERO_5bits;
    
    variable total_tests    : integer          := 20000;
    variable temp_in        : HDU_in           := EMPTY_HDU_in;
    variable temp_exp       : HDU_OUT_N        := EMPTY_HDU_OUT_N;
    variable temp_ID        : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
    variable temp_ID_EX     : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
    variable temp_ID2       : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
    variable temp_IDEX      : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
    variable temp_EX_MEM    : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
    variable temp_MEM_WB    : RD_CTRL_N_INSTR  := EMPTY_RD_CTRL_N_INSTR; 
    
    -- randomized used for generating values
    variable rand1, rand2   : real;
    variable rd, rs1, rs2   : real;
    variable seed1, seed2   : positive     := 12345;
    -- Keep track test
    variable pass, fail     : integer      := 0;

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
            temp_ID.A               := get_decoded_val(rand1, rs1, rs2, rd);
            temp_ID2.A.readWrite    := get_contrl_sig  (temp_ID.A.op);
            temp_ID2.A.rd           := temp_ID.A.rd;
            
            uniform(seed1, seed2, rand2);
            uniform(seed1, seed2, rs1);
            uniform(seed1, seed2, rs2);
            uniform(seed1, seed2, rd);
            temp_ID.B               := get_decoded_val(rand2, rs1, rs2, rd);
            temp_ID2.B.readWrite    := get_contrl_sig  (temp_ID.B.op);
            temp_ID2.B.rd           := temp_ID.B.rd;

            -- input and 
            case i is
                when 1 => 
                    temp_ID_EX      := EMPTY_DECODER_N_INSTR;  
                    temp_IDEX       := EMPTY_RD_CTRL_N_INSTR; 
                    temp_EX_MEM     := EMPTY_RD_CTRL_N_INSTR; 
                    temp_MEM_WB     := EMPTY_RD_CTRL_N_INSTR; 
                    
                when 2 =>  
                    temp_ID_EX      := whole_ID; 
                    temp_IDEX       := ID;
                    temp_EX_MEM     := EMPTY_RD_CTRL_N_INSTR; 
                    temp_MEM_WB     := EMPTY_RD_CTRL_N_INSTR; 
                    
                when 3 =>  
                    temp_ID_EX      := whole_ID;   
                    temp_IDEX       := ID;
                    temp_EX_MEM     := ID_EX; 
                    temp_MEM_WB     := EMPTY_RD_CTRL_N_INSTR;  

                when others => 
                    temp_ID_EX      := whole_ID; 
                    temp_IDEX       := ID;
                    temp_EX_MEM     := ID_EX; 
                    temp_MEM_WB     := EX_MEM; 
                    
            end case;
            
            -- HDU input
            temp_in.ID      := temp_ID;
            temp_in.ID_EX   := temp_ID_EX;
            temp_in.EX_MEM  := temp_EX_MEM;
            temp_in.MEM_WB  := temp_MEM_WB;
            
            -- display result
            actual_in       <= temp_in;  -- Send the values to the unit
            expected_res    <= get_hazard_sig (temp_in);
            
            whole_ID        <= temp_ID;
            ID.A.rd         <= temp_ID2.A.rd;
            ID.A.readWrite  <= temp_ID2.A.readWrite;
            ID.B.rd         <= temp_ID2.B.rd;
            ID.B.readWrite  <= temp_ID2.B.readWrite;
            ID_EX           <= temp_IDEX;
            EX_MEM          <= temp_EX_MEM;
            MEM_WB          <= temp_MEM_WB;
             
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
