

`timescale 1ns/1ps
import InstrGenPkg::*;
import enum_helpers::*;
import struct_helpers::*;

module tb_id;

    logic clk = 0;
    always #5 clk = ~clk; // Clock: 10ns period
    // Actual
    logic [31:0] instr1, instr2;
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
    int idr1 = 0, idi1 = 0,  idl1 = 0,  ids1 = 0,  idj1 = 0,  idb1 = 0, idd1 = 0;
    int idr2 = 0, idi2 = 0,  idl2 = 0,  ids2 = 0,  idj2 = 0,  idb2 = 0, idd2 = 0;
    int seed = 24, total_tests = 100;
    
    // Transaction class for stimulus
    class IDTest;
        rand bit [31:0] wr_data1, wr_data2;
        rand control_signal_t  we1, we2, ex1, ex2, m1, m2;

        constraint we_constraint {
        we1 inside {REG_WRITE, NONE_c};
        we2 inside {REG_WRITE, NONE_c};
        ex1 inside {REG_WRITE, NONE_c};
        ex2 inside {REG_WRITE, NONE_c};
        m1  inside {REG_WRITE, NONE_c};
        m2  inside {REG_WRITE, NONE_c};
        }
    
        task automatic apply();
            instr1 = gen_random_instr(seed);
            instr2 = gen_random_instr(seed);
            
            ID_EX           <= ID;
            EX_MEM.A.target = NONE_c;
            EX_MEM.A.alu    = NONE_c;
            EX_MEM.A.mem    = NONE_c;
            EX_MEM.A.wb     = ex1;
            EX_MEM.A.rd     <= ID_EX.A.rd;
            MEM_WB.A.target = NONE_c;
            MEM_WB.A.alu    = NONE_c;
            MEM_WB.A.mem    = NONE_c;
            MEM_WB.A.wb     = m1;
            MEM_WB.A.rd     <= EX_MEM.A.rd;
            EX_MEM.B.target = NONE_c;
            EX_MEM.B.alu    = NONE_c;
            EX_MEM.B.mem    = NONE_c;
            EX_MEM.B.wb     = ex2;
            EX_MEM.B.rd     <= ID_EX.B.rd;
            MEM_WB.B.target = NONE_c;
            MEM_WB.B.alu    = NONE_c;
            MEM_WB.B.mem    = NONE_c;
            MEM_WB.B.wb     = m2; 
            MEM_WB.B.rd     <= EX_MEM.B.rd;
            WB.A            = '{wr_data1, MEM_WB.A.rd, we1};
            WB.B            = '{wr_data2, MEM_WB.B.rd, we2};
            
            ID_exp          = '{decode(instr1), decode(instr2)};
            cntrl_exp       = '{cntrl_gen(ID_exp.A.op), cntrl_gen(ID_exp.B.op)};
            ID_EX_exp       <= ID_exp;
            EX_MEM_exp.A    = '{NONE_c, NONE_c, NONE_c, cntrl_exp.A.wb, ID_EX_exp.A.rd};
            EX_MEM_exp.B    = '{NONE_c, NONE_c, NONE_c, cntrl_exp.B.wb, ID_EX_exp.B.rd};
            MEM_WB_exp      = EX_MEM_exp;
            WB_exp.A        = '{wr_data1, MEM_WB_exp.A.rd, we1};
            WB_exp.B        = '{wr_data2, MEM_WB_exp.B.rd, we2};
            
            haz_exp       = haz_gen(ID_exp, ID_EX_exp, cntrl_exp, EX_MEM_exp, MEM_WB_exp);
    
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
    endclass
    
    task automatic check();
        #1;
        if ((ID === ID_exp) && (ID_EX === ID_EX_exp) && (EX_MEM === EX_MEM_exp) &&
            (EX_MEM === EX_MEM_exp) && (MEM_WB === MEM_WB_exp) && (haz === haz_exp) &&
            (cntrl === cntrl_exp) && (datas === data_exp) && 
            (WB === WB_exp)) begin
            pass++;
        end else begin
            fail++;
            
            if (ID !== ID_exp) begin  
                if (ID.A !== ID_exp.A) begin
                    case (ID_exp.A.op)
                        7'b0110011: idr1++;
                        7'b0010011: idi1++;
                        7'b0000011: idl1++;
                        7'b0100011: ids1++;
                        7'b1101111: idj1++;
                        7'b1100011: idb1++;
                        default:    idd1++;   
                    endcase
                end
                if (ID.B !== ID_exp.B) begin
                    case (ID_exp.B.op)
                        7'b0110011: idr2++;
                        7'b0010011: idi2++;
                        7'b0000011: idl2++;
                        7'b0100011: ids2++;
                        7'b1101111: idj2++;
                        7'b1100011: idb2++;
                        default:    idd2++;   
                    endcase    
                end  
                fid++;
            end 
            if (ID_EX !== ID_EX_exp)   fidex++;
            if (EX_MEM !== EX_MEM_exp) fe++;
            if (MEM_WB !== MEM_WB_exp) fm++;
            if (WB !== WB_exp)         fw++;
            if (haz !== haz_exp)       fh++;
            if (cntrl !== cntrl_exp)   fc++;
            if (datas !== data_exp)    fd++;
        end
    endtask

    IDTest t;
    
    initial begin
        $display("Starting ID_STAGE randomized testbench...");
        golden_regs = '{default:0};
         
        instr1      = '0; instr2 = '0;
        datas       = '0; data_exp = '0;
        ID          = '{default: 0}; ID_EX = '{default: 0};
        ID_exp      = '{default: 0}; ID_EX_exp = '{default: 0};
        cntrl       = '{A: '{default: NONE_c}, B: '{default: NONE_c}};
        cntrl_exp   = cntrl;
        haz         = '{A: '{default: NONE_h}, B: '{default: NONE_h}};
        haz_exp     = haz;
        EX_MEM      = '{A: '{default: NONE_c, rd: 5'd0}, B: '{default: NONE_c, rd: 5'd0}};
        MEM_WB      = EX_MEM;
        WB          = '{A: '{data: 0, rd: 0, we: NONE_c}, B: '{data: 0, rd: 0, we: NONE_c}};
        WB_exp      = WB;
        EX_MEM_exp  = EX_MEM;
        MEM_WB_exp  = MEM_WB;
        
         
       for (int test_count = 0; test_count < total_tests; test_count++) begin
            @(posedge clk);
            t = new();
            if (!t.randomize()) begin
                $display("ERROR: Randomization failed at test %0d", test_count);
                $fatal;
            end
            t.apply();
            @(posedge clk);
            check();
        end
        if (pass == total_tests) begin
            $display("All %0d tests passed!", pass);
        end else begin
            $display("%0d tests failed out of %0d", fail, total_tests);
            if (fid !== 0) begin
                $display("------ID--------");
                $display("ID mismatches : %0d", fid);
                $display("------1st--------");
                $display("R : %0d", idr1);
                $display("I : %0d", idi1);
                $display("L : %0d", idl1);
                $display("J : %0d", idj1);
                $display("S : %0d", ids1);
                $display("B : %0d", idb1);
                $display("------2nd--------");
                $display("R : %0d", idr2);
                $display("I : %0d", idi2);
                $display("L : %0d", idl2);
                $display("J : %0d", idj2);
                $display("S : %0d", ids2);
                $display("B : %0d", idb2);
                $display("----------------");
            end 
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
