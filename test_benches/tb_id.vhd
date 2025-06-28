
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
use work.instruction_generator.all;
use work.decoder_function.all;

entity tb_id_stage is
end tb_id_stage;

architecture sim of tb_id_stage is
    
    constant clk_period : time                := 10 ns;
    signal clk          : std_logic           := '0';
    signal rst          : std_logic           := '1';
    
    signal instr1       : std_logic_vector(DATA_WIDTH-1 downto 0)   := ZERO_32bits;      
    signal instr2       : std_logic_vector(DATA_WIDTH-1 downto 0)   := ZERO_32bits;
    signal ID           : DECODER_N_INSTR                           := EMPTY_DECODER_N_INSTR; 
    signal ID_exp       : DECODER_N_INSTR                           := EMPTY_DECODER_N_INSTR; 
    signal ID_EX        : DECODER_N_INSTR                           := EMPTY_DECODER_N_INSTR; 
    signal ID_EX_exp    : DECODER_N_INSTR                           := EMPTY_DECODER_N_INSTR; 
    signal cntrl        : control_Type_N                            := EMPTY_control_Type_N; 
    signal cntrl_exp    : control_Type_N                            := EMPTY_control_Type_N; 
    signal ID_EX_c      : control_Type_N                            := EMPTY_control_Type_N; 
    signal ID_EX_c_exp  : control_Type_N                            := EMPTY_control_Type_N; 
    signal EX_MEM       : RD_CTRL_N_INSTR                           := EMPTY_RD_CTRL_N_INSTR;    
    signal EX_MEM_exp   : RD_CTRL_N_INSTR                           := EMPTY_RD_CTRL_N_INSTR;    
    signal MEM_WB       : RD_CTRL_N_INSTR                           := EMPTY_RD_CTRL_N_INSTR; 
    signal MEM_WB_exp   : RD_CTRL_N_INSTR                           := EMPTY_RD_CTRL_N_INSTR; 
    signal WB           : WB_CONTENT_N_INSTR                        := EMPTY_WB_CONTENT_N_INSTR; 
    signal WB_exp       : WB_CONTENT_N_INSTR                        := EMPTY_WB_CONTENT_N_INSTR; 
    signal haz          : HDU_OUT_N                                 := EMPTY_HDU_OUT_N;      
    signal haz_exp      : HDU_OUT_N                                 := EMPTY_HDU_OUT_N;      
    signal datas        : REG_DATAS                                 := EMPTY_REG_DATAS;   
    signal datas_exp    : REG_DATAS                                 := EMPTY_REG_DATAS; 
    
    type regfile_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal exp_reg : regfile_array := (others => (others => '0'));       

begin
    UUT: entity work.ID_STAGE 
        port map ( clk      => clk,
                   instr1   => instr1,
                   instr2   => instr2,
                   ID_EX    => ID_EX,
                   ID_EX_c  => ID_EX_c,
                   EX_MEM   => EX_MEM,
                   MEM_WB   => MEM_WB,
                   WB       => WB,
                   ID       => ID,
                   cntrl    => cntrl,
                   haz      => haz,
                   datas    => datas
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
        variable rand_A, rand_B           : integer;
        variable rand_real, rs1, rs2, rd  : real;
        variable seed1                    : positive := 42;
        variable seed2                    : positive := 24;
        
        variable instr1_t  : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;       
        variable instr2_t  : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;     
        variable ID_EX_t   : DECODER_N_INSTR                         := EMPTY_DECODER_N_INSTR; 
        variable ID_EX_c_t : control_Type_N                          := EMPTY_control_Type_N; 
        variable EX_MEM_t  : RD_CTRL_N_INSTR                         := EMPTY_RD_CTRL_N_INSTR;   
        variable MEM_WB_t  : RD_CTRL_N_INSTR                         := EMPTY_RD_CTRL_N_INSTR; 
        variable WB_t      : WB_CONTENT_N_INSTR                      := EMPTY_WB_CONTENT_N_INSTR; 
        variable ID_t      : DECODER_N_INSTR                         := EMPTY_DECODER_N_INSTR; 
        variable cntrl_t   : control_Type_N                          := EMPTY_control_Type_N; 
        variable haz_t     : HDU_OUT_N                               := EMPTY_HDU_OUT_N;      
        variable reg_temp  : REG_DATAS                               := EMPTY_REG_DATAS;
       -- variable exp_rD    : regfile_array                           := (others => (others => '0'));
        
        -- Number of tests
        variable total_tests : integer := 20000;
        
        -- Keep track of the tests
        variable pass, fail, fid, fidex, fc, ficx, fe, fm, fh, fw, fd : integer := 0;  
        variable fail_A1, fail_A2, fail_B1, fail_B2 : integer := 0;  
        variable fail_rA1, fail_rA2, fail_rB1, fail_rB2 : integer := 0;  
        
    begin 
    
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        
        for i in 1 to total_tests loop
 
            -- Generate instructions
            uniform(seed1, seed2, rand_real); instr1_t := instr_gen(rand_real);
            uniform(seed1, seed2, rand_real); instr2_t := instr_gen(rand_real);
            
            -- ACTUAL ASSIGNMENT
            instr1          <= instr1_t;
            instr2          <= instr2_t;
            ID_EX           <= ID;
            ID_EX_c         <= cntrl;
            EX_MEM.A.cntrl  <= ID_EX_c.A;
            EX_MEM.A.rd     <= ID_EX.A.rd;
            EX_MEM.B.cntrl  <= ID_EX_c.B;
            EX_MEM.B.rd     <= ID_EX.B.rd;
            MEM_WB          <= EX_MEM;
            WB.A.data       <= WB_t.A.data;
            WB.A.rd         <= EX_MEM.A.rd;
            WB.A.we         <= EX_MEM.A.cntrl.wb;
            WB.B.data       <= WB_t.B.data;
            WB.B.rd         <= EX_MEM.B.rd;
            WB.B.we         <= EX_MEM.B.cntrl.wb;
            
            -- Generate 32-bits value for the wb
            uniform(seed1, seed2, rand_real); WB_t.A.data := get_32bits_val(rand_real);
            uniform(seed1, seed2, rand_real); WB_t.B.data := get_32bits_val(rand_real);
            
            -- Decode instruction
            ID_t.A := decode(instr1_t);
            ID_t.B := decode(instr2_t);
            
            -- get control signal
            cntrl_t.A := Get_Control(ID_t.A.op);
            cntrl_t.B := Get_Control(ID_t.B.op);
            
            -- EXPECTED ASSIGNMENT
            ID_exp              <= ID_t;
            cntrl_exp           <= cntrl_t;
            ID_EX_exp           <= ID_exp;
            ID_EX_c_exp         <= cntrl_exp;
            EX_MEM_exp.A.cntrl  <= ID_EX_c_exp.A;
            EX_MEM_exp.A.rd     <= ID_EX_exp.A.rd;
            EX_MEM_exp.B.cntrl  <= ID_EX_c_exp.B;
            EX_MEM_exp.B.rd     <= ID_EX_exp.B.rd;
            MEM_WB_exp          <= EX_MEM_exp;
            WB_exp.A.data       <= WB_t.A.data;
            WB_exp.A.rd         <= EX_MEM_exp.A.rd;
            WB_exp.A.we         <= EX_MEM_exp.A.cntrl.wb;
            WB_exp.B.data       <= WB_t.B.data;
            WB_exp.B.rd         <= EX_MEM_exp.B.rd;
            WB_exp.B.we         <= EX_MEM_exp.B.cntrl.wb;
            
            -- Generate Hazard
            haz_t := get_hazard_sig  (ID_t, ID_EX_exp, ID_EX_c_exp, EX_MEM_exp, MEM_WB_exp );
            -- Check if read or write in the register
            if ((WB_exp.A.we = REG_WRITE) and (WB_exp.A.rd /= ZERO_5bits)) then
                exp_reg(to_integer(unsigned(WB_exp.A.rd))) <= WB_exp.A.data;
            end if;
            
            if (WB_exp.B.we = REG_WRITE) and (WB_exp.B.rd /= ZERO_5bits) and 
               not ((WB_exp.A.we = REG_WRITE) and (WB_exp.A.rd = WB_exp.B.rd)) then
                exp_reg(to_integer(unsigned(WB_exp.B.rd))) <= WB_exp.B.data;
            end if;
            
            reg_temp.one.A := exp_reg(to_integer(unsigned(ID_t.A.rs1)));
            reg_temp.one.B := exp_reg(to_integer(unsigned(ID_t.A.rs2)));
            reg_temp.two.A := exp_reg(to_integer(unsigned(ID_t.B.rs1)));
            reg_temp.two.B := exp_reg(to_integer(unsigned(ID_t.B.rs2)));
            
            datas_exp           <= reg_temp;
     --       exp_reg             <= exp_rD;

            wait until rising_edge(clk);
            
            -- Keep track the number of pass or fail
            if ID = ID_exp and ID_EX = ID_EX_exp and cntrl = cntrl_exp and
            ID_EX_c = ID_EX_c_exp and EX_MEM = EX_MEM_exp and MEM_WB = MEM_WB_exp
            and haz = haz_exp and datas = datas_exp and WB = WB_exp then
                pass := pass + 1;
            else
                fail := fail + 1; 
                if ID /= ID_exp           then fid   := fid + 1;   end if;
                if ID_EX /= ID_EX_exp     then fidex := fidex + 1; end if;
                if cntrl /= cntrl_exp     then fc    := fc + 1;    end if;
                if ID_EX_c /= ID_EX_c_exp then ficx  := ficx + 1;  end if;
                if EX_MEM /= EX_MEM_exp   then fe    := fe + 1;    end if;
                if MEM_WB /= MEM_WB_exp   then fm    := fm + 1;    end if;
                if haz /= haz_exp         then fh    := fh + 1;    end if;
                if datas /= datas_exp     then fd    := fd + 1;    end if;
                if WB /= WB_exp           then fw    := fw + 1;    end if;
            end if;

        end loop;
        
        -- Summary report
        report "----------------------------------------------------";
        report "ALU Randomized Test Summary:";
        report "Total Tests      : " & integer'image(total_tests);
        report "Total Passes     : " & integer'image(pass);
        report "Total Failures   : " & integer'image(fail);
        report "----------------------------------------------------";
        report "ID Failures      : " & integer'image(fid);
        report "ID_EX Failures   : " & integer'image(fidex);
        report "CNTRL Failures   : " & integer'image(fc);
        report "ID_EX_c Failures : " & integer'image(ficx);
        report "EX_MEM Failures  : " & integer'image(fe);
        report "MEM_WB Failures  : " & integer'image(fm);
        report "HAZ Failures     : " & integer'image(fh);
        report "DATAS Failures   : " & integer'image(fd);
        report "WB Failures      : " & integer'image(fw);
      --  report "A rs1 Failures   : " & integer'image(fail_A1);
     --   report "A rs2 Failures   : " & integer'image(fail_A2);
     --   report "B rs1 Failures   : " & integer'image(fail_B1);
     --   report "B rs2 Failures   : " & integer'image(fail_B2);
     --   report "reg1A Failures   : " & integer'image(fail_rA1);
     --   report "reg1B Failures   : " & integer'image(fail_rA2);
      --  report "reg2A Failures   : " & integer'image(fail_rB1);
      --  report "reg2B Failures   : " & integer'image(fail_rB2);
        report "----------------------------------------------------";

        wait;
    end process;
end sim;