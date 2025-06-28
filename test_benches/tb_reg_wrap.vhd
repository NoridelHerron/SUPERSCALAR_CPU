
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all; 
use work.MyFunctions.all;

entity tb_reg_wrap is
end tb_reg_wrap;

architecture sim of tb_reg_wrap is
    
    constant clk_period : time                := 10 ns;
    signal clk          : std_logic           := '0';
    signal rst          : std_logic           := '1';
    signal WB           : WB_CONTENT_N_INSTR  := EMPTY_WB_CONTENT_N_INSTR;
    signal WB_exp       : WB_CONTENT_N_INSTR  := EMPTY_WB_CONTENT_N_INSTR;
    signal ID           : DECODER_N_INSTR     := EMPTY_DECODER_N_INSTR;
    signal ID_exp       : DECODER_N_INSTR     := EMPTY_DECODER_N_INSTR;
    signal reg_data     : REG_DATAS           := EMPTY_REG_DATAS;
    signal reg_exp      : REG_DATAS           := EMPTY_REG_DATAS;
     
    
    type regfile_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal exp_reg : regfile_array := (others => (others => '0'));
 
begin
    UUT: entity work.RegFile_wrapper 
        port map ( clk      => clk,
                   WB       => WB,
                   ID       => ID,
                   reg_data => reg_data
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
        -- For generated value
        variable rand_real      : real;
        variable seed1          : positive := 42;
        variable seed2          : positive := 24;
        variable rand_A, rand_B            : integer;
        variable rand_f3        : integer;
        
        -- Expected result
        variable WB_temp  : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;
        variable ID_temp  : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
        variable reg_temp : REG_DATAS          := EMPTY_REG_DATAS;
        variable exp_rD : regfile_array := (others => (others => '0'));
        
        -- Number of tests
        variable total_tests : integer := 20000;
        
        -- Keep track of the tests
        variable pass, fail, fail_A1, fail_A2, fail_B1, fail_B2 : integer := 0;  
        variable fail_rA1, fail_rA2, fail_rB1, fail_rB2 : integer := 0;  
    begin 
    
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        for i in 1 to total_tests loop
 
            -- Generate inputs
            uniform(seed1, seed2, rand_real);
            WB_temp.A.data := get_32bits_val(rand_real);
            WB_temp.A.rd   := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
            if rand_real < 0.5 then
                WB_temp.A.we := REG_WRITE;
            else
                WB_temp.A.we := NONE_c;
            end if;
            
            uniform(seed1, seed2, rand_real);
            WB_temp.B.data := get_32bits_val(rand_real);
            WB_temp.B.rd   := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
            if rand_real < 0.5 then
                WB_temp.B.we := REG_WRITE;
            else
                WB_temp.B.we := NONE_c;
            end if;
            
            uniform(seed1, seed2, rand_real); ID_temp.A.rs1 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
            uniform(seed1, seed2, rand_real); ID_temp.A.rs2 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
            uniform(seed1, seed2, rand_real); ID_temp.B.rs1 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
            uniform(seed1, seed2, rand_real); ID_temp.B.rs2 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
            
            -- Check if read or write in the register
            if ((WB_temp.A.we = REG_WRITE) and (WB_temp.A.rd /= ZERO_5bits)) then
                exp_rD(to_integer(unsigned(WB_temp.A.rd))) := WB_temp.A.data;
            end if;
            
            if (WB_temp.B.we = REG_WRITE) and (WB_temp.B.rd /= ZERO_5bits) and 
               not ((WB_temp.A.we = REG_WRITE) and (WB_temp.A.rd = WB_temp.B.rd)) then
                exp_rD(to_integer(unsigned(WB_temp.B.rd))) := WB_temp.B.data;
            end if;
            
            reg_temp.one.A := exp_reg(to_integer(unsigned(ID_temp.A.rs1)));
            reg_temp.one.B := exp_reg(to_integer(unsigned(ID_temp.A.rs2)));
            reg_temp.two.A := exp_reg(to_integer(unsigned(ID_temp.B.rs1)));
            reg_temp.two.B := exp_reg(to_integer(unsigned(ID_temp.B.rs2)));
            
            -- Value assignment for the unit
            ID      <= ID_temp;
            ID_exp  <= ID_temp;
            WB      <= WB_temp;
            WB_exp  <= WB_temp;
            reg_exp <= reg_temp;
            exp_reg <= exp_rD;
            
            wait until rising_edge(clk);
            
            -- Keep track the number of pass or fail
            if ID = ID_exp and WB = WB_exp and reg_data = reg_exp then
                pass := pass + 1;
            else
                fail := fail + 1; 
                -- Narrow down bugs
                if ID.A.rs1 /= ID_exp.A.rs1 then
                    fail_A1 := fail_A1 + 1;
                end if;
                if ID.A.rs2 /= ID_exp.A.rs2 then
                    fail_A2 := fail_A2 + 1;
                end if;
                if ID.B.rs1 /= ID_exp.B.rs1 then
                    fail_B1 := fail_B1 + 1;
                end if;
                if ID.B.rs2 /= ID_exp.B.rs2 then
                    fail_B1 := fail_B1 + 1;
                end if;
                
                if reg_data.one.A /= reg_exp.one.A then
                    fail_rA1 := fail_rA1 + 1;
                end if;
                if reg_data.one.B /= reg_exp.one.B then
                    fail_rA2 := fail_rA2 + 1;
                end if;
                if reg_data.two.A /= reg_exp.two.A then
                    fail_rB1 := fail_rB1 + 1;
                end if;
                if reg_data.two.B /= reg_exp.two.B then
                    fail_rB2 := fail_rB2 + 1;
                end if;
            end if;

        end loop;
        
        -- Summary report
        report "----------------------------------------------------";
        report "ALU Randomized Test Summary:";
        report "Total Tests      : " & integer'image(total_tests);
        report "Total Passes     : " & integer'image(pass);
        report "Total Failures   : " & integer'image(fail);
        report "A rs1 Failures   : " & integer'image(fail_A1);
        report "A rs2 Failures   : " & integer'image(fail_A2);
        report "B rs1 Failures   : " & integer'image(fail_B1);
        report "B rs2 Failures   : " & integer'image(fail_B2);
        report "reg1A Failures   : " & integer'image(fail_rA1);
        report "reg1B Failures   : " & integer'image(fail_rA2);
        report "reg2A Failures   : " & integer'image(fail_rB1);
        report "reg2B Failures   : " & integer'image(fail_rB2);
        report "----------------------------------------------------";

        wait;
    end process;
end sim;