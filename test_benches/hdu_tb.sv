// Noridel Herron
// Additional testbench and practice testbench in system verilog
`timescale 1ns / 1ps
import InstrGenPkg::*;
import struct_helpers::*;
import enum_helpers::*;

module hdu_tb( );
    
    logic clk = 0;
    always #5 clk = ~clk; // Clock: 10ns period
    
    id_ex_t     id, idex; 
    ctrl_N_t    id_c, idex_c;
    rd_ctrl_N_t exmem, memwb;
    haz_t       haz, exp_haz;
    
    // Instantiate DUT
    hdu_wrapper dut (
        .ida_rs1(id.A.rs1),       .ida_rs2(id.A.rs2),
        .idb_rs1(id.B.rs1),       .idb_rs2(id.B.rs1),
        .idexa_rd(idex.A.rd),     .idexa_rs1(idex.A.rs1), .idexa_rs2(idex.A.rs2),
        .idexa_mem(idex_c.A.mem), .idexa_wb(idex_c.A.wb),
        .idexb_rd(idex.B.rd),     .idexb_rs1(idex.B.rs1), .idexb_rs2(idex.B.rs2),
        .idexb_mem(idex_c.B.mem), .idexb_wb(idex_c.B.wb),
        .exmema_wb(exmem.A.wb),   .exmema_rd(exmem.A.rd),
        .exmemb_wb(exmem.B.wb),   .exmemb_rd(exmem.B.rd),
        .memwba_wb(memwb.A.wb),   .memwba_rd(memwb.A.rd),
        .memwbb_wb(memwb.B.wb),   .memwbb_rd(memwb.B.rd),
        .aforwa(haz.A.ForwA),     .aforwb(haz.A.ForwB),   .aforws(haz.A.stall),
        .bforwa(haz.B.ForwA),     .bforwb(haz.B.ForwB),   .bforws(haz.B.stall)
    );
    
    int total_tests = 1000;
    // Keep track all the test and make sure it covers all the cases
    int pass = 0, fail = 0; 
    // instruction 1 
    int afa_emA = 0, afa_emB = 0, afa_mwA = 0, afa_mwB = 0, apfnA = 0; // AForwA
    int afb_emA = 0, afb_emB = 0, afb_mwA = 0, afb_mwB = 0, apfnB = 0; // AForwB
    int asA = 0, asB = 0,  asn = 0; // Astall
    
    int bfa_ffa = 0, bfa_emA = 0, bfa_emB = 0, bfa_mwA = 0, bfa_mwB = 0, bpfnA = 0; // BForwA
    int bfb_ffa = 0, bfb_emA = 0, bfb_emB = 0, bfb_mwA = 0, bfb_mwB = 0, bpfnB = 0; // BForwB
    int bsAA = 0, bsA = 0, bsB = 0,  bsn = 0; // Bstall
    
    // Narrow down bugs
    int fhAA = 0, fhAB = 0, fhAS = 0, fhBA = 0, fhBB = 0, fhBS = 0;
    
    class HAZ_UNIT;
        rand bit [6:0]   randA_op,  randB_op;
        rand bit [4:0]   randA_rs1, randA_rs2, randA_rd;
        rand bit [4:0]   randB_rs1, randB_rs2, randB_rd;
        control_signal_t randB_mem, randB_wb;

        constraint unique_op {
            randA_op dist {
                R_TYPE  := 25, S_TYPE := 10, B_TYPE := 10, JAL := 10, 
                IMM     := 15, LOAD   := 10, JALR   := 5, ECALL   := 5,
                U_LUI   := 5, U_AUIPC := 5 // remove the comment to catch all edge cases
                //[7'b0000000:7'b1111111] := 5  // catch-all random opcodes
            };
            
            randB_op dist {
                R_TYPE  := 25, S_TYPE := 10, B_TYPE := 10, JAL := 10, 
                IMM     := 15, LOAD   := 10, JALR   := 5, ECALL   := 5,
                U_LUI   := 5, U_AUIPC := 5 // remove the comment to catch all edge cases
                //[7'b0000000:7'b1111111] := 5  // catch-all random opcodes
            };
        }
       
        function void apply_inputs();
            id.A.op <= randA_op; id.A.rs1 <= randA_rs1; id.A.rs2    <= randA_rs2; id.A.rd    <= randA_rd;
            id_c.A  = cntrl_gen(randA_op);
            
            id.B.op <= randB_op; id.B.rs1 <= randB_rs1; id.B.rs2 <= randB_rs2; id.B.rd <= randB_rd;
            id_c.B  = cntrl_gen(randB_op);
            
            idex.A.op       <= id.A.op;       idex.A.rd  <= id.A.rd;    idex.A.rs1 <= id.A.rs1;   idex.A.rs2 <= id.A.rs2; 
            idex_c.A.target <= id_c.A.target; idex_c.A.alu <= id_c.A.alu; idex_c.A.mem <= id_c.A.mem; idex_c.A.wb <= id_c.A.wb;   
            
            idex.B.op       <= id.B.op;       idex.B.rd  <= id.B.rd;    idex.B.rs1 <= id.B.rs1;   idex.B.rs2 <= id.B.rs2; 
            idex_c.B.target <= id_c.B.target; idex_c.B.alu <= id_c.B.alu; idex_c.B.mem <= id_c.B.mem; idex_c.B.wb <= id_c.B.wb;   
            
            exmem.A.op  <= idex.A.op;    exmem.A.rd  <= idex.A.rd;    exmem.A.target <= idex_c.A.target;
            exmem.A.alu <= idex_c.A.alu; exmem.A.mem <= idex_c.A.mem; exmem.A.wb <= idex_c.A.wb; 
            
            exmem.B.op  <= idex.B.op;    exmem.B.rd  <= idex.B.rd;    exmem.B.target <= idex_c.B.target;
            exmem.B.alu <= idex_c.B.alu; exmem.A.mem <= idex_c.B.mem; exmem.B.wb <= idex_c.B.wb; 
  
            memwb <= exmem; 
            
        endfunction
        
        task check();
            exp_haz.A.ForwA = haz_forw1( exmem.A.op, exmem.A.rd, exmem.B.op, exmem.B.rd, 
                              memwb.A.op, memwb.A.rd, memwb.B.op, memwb.B.rd, idex.A.rs1);
            exp_haz.A.ForwB = haz_forw1( exmem.A.op, exmem.A.rd, exmem.B.op, exmem.B.rd, 
                              memwb.A.op, memwb.A.rd, memwb.B.op, memwb.B.rd, idex.A.rs2);  
            exp_haz.A.stall = haz_stall1( idex.A.op, idex.A.rd, idex.B.op, idex.B.rd, id.A.rs1, id.A.rs2);
            
            exp_haz.B.ForwA = haz_forw2( exmem.A.op, exmem.A.rd, exmem.B.op, exmem.B.rd, 
                              memwb.A.op, memwb.A.rd, memwb.B.op, memwb.B.rd, idex.A.op, idex.A.rs1);
            exp_haz.B.ForwB = haz_forw2( exmem.A.op, exmem.A.rd, exmem.B.op, exmem.B.rd, 
                              memwb.A.op, memwb.A.rd, memwb.B.op, memwb.B.rd, idex.A.op,  idex.A.rs2);  
            exp_haz.B.stall = haz_stall2( idex.A.op, idex.A.rd, idex.B.op, id.A.op, idex.B.rd, id.A.rd, id.B.rs1, id.B.rs2);
            

            if (haz === exp_haz) begin
                pass++;
               
            end else begin 
                // Instruction A  
                if (haz.A.ForwA !== exp_haz.A.ForwA) begin 
                    fhAA++;
                    $display("A: Actual ForwA = %s : expected ForwA = %s ", haz.A.ForwA, exp_haz.A.ForwA); 
                end
                
                if (haz.A.ForwB !== exp_haz.A.ForwB) begin 
                    fhAB++;
                    $display("A: Actual ForwB = %s : expected ForwB = %s ", haz.A.ForwB, exp_haz.A.ForwB); 
                end
                
                if (haz.A.stall !== exp_haz.A.stall) begin 
                    fhAS++;
                    $display("A: Actual stall = %s : expected stall = %s ", haz.A.stall, exp_haz.A.stall); 
                end
                
                // Instruction B
                if (haz.B.ForwA !== exp_haz.B.ForwA) begin 
                    fhBA++;
                    $display("B: Actual ForwA = %s : expected ForwA = %s ", haz.B.ForwA, exp_haz.B.ForwA); 
                end
                
                if (haz.B.ForwB !== exp_haz.B.ForwB) begin 
                    fhBB++;
                    $display("B: Actual ForwB = %s : expected ForwB = %s ", haz.B.ForwB, exp_haz.B.ForwB); 
                end
                
                if (haz.B.stall !== exp_haz.B.stall) begin 
                    fhBS++;
                    $display("B: Actual stall = %s : expected stall = %s ", haz.B.stall, exp_haz.B.stall); 
                end
            end
        endtask 
    endclass
    
    HAZ_UNIT t;
    initial begin
        $display("Starting DECODER randomized testbench...");
        
        id.A    = '{op : 7'b0, rd: 5'b0, funct3: 3'b0, rs1: 5'b0, rs2: 5'b0, funct7: 7'b0, imm12: 12'b0, imm20: 20'b0};
        id.B    = id.A; idex = id;
        id_c.A  = '{target: NONE_c, alu:  NONE_c, mem:  NONE_c, wb:  NONE_c};
        id_c.B  = id_c.A; idex_c = id_c;
        exmem.A = '{op : 7'b0, target: NONE_c, alu:  NONE_c, mem:  NONE_c, wb:  NONE_c, rd: 5'b0};
        exmem.B = exmem.A; memwb = exmem;
        haz.A   = '{ForwA: NONE_h, ForwB: NONE_h, stall: NONE_h};
        haz.B   = haz.A; exp_haz = haz;
        
        repeat (total_tests) begin
            t = new();
            void'(t.randomize());
            @(posedge clk);
            t.apply_inputs();  
            @(posedge clk); // Have to update on rising edge to ensure that we compare the correct values
            t.check();
        end

        // If there's any error, "Case covered summary" will not be display until everything is resolve
        if (pass == total_tests) begin
            $display("All %0d tests passed!", pass);
            $display("Case Covered Summary!!!");
            $display("AA: EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", afa_emA, afa_emB, afa_mwA, afa_mwB, apfnA);
            $display("AB: EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", afb_emA, afb_emB, afb_mwA, afb_mwB, apfnB);
            $display("AS: A_STALL  : %0d, B_STALL  : %0d, NONE : %0d,", asA, asB, asn);
            $display("BA: FFA      : %0d, EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", bfa_ffa, bfa_emA, bfa_emB, bfa_mwA, bfa_mwB, bpfnA);
            $display("BB: FFA      : %0d, EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", bfb_ffa, bfb_emA, bfb_emB, bfb_mwA, bfb_mwB, bpfnB);
            $display("BS: SFA      : %0d, A_STALL  : %0d, B_STALL  : %0d, NONE : %0d,", bsAA, bsA, bsB, bsn);

        end else begin
            $display("%0d tests failed out of %0d", fail, total_tests);
            if (fhAA   !== 0) $display("A: forwA  : %0d",  fhAA);
            if (fhAB   !== 0) $display("A: forwB  : %0d",  fhAB);
            if (fhAS   !== 0) $display("A: stall  : %0d",  fhAS);
            if (fhBA   !== 0) $display("B: forwA  : %0d",  fhBA);
            if (fhBB   !== 0) $display("B: forwB  : %0d",  fhBB);
            if (fhBS   !== 0) $display("B: stall  : %0d",  fhBS);
        end
       $stop;
    end
endmodule
