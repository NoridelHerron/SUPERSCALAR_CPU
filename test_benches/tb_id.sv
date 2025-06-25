`timescale 1ns/1ps
import InstrGenPkg::*;       // gen_random_instr(), decode(), cntrl_gen(), haz_gen()
import enum_helpers::*;
import struct_helpers::*;

module tb_id_stage;

    // Clock generation
    logic clk = 0;
    always #5 clk = ~clk; // 10ns period
    
    // Inputs to DUT
    logic [31:0] instr1, instr2;
    
    // Pipeline registers and control signals
    id_ex_t     ID, ID_exp, ID_EX, ID_EX_exp;
    rd_ctrl_N_t EX_MEM, EX_MEM_exp, MEM_WB, MEM_WB_exp;
    mem_wb_t    WB_exp, WB;
    ctrl_N_t    cntrl, cntrl_exp;
    haz_t       haz, haz_exp;
    regs_t      datas, data_exp;
    
    // Other signals
    logic [31:0] golden_regs[31:0];
    logic [31:0] wb_data1, wb_data2;
    logic [3:0]  wb_we1, wb_we2;
    logic [4:0]  rd1, rd2;

    // DUT instantiation
    ID_STAGE dut (
      .clk(clk),
      .instr1(instr1),
      .instr2(instr2),
      .ID_EX(ID_EX),
      .EX_MEM(EX_MEM),
      .MEM_WB(MEM_WB),
      .rd1(rd1), .wb_data1(wb_data1), .wb_we1(wb_we1),
      .rd2(rd2), .wb_data2(wb_data2), .wb_we2(wb_we2),
      .ID_out(ID),
      .cntrl(cntrl),
      .haz(haz),
      .datas(datas)
    );

    // Test counters and seed
    int pass = 0;
    int fail = 0;
    int fid = 0, fidex = 0, fe = 0, fm = 0, fw = 0, fc = 0, fh = 0, fd = 0;
    int seed = 24;
    int test_count = 0;
    int total_tests = 100;  // adjust for your test duration preference
    
  // Apply inputs and update expected values task
    task automatic apply();
        // Generate random instructions
        instr1 = gen_random_instr(seed);
        instr2 = gen_random_instr(seed);
    
        // Generate random data for write-back stage
        wb_data1 = $urandom;
        wb_data2 = $urandom;
        
        // Capture current pipeline registers from DUT outputs (for testbench propagation)
        ID_EX          = ID;
        EX_MEM.A.cntrl = cntrl.A.wb;
        EX_MEM.A.rd    = ID_EX.A.rd;
        EX_MEM.B.cntrl = cntrl.B.wb;
        EX_MEM.B.rd    = ID_EX.B.rd;
        
        MEM_WB = EX_MEM;
        rd1    = MEM_WB.A.rd;
        wb_we1 = MEM_WB.A.cntrl;
        rd2    = MEM_WB.B.rd;
        wb_we2 = MEM_WB.B.cntrl;
        
        WB.A.data  = wb_data1;
        WB.A.rd    = MEM_WB.A.rd;
        WB.A.cntrl = MEM_WB.A.cntrl;
        WB.B.data  = wb_data2;
        WB.B.rd    = MEM_WB.B.rd;
        WB.B.cntrl = MEM_WB.B.cntrl;
        
        // Expected decoding
        ID_exp.A = decode(instr1);
        ID_exp.B = decode(instr2);
        
        // Expected control signals
        cntrl_exp.A = cntrl_gen(ID_exp.A.op);
        cntrl_exp.B = cntrl_gen(ID_exp.B.op);
        
        // Expected pipeline registers
        ID_EX_exp = ID_exp;
        EX_MEM_exp.A.cntrl = cntrl_exp.A.wb;
        EX_MEM_exp.A.rd    = ID_EX_exp.A.rd;
        EX_MEM_exp.B.cntrl = cntrl_exp.B.wb;
        EX_MEM_exp.B.rd    = ID_EX_exp.B.rd;
        
        MEM_WB_exp = EX_MEM_exp;
        
        WB_exp.A.data  = wb_data1;
        WB_exp.A.rd    = MEM_WB_exp.A.rd;
        WB_exp.A.cntrl = MEM_WB_exp.A.cntrl;
        WB_exp.B.data  = wb_data2;
        WB_exp.B.rd    = MEM_WB_exp.B.rd;
        WB_exp.B.cntrl = MEM_WB_exp.B.cntrl;
        
        // Hazard detection expected values
        haz_exp.A = haz_gen(ID_exp, ID_EX_exp, cntrl_exp, EX_MEM_exp, MEM_WB_exp);
    
        // Update golden registers based on write-back stage signals
        if ((WB_exp.A.cntrl == 4'd2) && (WB_exp.A.rd != 0))
          golden_regs[WB_exp.A.rd] = WB_exp.A.data;
        
        if ((WB_exp.B.cntrl == 4'd2) && (WB_exp.B.rd != 0) && !(WB_exp.A.cntrl == 4'd2 && WB_exp.A.rd == WB_exp.B.rd))
          golden_regs[WB_exp.B.rd] = WB_exp.B.data;
        
        // Expected register file data for source operands
        if (WB_exp.A.cntrl != 4'd2) begin
          data_exp.one.A = golden_regs[ID_exp.A.rs1];
          data_exp.one.B = golden_regs[ID_exp.A.rs2];
        end
        
        if (WB_exp.B.cntrl != 4'd2) begin
          data_exp.two.A = golden_regs[ID_exp.B.rs1];
          data_exp.two.B = golden_regs[ID_exp.B.rs2];
        end
    endtask
    
    // Print pipeline stage decoder fields (for visualization)
    task automatic print_decoder(string label, decoder_t d);
        $display("-------- %s --------", label);
        $display("op     = %b", d.op);
        $display("rd     = %0d", d.rd);
        $display("funct3 = %b", d.funct3);
        $display("rs1    = %0d", d.rs1);
        $display("rs2    = %0d", d.rs2);
        $display("funct7 = %b", d.funct7);
        $display("imm12  = %0d (0x%0h)", $signed(d.imm12), d.imm12);
        $display("imm20  = %0d (0x%0h)", $signed(d.imm20), d.imm20);
    endtask
    
    task automatic print_haz(string label, haz_per_t h);
        $display("-------- %s --------", label);
        $display("ForwA : %0d", h.ForwA);
        $display("ForwB : %0d", h.ForwB);
        $display("stall : %0d", h.stall);
    endtask
    
    task automatic print_mem_wb(string label, mem_wb_per_t wb);
        $display("-------- %s --------", label);
        $display("data  : 0x%08h (%0d)", wb.data, wb.data);
        $display("rd    : %0d", wb.rd);
        $display("cntrl : %0d", wb.cntrl);
    endtask
    
    task automatic print_rd_ctrl(string label, rd_ctrl_t rc);
        $display("-------- %s --------", label);
        $display("rd    : %0d", rc.rd);
        $display("cntrl : %0d", rc.cntrl);
    endtask
    
    task automatic print_regs_per(string label, regs_per_t r);
        $display("-------- %s --------", label);
        $display("A : 0x%08h (%0d)", r.A, r.A);
        $display("B : 0x%08h (%0d)", r.B, r.B);
    endtask
    
    task automatic print_regs(string label, regs_t r);
        $display("======== %s ========", label);
        print_regs_per({label, ".one"}, r.one);
        print_regs_per({label, ".two"}, r.two);
    endtask



  // Check and compare all signals and print diagnostics on mismatch
    task automatic check();
        #1; // Small delay to let signals settle
    
        if ((ID === ID_exp) && (ID_EX === ID_EX_exp) && (EX_MEM === EX_MEM_exp) &&
            (MEM_WB === MEM_WB_exp) && (WB === WB_exp) && (haz === haz_exp) &&
            (cntrl === cntrl_exp) && (datas === data_exp)) begin
          pass++;
          
        end else begin
          fail++;
          if (ID !== ID_exp) begin
            fid++;
            $display("Mismatch at ID:");
            print_decoder("Actual ID.A", ID.A);
            print_decoder("Expected ID.A", ID_exp.A);
            print_decoder("Actual ID.B", ID.B);
            print_decoder("Expected ID.B", ID_exp.B);
          end
          if (ID_EX !== ID_EX_exp) begin
            fidex++;
            $display("Match at ID:");
            print_decoder("Actual ID.A", ID.A);
            print_decoder("Expected ID.A", ID_exp.A);
            print_decoder("Actual ID.B", ID.B);
            print_decoder("Expected ID.B", ID_exp.B);
            $display("Mismatch at ID_EX:");
            print_decoder("Actual ID_EX.A", ID_EX.A);
            print_decoder("Expected ID_EX.A", ID_EX_exp.A);
            print_decoder("Actual ID_EX.B", ID_EX.B);
            print_decoder("Expected ID_EX.B", ID_EX_exp.B);
          end
          if (EX_MEM !== EX_MEM_exp) begin
            fe++;
            $display("Mismatch at EX_MEM");
            print_rd_ctrl("Actual EX_MEM.A ", EX_MEM.A);
            print_rd_ctrl("Expected EX_MEM.A ", EX_MEM.A);
            print_rd_ctrl("Actual EX_MEM.B ", EX_MEM.B);
            print_rd_ctrl("Expected EX_MEM.B ", EX_MEM.B);
          end
          if (MEM_WB !== MEM_WB_exp) begin
            fm++;
            $display("Mismatch at MEM_WB");
            print_rd_ctrl("Actual MEM_WB.A ", MEM_WB.A);
            print_rd_ctrl("Expected MEM_WB.A ", MEM_WB.A);
            print_rd_ctrl("Actual MEM_WB.B ", MEM_WB.B);
            print_rd_ctrl("Expected MEM_WB.B ", MEM_WB.B);
          end
          if (WB !== WB_exp) begin
            fw++;
            $display("Mismatch at WB:");
            print_mem_wb("Actual WB.A", WB.A);
            print_mem_wb("Expected WB.A", WB_exp.A);
            print_mem_wb("Actual WB.B", WB.B);
            print_mem_wb("Expected WB.B", WB_exp.B);
          end
          if (haz !== haz_exp) begin
            fh++;
            $display("Mismatch at Hazard");   
            print_haz("Actual haz.A", haz.A);
            print_haz("Expected haz.A", haz_exp.A);
            print_haz("Actual haz.B", haz.B);
            print_haz("Expected haz.B", haz_exp.B);
          end
          if (cntrl !== cntrl_exp) begin
            fc++;
            $display("Mismatch at Control signals");
          end
          if (datas !== data_exp) begin
            fd++;
            $display("Mismatch at datas:");
            print_regs("Actual datas", datas);
            print_regs("Expected datas", data_exp);
          end 
        end
    endtask
    
  // Testbench main sequence
    initial begin
        $display("Starting ID_STAGE randomized testbench...");
        
        // Initialize memory/register model and pipeline registers
        golden_regs = '{default:0};
        ID  = '0; ID_EX  = '0; EX_MEM = '0; MEM_WB = '0; WB = '0;
        
        for (test_count = 0; test_count < total_tests; test_count++) begin
          @(posedge clk);
          apply();
          @(posedge clk);
          check();
        end
        
        // Summary report
        if (pass == total_tests) begin
          $display("All %0d tests passed!", pass);
        end else begin
          $display("%0d tests failed out of %0d", fail, total_tests);
          $display("========== MISMATCH SUMMARY ==========");
          $display("ID mismatches     : %0d", fid);
          $display("ID_EX mismatches  : %0d", fidex);
          $display("EX_MEM mismatches : %0d", fe);
          $display("MEM_WB mismatches : %0d", fm);
          $display("WB mismatches     : %0d", fw);
          $display("Hazard mismatches : %0d", fh);
          $display("Control mismatches: %0d", fc);
          $display("Data mismatches   : %0d", fd);
        end
        
    $stop;
    end

endmodule
