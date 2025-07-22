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

signal clk           : std_logic := '0';
signal rst           : std_logic := '1';

signal ID            : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
signal ID_EX         : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
signal ID_EX_c       : control_Type_N   := EMPTY_control_Type_N;
signal EX_MEM        : EX_CONTENT_N     := EMPTY_EX_CONTENT_N; 
signal MEM_WB        : MEM_CONTENT_N    := EMPTY_MEM_CONTENT_N; 
signal actual_res    : HDU_OUT_N        := EMPTY_HDU_OUT_N;
signal expected_res  : HDU_OUT_N        := EMPTY_HDU_OUT_N;
constant clk_period  : time := 10 ns;
    
begin
    
    UUT : entity work.HDU port map (
        ID      => ID, 
        ID_EX   => ID_EX,
        ID_EX_c => ID_EX_c, 
        EX_MEM  => EX_MEM,
        MEM_WB  => MEM_WB,
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

    variable total_tests    : integer          := 20000;
    variable temp_exp       : HDU_OUT_N        := EMPTY_HDU_OUT_N;
    variable temp_ID        : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
    variable temp_ID_EX     : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR; 
    variable temp_ID_EX_c   : control_Type_N   := EMPTY_control_Type_N;
    variable temp_EX_MEM    : EX_CONTENT_N     := EMPTY_EX_CONTENT_N; 
    variable temp_MEM_WB    : MEM_CONTENT_N    := EMPTY_MEM_CONTENT_N; 
    variable temp_HDU_cntrl : control_Type_N   := EMPTY_control_Type_N;
    
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
            temp_ID.A      := get_decoded_val(rand1, rs1, rs2, rd);
            temp_ID_EX_c.A := Get_Control (temp_ID.A.op);
            
            
            uniform(seed1, seed2, rand2);
            uniform(seed1, seed2, rs1);
            uniform(seed1, seed2, rs2);
            uniform(seed1, seed2, rd);
            temp_ID.B      := get_decoded_val(rand2, rs1, rs2, rd);
            temp_ID_EX_c.B := Get_Control (temp_ID.B.op);

            -- input and 
            case i is
                when 1 => 
                    temp_ID_EX      := EMPTY_DECODER_N_INSTR;  
                    temp_EX_MEM     := EMPTY_EX_CONTENT_N; 
                    temp_MEM_WB     := EMPTY_MEM_CONTENT_N; 
                    
                when 2 =>  
                    temp_ID_EX      := ID; 
                    temp_EX_MEM     := EMPTY_EX_CONTENT_N; 
                    temp_MEM_WB     := EMPTY_MEM_CONTENT_N; 
                    
                when 3 =>  
                    temp_ID_EX          := ID;
                    temp_EX_MEM.A.cntrl := ID_EX_c.A; 
                    temp_EX_MEM.A.rd    := ID_EX.A.rd; 
                    temp_EX_MEM.B.cntrl := ID_EX_c.B; 
                    temp_EX_MEM.B.rd    := ID_EX.B.rd; 
                    temp_MEM_WB         := EMPTY_MEM_CONTENT_N;  

                when others => 
                    temp_ID_EX          := ID; 
                    temp_EX_MEM.A.cntrl := ID_EX_c.A; 
                    temp_EX_MEM.A.rd    := ID_EX.A.rd; 
                    temp_EX_MEM.B.cntrl := ID_EX_c.B; 
                    temp_EX_MEM.B.rd    := ID_EX.B.rd; 
                    temp_MEM_WB.A.rd    := EX_MEM.A.rd; 
                    temp_MEM_WB.A.we    := EX_MEM.B.cntrl.wb; 
                    temp_MEM_WB.A.me    := EX_MEM.B.cntrl.mem; 
                    
            end case;
          
            ID_EX_c         <= temp_ID_EX_c;
            expected_res    <= get_hazard_sig (temp_ID, temp_ID_EX, temp_ID_EX_c, temp_EX_MEM, temp_MEM_WB);
            ID              <= temp_ID;
            ID_EX           <= temp_ID_EX;
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