

`timescale 1ns/1ps
import InstrGenPkg::*;
import enum_helpers::*;
import struct_helpers::*;

module tb_id;

    logic clk = 0;
    always #5 clk = ~clk; // Clock: 10ns period
    
    logic [31:0] data1, data2, instr1, instr2;
    id_ex_t      ID, ID_exp, ID_EX, ID_EX_exp;
    ctrl_N_t     cntrl, cntrl_exp;
    haz_t        haz, haz_exp;
    regs_t       datas, data_exp;
    rd_ctrl_N_t  EX_MEM, EX_MEM_exp, MEM_WB, MEM_WB_exp;
    wb_t         WB, WB_exp;
    
    logic [31:0] golden_regs[31:0];

    ID_STAGE dut (
            .clk(clk),
            .instr1(instr1),
            .instr2(instr2),
            .ID_EX(ID_EX),
            .ex_rd1(EX_MEM.A.rd), .ex_c1(EX_MEM.A.wb),
            .ex_rd2(EX_MEM.B.rd), .ex_c2(EX_MEM.B.wb),
            .m_rd1(MEM_WB.A.rd),  .m_c1(MEM_WB.A.wb),
            .m_rd2(MEM_WB.B.rd),  .m_c2(MEM_WB.B.wb),
            .rd1(WB.A.rd),        .wb_data1(WB.A.data), .wb_we1(WB.A.we),
            .rd2(WB.B.rd),        .wb_data2(WB.B.data), .wb_we2(WB.B.we),
            .ID_out(ID),
            .cntrl(cntrl),
            .haz(haz),
            .datas(datas)
            );

    int pass = 0, fail = 0, pe = 0;
    int fid = 0, fidex = 0, fe = 0, fm = 0, fw = 0, fc = 0, fh = 0, fd = 0;
    int seed = 24, test_count = 0, total_tests = 100;
    
    task automatic apply();
        instr1 = gen_random_instr(seed);
        instr2 = gen_random_instr(seed);
        data1  = $urandom;
        data2  = $urandom;
        
        ID_EX         <= ID;
        EX_MEM.A      <= '{cntrl.A.target, cntrl.A.alu, cntrl.A.mem, cntrl.A.wb, ID_EX.A.rd};
        EX_MEM.B      <= '{cntrl.B.target, cntrl.B.alu, cntrl.B.mem, cntrl.B.wb, ID_EX.B.rd};
        MEM_WB        <= EX_MEM;
        WB.A          <= '{data1, MEM_WB.A.rd, MEM_WB.A.wb};
        WB.B          <= '{data2, MEM_WB.B.rd, MEM_WB.B.wb};
        
        ID_exp        = '{decode(instr1), decode(instr2)};
        cntrl_exp     = '{cntrl_gen(ID_exp.A.op), cntrl_gen(ID_exp.B.op)};
        ID_EX_exp     <= ID_exp;
        EX_MEM_exp.A  <= '{cntrl_exp.A.target, cntrl_exp.A.alu, cntrl_exp.A.mem, cntrl_exp.A.wb, ID_EX_exp.A.rd};
        EX_MEM_exp.B  <= '{cntrl_exp.B.target, cntrl_exp.B.alu, cntrl_exp.B.mem, cntrl_exp.B.wb, ID_EX_exp.B.rd};
        MEM_WB_exp    <= EX_MEM_exp;
        WB_exp.A      <= '{data1, MEM_WB_exp.A.rd, MEM_WB_exp.A.wb};
        WB_exp.B      <= '{data2, MEM_WB_exp.B.rd, MEM_WB_exp.B.wb};
        
        haz_exp       <= haz_gen(ID_exp, ID_EX_exp, cntrl_exp, EX_MEM_exp, MEM_WB_exp);

    if ((WB_exp.A.we == REG_WRITE) && (WB_exp.A.rd != 0))
        golden_regs[WB_exp.A.rd] = WB_exp.A.data;
    if ((WB_exp.B.we == REG_WRITE) && (WB_exp.B.rd != 0) && 
        !(WB_exp.A.we == REG_WRITE && WB_exp.A.rd == WB_exp.B.rd))
        golden_regs[WB_exp.B.rd] = WB_exp.B.data;
        
        data_exp.one.A = golden_regs[ID_exp.A.rs1];
        data_exp.one.B = golden_regs[ID_exp.A.rs2];
        data_exp.two.A = golden_regs[ID_exp.B.rs1];
        data_exp.two.B = golden_regs[ID_exp.B.rs2];
    endtask
    
    task automatic check();
    #1;
    if ((ID === ID_exp) && (ID_EX === ID_EX_exp) && (EX_MEM === EX_MEM_exp) &&
        (EX_MEM === EX_MEM_exp) && (MEM_WB === MEM_WB_exp) && (haz === haz_exp) &&
        (cntrl === cntrl_exp) && (datas === data_exp) && 
        (WB === WB_exp)) begin
        pass++;
    end else begin
        fail++;
        if (ID !== ID_exp)         fid++;
        if (ID_EX !== ID_EX_exp)   fidex++;
        if (EX_MEM !== EX_MEM_exp) begin
            if ((EX_MEM.A.wb === EX_MEM_exp.A.wb) && (EX_MEM.B.wb === EX_MEM_exp.B.wb)) begin
                pe++;
            end else begin
                fe++;
            end
        end
        if (MEM_WB !== MEM_WB_exp) fm++;
        if (WB !== WB_exp)         fw++;
        if (haz !== haz_exp)       fh++;
        if (cntrl !== cntrl_exp)   fc++;
        if (datas !== data_exp)    fd++;
    end
    endtask

    initial begin
        $display("Starting ID_STAGE randomized testbench...");
        golden_regs = '{default: 0};
        datas = '0; data_exp = '0; data1 = '0; data2 = '0;
        instr1 = '0; instr2 = '0;
    
        ID         = '{default: 0}; ID_EX = '{default: 0};
        ID_exp     = '{default: 0}; ID_EX_exp = '{default: 0};
        cntrl      = '{A: '{default: NONE_c}, B: '{default: NONE_c}};
        cntrl_exp  = cntrl;
        haz        = '{A: '{default: NONE_h}, B: '{default: NONE_h}};
        haz_exp    = haz;
        EX_MEM     = '{A: '{default: NONE_c, rd: 5'd0}, B: '{default: NONE_c, rd: 5'd0}};
        MEM_WB     = EX_MEM;
        WB         = '{A: '{data: 0, rd: 0, we: NONE_c}, B: '{data: 0, rd: 0, we: NONE_c}};
        WB_exp     = WB;
        EX_MEM_exp = EX_MEM;
        MEM_WB_exp = MEM_WB;
        
        for (test_count = 0; test_count < total_tests; test_count++) begin
          @(posedge clk);
          apply();
          @(posedge clk);
          check();
        end
        
        if (pass == total_tests) begin
          $display("All %0d tests passed!", pass);
        end else begin
          $display("%0d tests failed out of %0d", fail, total_tests);
          $display("ID mismatches     : %0d", fid);
          $display("ID_EX mismatches  : %0d", fidex);
          $display("EX_MEM mismatches : %0d", fe);
          $display("EX_MEM correc     : %0d", pe);
          $display("MEM_WB mismatches : %0d", fm);
          $display("WB mismatches     : %0d", fw);
          $display("Hazard mismatches : %0d", fh);
          $display("Control mismatches: %0d", fc);
          $display("Data mismatches   : %0d", fd);
        end
        $stop;
        end
    
endmodule 
