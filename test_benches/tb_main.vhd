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
use work.decoder_function.all;

entity tb_main is
--  Port ( );
end tb_main;

architecture sim of tb_main is

constant clk_period     : time              := 10 ns;
signal clk              : std_logic         := '0';
signal rst              : std_logic         := '1';

signal if_ipcv          : Inst_PC_N          := EMPTY_Inst_PC_N;

signal id_ipcv          : Inst_PC_N          := EMPTY_Inst_PC_N;
signal id_ipcv_exp      : Inst_PC_N          := EMPTY_Inst_PC_N;
signal id_value         : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal id_value_exp     : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal id_cntrl         : control_Type_N     := EMPTY_control_Type_N;
signal id_cntrl_exp     : control_Type_N     := EMPTY_control_Type_N;
signal id_haz           : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal id_haz_exp       : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal id_datas         : REG_DATAS          := EMPTY_REG_DATAS;
signal id_datas_exp     : REG_DATAS          := EMPTY_REG_DATAS;

signal ex_ipcv        : Inst_PC_N          := EMPTY_Inst_PC_N;
signal ex_ipcv_exp    : Inst_PC_N          := EMPTY_Inst_PC_N;
signal idex_value       : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal idex_value_exp   : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal idex_cntrl       : control_Type_N     := EMPTY_control_Type_N;
signal idex_cntrl_exp   : control_Type_N     := EMPTY_control_Type_N;
signal id_ex_haz        : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal id_ex_haz_exp    : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal idex_datas       : REG_DATAS          := EMPTY_REG_DATAS;
signal idex_datas_exp   : REG_DATAS          := EMPTY_REG_DATAS;
signal Forw_exp         : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal ex_value         : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal ex_value_exp     : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;

signal mem_ipcv       : Inst_PC_N          := EMPTY_Inst_PC_N;
signal mem_ipcv_exp   : Inst_PC_N          := EMPTY_Inst_PC_N;
signal exmem_value      : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal exmem_value_exp  : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
signal exmem_cntrl      : control_Type_N     := EMPTY_control_Type_N;
signal exmem_cntrl_exp  : control_Type_N     := EMPTY_control_Type_N;
signal ex_mem_rc        : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR;
signal ex_mem_rc_exp    : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR;
signal mem_value        : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;
signal mem_value_exp    : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;

signal wb_ipcv       : Inst_PC_N          := EMPTY_Inst_PC_N;
signal wb_ipcv_exp   : Inst_PC_N          := EMPTY_Inst_PC_N;
signal memwb_value      : MEM_CONTENT_N      := EMPTY_MEM_CONTENT_N;
signal memwb_value_exp  : MEM_CONTENT_N      := EMPTY_MEM_CONTENT_N;
signal mem_wb_rc        : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR;

signal wb_value         : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;
signal wb_value_exp     : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;

type regfile_array is array (0 to 31) of std_logic_vector(31 downto 0);
type memory_array is array (0 to 1023) of std_logic_vector(DATA_WIDTH-1 downto 0); 
signal exp_reg  : regfile_array := (others => (others => '0'));

signal exp_mem  : memory_array  := (others => (others => '0')); 
begin
     UUT : entity work.main port map (
        clk         => clk,
        reset       => rst,
        if_ipcv     => if_ipcv,
        id_ipcv     => id_ipcv,
        id_value    => id_value,
        id_cntrl    => id_cntrl,
        id_haz      => id_haz,  
        id_datas    => id_datas,
        idex_ipcv   => ex_ipcv,
        idex_value  => idex_value,
        idex_cntrl  => idex_cntrl,
        idex_datas  => idex_datas,
        ex_value    => ex_value,
        exmem_ipcv  => mem_ipcv,
        exmem_value => exmem_value,
        exmem_cntrl => exmem_cntrl,
        mem_value   => mem_value,
        memwb_ipcv  => wb_ipcv,
        memwb_value => memwb_value,
        wb_value    => wb_value 
    );

    -- Clock generation only
    clk_process : process
    begin -- 2000000
        while now < 5000 ns loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;
    
    process
    -- randomized used for generating values
    variable rand, rand2   : real;
    variable seed1, seed2  : positive           := 12345;
    variable id_value_v    : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
    variable id_cntrl_v    : control_Type_N     := EMPTY_control_Type_N;
    variable id_haz_v      : HDU_OUT_N          := EMPTY_HDU_OUT_N;      
    variable id_datas_v    : REG_DATAS          := EMPTY_REG_DATAS;
    variable idex_value_v  : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
    variable idex_cntrl_v  : control_Type_N     := EMPTY_control_Type_N;  
    variable idex_datas_v  : REG_DATAS          := EMPTY_REG_DATAS;
    variable Forw_v        : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
    variable ex_operand_v  : EX_OPERAND_N       := EMPTY_EX_OPERAND_N;
    variable ex_value_v    : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
    variable exmem_value_v : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;
    variable exmem_cntrl_v : control_Type_N     := EMPTY_control_Type_N; 
    variable ex_mem_rc_v   : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR; 
    variable mem_value_v   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); 
    variable memwb_value_v : MEM_CONTENT_N      := EMPTY_MEM_CONTENT_N;
    variable mem_wb_rc_v   : RD_CTRL_N_INSTR    := EMPTY_RD_CTRL_N_INSTR; 
    variable wb_value_v    : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR; 
    
    variable alu_in1  : ALU_in  := EMPTY_ALU_in;
    variable alu_out1 : ALU_out := EMPTY_ALU_out;  
    variable alu_in2  : ALU_in  := EMPTY_ALU_in;
    variable alu_out2 : ALU_out := EMPTY_ALU_out;  

    variable total_tests   : integer            := 5;
    -- Keep track test
    variable pass, fail    : integer   := 0;
    -- Narrow down bugs
    variable f_e, f_ec, f_ctrl, f_mA, f_mB, f_m, f_mc : integer   := 0;
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period * 2;
        
        for i in 1 to total_tests loop  
      
            id_value_v.A        := decode(if_ipcv.A.instr);
            id_value_v.B        := decode(if_ipcv.B.instr);
            id_cntrl_v.A        := Get_Control(if_ipcv.A.instr(6 downto 0));
            id_cntrl_v.B        := Get_Control(if_ipcv.B.instr(6 downto 0));
            id_datas_v.one.A    := exp_reg(to_integer(unsigned(id_value_v.A.rs1)));
            id_datas_v.one.B    := exp_reg(to_integer(unsigned(id_value_v.A.rs2)));
            id_datas_v.two.A    := exp_reg(to_integer(unsigned(id_value_v.B.rs1)));
            id_datas_v.two.B    := exp_reg(to_integer(unsigned(id_value_v.B.rs2)));
            
            ex_mem_rc_v.A.cntrl := idex_cntrl_exp.A;
            ex_mem_rc_v.A.rd    := idex_value_exp.A.rd;
            ex_mem_rc_v.B.cntrl := idex_cntrl_exp.B;
            ex_mem_rc_v.B.rd    := idex_value_exp.B.rd; 
            mem_wb_rc_v         := ex_mem_rc_exp;
            
            id_haz_v            := get_hazard_sig (id_value_v, id_value_exp, id_cntrl_exp, ex_mem_rc_v, mem_wb_rc_v); 
            
            idex_value_v        := id_value_exp;
            idex_cntrl_v        := id_cntrl_exp;
            idex_datas_v        := id_datas_exp;
            Forw_v              := Forw_exp; 
            ex_operand_v        := get_operands ( exmem_value_v, wb_value_v, idex_value_v, idex_datas_v, Forw_v); 
            
            alu_in1             := get_alu1_input ( idex_value_v, ex_operand_v);
  
            ex_value_v.A.alu    := get_alu_res ( alu_in1.f3, alu_in1.f7, alu_in1.A, alu_in1.B);    
            ex_value_v.A.operand := ex_operand_v.one; 
            ex_value_v.A.S_data := ex_operand_v.S_data1; 
            ex_value_v.A.rd     := idex_value_v.A.rd; 
             
            alu_in2             := get_alu2_input ( ex_operand_v, Forw_v, idex_value_v, ex_value_v.A.alu );
            ex_value_v.B.alu    := get_alu_res ( alu_in2.f3, alu_in2.f7, alu_in2.A, alu_in2.B); 
            ex_value_v.B.operand := ex_operand_v.two; 
            ex_value_v.B.S_data := ex_operand_v.S_data2; 
            ex_value_v.B.rd     := idex_value_v.B.rd; 
            
            exmem_value_v       := ex_value_exp;
            
            exmem_cntrl_v       := idex_cntrl_exp; 
            ex_mem_rc_v.A.cntrl := exmem_cntrl_v.A ;
            ex_mem_rc_v.A.rd    := exmem_value_v.A.rd ;
            ex_mem_rc_v.B.cntrl := exmem_cntrl_v.B;
            ex_mem_rc_v.B.rd    := exmem_value_v.B.rd;
            
               
 
            if rising_edge (clk) then
                if ex_mem_rc_v.A.cntrl.mem = MEM_write then
                    exp_mem(TO_INTEGER(UNSIGNED(exmem_value_v.A.alu.result(11 downto 2)))) <= exmem_value_v.A.S_data;
                end if; 
            end if; 
            
            if ex_mem_rc_v.A.cntrl.mem = MEM_READ then
                mem_value_v := exp_mem(TO_INTEGER(UNSIGNED(exmem_value_v.A.alu.result(11 downto 2))));
            else
                mem_value_v := (others => '0');
            end if;   
            
            memwb_value_v.A.alu := exmem_value_v.A.alu.result;
            memwb_value_v.A.mem := mem_value_v;
            mem_wb_rc_v         := ex_mem_rc_exp;
            
            if mem_wb_rc_v.A.cntrl.mem = MEM_READ then
                wb_value_v.A.data := memwb_value_v.A.mem;
            else
                wb_value_v.A.data := memwb_value_v.A.alu;
            end if;  
            wb_value_v.A.rd := mem_wb_rc_v.A.rd;  
            wb_value_v.A.we := mem_wb_rc_v.A.cntrl.wb;  
            
            if mem_wb_rc_v.B.cntrl.mem = MEM_READ then
                wb_value_v.B.data := memwb_value_v.B.mem;
            else
                wb_value_v.B.data := memwb_value_v.B.alu;
            end if;    
            wb_value_v.B.rd := mem_wb_rc_v.B.rd;  
            wb_value_v.B.we := mem_wb_rc_v.B.cntrl.wb;  
               
            -- expected output
            -- propagation of each stages (pc, instruction, and validity) 
            id_ipcv_exp     <= if_ipcv;
            ex_ipcv_exp     <= id_ipcv_exp;
            mem_ipcv_exp    <= ex_ipcv_exp;
            wb_ipcv_exp     <= mem_ipcv_exp;
            
            id_value_exp    <= id_value_v;
            id_cntrl_exp    <= id_cntrl_v;
            id_haz_exp      <= id_haz_v;  
            id_datas_exp    <= id_datas_v;
            
            idex_value_exp  <= idex_value_v;
            idex_cntrl_exp  <= idex_cntrl_v;
            idex_datas_exp  <= idex_datas_v;
            Forw_exp        <= id_haz_exp;
            ex_value_exp    <= ex_value_v;
            
            exmem_value_exp <= exmem_value_v;
            exmem_cntrl_exp <= exmem_cntrl_v;
            mem_value_exp   <= mem_value_v;
            
            memwb_value_exp <= memwb_value_v;
            wb_value_exp    <= wb_value_v; 
        
            -- Let the result settle down
             wait until rising_edge(clk);
            
            -- Keep track the test
           -- if id_ipcv = id_ipcv_exp and id_value = id_value_exp and id_cntrl = id_cntrl_exp and
             --  id_haz = id_haz_exp and id_datas = id_datas_exp and idex_ipcv = idex_ipcv_exp and
             --  idex_value = idex_value_exp and idex_cntrl = idex_cntrl_exp and 
            --   idex_datas = idex_datas_exp and ex_value = ex_value_exp and exmem_ipcv = exmem_ipcv_exp 
             --  and exmem_value = exmem_value_exp and exmem_cntrl = exmem_cntrl_exp and 
              -- mem_value = mem_value_exp and memwb_ipcv = memwb_ipcv_exp and
              -- memwb_value = memwb_value_exp and wb_value = wb_value_exp then
            if id_ipcv = id_ipcv_exp and ex_ipcv = ex_ipcv_exp and mem_ipcv = mem_ipcv_exp and wb_ipcv = wb_ipcv_exp then
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
