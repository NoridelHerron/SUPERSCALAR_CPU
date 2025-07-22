// Noridel Herron
// Additional testbench and practice testbench in system verilog
`timescale 1ns / 1ps
import InstrGenPkg::*;
import struct_helpers::*;
import enum_helpers::*;

module hdu_tb( );
    
    logic clk = 0;
    always #5 clk = ~clk; // Clock: 10ns period
    
    typedef struct packed {
        logic [6:0]  op;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
    } decoded_t;
    
    typedef struct packed {
        decoded_t  A;
        decoded_t  B;
    } decoded_N;
    
    logic [31:0] i;
    decoded_N    id, exp_id;  
    ctrl_N_t     id_c, exp_id_c;
    decoded_N    idex, exp_idex;
    ctrl_N_t     idex_c, exp_idex_c;
    rd_ctrl_N_t  exmem, exp_exmem, memwb, exp_memwb;
    haz_t        haz, exp_haz;
    haz_val_t    haz_temp;
    
    // Instantiate DUT
    hdu_wrapper dut (
        .ida_rs1(id.A.rs1),        .ida_rs2(id.A.rs2),
        .idb_rs1(id.B.rs1),        .idb_rs2(id.B.rs2),
        .idexa_rd(idex.A.rd),      .idexa_rs1(idex.A.rs1),  .idexa_rs2(idex.A.rs2),
        .idexa_mem(idex_c.A.mem),  .idexa_wb(idex_c.A.wb),
        .idexb_rd(idex.B.rd),      .idexb_rs1(idex.B.rs1),  .idexb_rs2(idex.B.rs2),
        .idexb_mem(idex_c.B.mem),  .idexb_wb(idex_c.B.wb),
        .exmema_wb(exmem.A.wb),    .exmema_rd(exmem.A.rd),
        .exmemb_wb(exmem.B.wb),    .exmemb_rd(exmem.B.rd),
        .memwba_wb(memwb.A.wb),    .memwba_rd(memwb.A.rd),
        .memwbb_wb(memwb.B.wb),    .memwbb_rd(memwb.B.rd),
        .aforwa(haz_temp.A.fA),    .aforwb(haz_temp.A.fB),  .aforws(haz_temp.A.st),
        .bforwa(haz_temp.B.fA),    .bforwb(haz_temp.B.fB),  .bforws(haz_temp.B.st)
    );
    
    int total_tests = 100000;
    // Keep track all the test and make sure it covers all the cases
    int pass = 0, fail = 0; 
    // instruction 1 
    int afa_emA = 0, afa_emB = 0, afa_mwA = 0, afa_mwB = 0, apfnA = 0; // AForwA
    int afb_emA = 0, afb_emB = 0, afb_mwA = 0, afb_mwB = 0, apfnB = 0; // AForwB
    int asA = 0, asB = 0,  asn = 0; // Astall
    // instruction 2
    int bfa_ffa = 0, bfa_emA = 0, bfa_emB = 0, bfa_mwA = 0, bfa_mwB = 0, bpfnA = 0; // BForwA
    int bfb_ffa = 0, bfb_emA = 0, bfb_emB = 0, bfb_mwA = 0, bfb_mwB = 0, bpfnB = 0; // BForwB
    int bsAA = 0, bsA = 0, bsB = 0,  bsn = 0; // Bstall
    // Keep track of the mismatch inputs
    int fid = 0, fid_c = 0, fidex = 0, fidex_c = 0, fexmem = 0, fmemwb = 0, fh = 0;
    // Narrow down bugs
    int fhAA = 0, fhAB = 0, fhAS = 0, fhBA = 0, fhBB = 0, fhBS = 0;
    
    class HAZ_UNIT;
        rand bit [6:0]   randA_op,  randB_op;
        rand bit [4:0]   randA_rs1, randA_rs2, randA_rd;
        rand bit [4:0]   randB_rs1, randB_rs2, randB_rd;

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
       
        function void apply_id();
            // Actual                               // EXPECTED INPUT
            id.A.op     <= randA_op;                exp_id.A.op     <= randA_op;
            id.A.rs1    <= randA_rs1;               exp_id.A.rs1    <= randA_rs1;
            id.A.rs2    <= randA_rs2;               exp_id.A.rs2    <= randA_rs2;
            id.A.rd     <= randA_rd;                exp_id.A.rd     <= randA_rd;
            id_c.A      <= cntrl_gen(randA_op);     exp_id_c.A      <= cntrl_gen(randA_op);
            
            id.B.op     <= randB_op;                exp_id.B.op     <= randB_op;
            id.B.rs1    <= randB_rs1;               exp_id.B.rs1    <= randB_rs1;
            id.B.rs2    <= randB_rs2;               exp_id.B.rs2    <= randB_rs2;
            id.B.rd     <= randB_rd;                exp_id.B.rd     <= randB_rd;
            id_c.B      <= cntrl_gen(randB_op);     exp_id_c.B      <= cntrl_gen(randB_op);
        endfunction

        task check();
            exp_haz.A.ForwA = haz_forw1( exp_exmem.A.op, exp_exmem.A.rd, exp_exmem.B.op, exp_exmem.B.rd, 
                                         exp_memwb.A.op, exp_memwb.A.rd, exp_memwb.B.op, exp_memwb.B.rd, exp_idex.A.rs1);
            exp_haz.A.ForwB = haz_forw1( exp_exmem.A.op, exp_exmem.A.rd, exp_exmem.B.op, exp_exmem.B.rd, 
                                         exp_memwb.A.op, exp_memwb.A.rd, exp_memwb.B.op, exp_memwb.B.rd, exp_idex.A.rs2);  
            exp_haz.A.stall = haz_stall1( exp_idex.A.op, exp_idex.A.rd, exp_idex.B.op, exp_idex.B.rd, exp_id.A.rs1, exp_id.A.rs2);
            
            exp_haz.B.ForwA = haz_forw2( exp_exmem.A.op, exp_exmem.A.rd, exp_exmem.B.op, exp_exmem.B.rd, 
                                         exp_memwb.A.op, exp_memwb.A.rd, exp_memwb.B.op, exp_memwb.B.rd, 
                                         exp_idex.A.op,  exp_idex.A.rd,  exp_idex.B.rs1);
            exp_haz.B.ForwB = haz_forw2( exp_exmem.A.op, exp_exmem.A.rd, exp_exmem.B.op, exp_exmem.B.rd, 
                                         exp_memwb.A.op, exp_memwb.A.rd, exp_memwb.B.op, exp_memwb.B.rd, 
                                         exp_idex.A.op,  exp_idex.A.rd,  exp_idex.B.rs2);  
            exp_haz.B.stall = haz_stall2( exp_idex.A.op, exp_idex.A.rd,  exp_idex.B.op, exp_idex.B.rd, exp_id.A.op, exp_id.A.rd, exp_id.B.rs1, exp_id.B.rs2);
            // Convert the output from the dut
            haz.A.ForwA = encode_HAZ_sig(haz_temp.A.fA);
            haz.A.ForwB = encode_HAZ_sig(haz_temp.A.fB);
            haz.A.stall = encode_HAZ_sig(haz_temp.A.st);
            haz.B.ForwA = encode_HAZ_sig(haz_temp.B.fA);
            haz.B.ForwB = encode_HAZ_sig(haz_temp.B.fB);
            haz.B.stall = encode_HAZ_sig(haz_temp.B.st);
            
            if ((haz === exp_haz) && (id === exp_id) && (idex === exp_idex) && (idex_c === exp_idex_c)
                && (id_c === exp_id_c) && (exmem === exp_exmem) && (memwb === exp_memwb)) begin
                pass++;
                // Instruction A
                case (exp_haz.A.ForwA)
                    EX_MEM_A: afa_emA++;
                    EX_MEM_B: afa_emB++;
                    MEM_WB_A: afa_mwA++;
                    MEM_WB_B: afa_mwB++;
                    NONE_h  : apfnA++;
                    default:;
                endcase 
                
                case (exp_haz.A.ForwB)
                    EX_MEM_A: afb_emA++;
                    EX_MEM_B: afb_emB++;
                    MEM_WB_A: afb_mwA++;
                    MEM_WB_B: afb_mwB++;
                    NONE_h  : apfnB++;
                    default:;
                endcase 
                
                case (exp_haz.A.stall)
                    A_STALL: asA++;
                    B_STALL: asB++;
                    NONE_h  : asn++;
                    default:;
                endcase 
                
                // Instruction B
                case (exp_haz.B.ForwA)
                    FORW_FROM_A : bfa_ffa++; 
                    EX_MEM_A    : bfa_emA++;
                    EX_MEM_B    : bfa_emB++;
                    MEM_WB_A    : bfa_mwA++;
                    MEM_WB_B    : bfa_mwB++;
                    NONE_h      : bpfnA++;
                    default:;
                endcase 
                
                case (exp_haz.B.ForwB)
                    FORW_FROM_A : bfb_ffa++; 
                    EX_MEM_A    : bfb_emA++;
                    EX_MEM_B    : bfb_emB++;
                    MEM_WB_A    : bfb_mwA++;
                    MEM_WB_B    : bfb_mwB++;
                    NONE_h      : bpfnB++;
                    default:;
                endcase 
                
                case (exp_haz.B.stall)
                    STALL_FROM_A : bsAA++; 
                    A_STALL      : bsA++;
                    B_STALL      : bsB++;
                    NONE_h       : bsn++;
                    default:;
                endcase 
               
            end else begin
                fail++;
                $display ("====================================================");
                if (id !== exp_id) fid++; 
                if (id_c !== exp_id_c) fid_c++;
                if (idex !== exp_idex) fidex++;
                if (idex_c !== exp_idex_c) fidex_c++; 
                if (exmem !== exp_exmem) fexmem++;  
                if (memwb !== exp_memwb) fmemwb++;
                if (haz !== exp_haz) begin
                    fh++;
                    $display ("i = %0h", i);
                    if (haz.A !== exp_haz.A) begin
                        // Instruction A  
                        if (haz.A.ForwA !== exp_haz.A.ForwA) fhAA++; 
                        if (haz.A.ForwB !== exp_haz.A.ForwB) fhAB++; 
                        if (haz.A.stall !== exp_haz.A.stall) fhAS++;  
                        $display ("==================HAZARD A ===============================");
                        $display("A : op = %0h  |  exp_op = %0h ", id.A.op, exp_id.A.op);  
                        $display("A    : ForwA = %0h  |  ForwB = %0h  |  stall = %0h ", haz.A.ForwA, haz.A.ForwB, haz.A.stall);  
                        $display("exp_A: ForwA = %0h  |  ForwB = %0h  |  stall = %0h ", exp_haz.A.ForwA, exp_haz.A.ForwB, exp_haz.A.stall);     
                    end
                    
                    if (haz.B !== exp_haz.B) begin
                        // Instruction B
                        if (haz.B.ForwA !== exp_haz.B.ForwA) fhBA++; 
                        if (haz.B.ForwB !== exp_haz.B.ForwB) fhBB++;
                        if (haz.B.stall !== exp_haz.B.stall) fhBS++;
                        $display ("==================HAZARD B ===============================");
                        $display("B : op = %0h  |  exp_op = %0h ", id.B.op, exp_id.B.op);  
                        $display("B    : ForwA = %0h  |  ForwB = %0h  |  stall = %0h ", haz.B.ForwA, haz.B.ForwB, haz.B.stall);  
                        $display("exp_B: ForwA = %0h  |  ForwB = %0h  |  stall = %0h ", exp_haz.B.ForwA, exp_haz.B.ForwB, exp_haz.B.stall);  
                    end 
                 end
            end
        endtask 
    endclass
    
    HAZ_UNIT t;
    initial begin
        $display("Starting DECODER randomized testbench...");
        
        id.A    = '{op : 7'b0, rd: 5'b0, rs1: 5'b0, rs2: 5'b0};
        id.B    = id.A; idex = id; exp_id = id; exp_idex = idex;
        id_c.A  = '{mem:  NONE_c, wb:  NONE_c};
        id_c.B  = id_c.A; idex_c = id_c; exp_id_c = id_c; exp_idex_c = id_c;
        exmem.A = '{op : 7'b0, mem:  NONE_c, wb:  NONE_c, rd: 5'b0};
        exmem.B = exmem.A; memwb = exmem; exp_exmem = exmem; exp_memwb = memwb; 
        haz.A   = '{ForwA: NONE_h, ForwB: NONE_h, stall: NONE_h};
        haz.B   = haz.A; exp_haz = haz; i = 32'b0;
        
        repeat (total_tests) begin
            t = new();
            void'(t.randomize());
            t.apply_id(); 
            
            @(posedge clk); // Have to update on rising edge to ensure that we compare the correct values
            i++;
            
            idex.A.op       <= id.A.op;             exp_idex.A.op       <= exp_id.A.op;
            idex.A.rd       <= id.A.rd;             exp_idex.A.rd       <= exp_id.A.rd;
            idex.A.rs1      <= id.A.rs1;            exp_idex.A.rs1      <= exp_id.A.rs1;
            idex.A.rs2      <= id.A.rs2;            exp_idex.A.rs2      <= exp_id.A.rs2; 
            idex_c.A.mem    <= id_c.A.mem;          exp_idex_c.A.mem    <= exp_id_c.A.mem;
            idex_c.A.wb     <= id_c.A.wb;           exp_idex_c.A.wb     <= exp_id_c.A.wb;   
            
            idex.B.op       <= id.B.op;             exp_idex.B.op       <= exp_id.B.op;
            idex.B.rd       <= id.B.rd;             exp_idex.B.rd       <= exp_id.B.rd; 
            idex.B.rs1      <= id.B.rs1;            exp_idex.B.rs1      <= exp_id.B.rs1;
            idex.B.rs2      <= id.B.rs2;            exp_idex.B.rs2      <= exp_id.B.rs2; 
            idex_c.B.mem    <= id_c.B.mem;          exp_idex_c.B.mem    <= exp_id_c.B.mem;
            idex_c.B.wb     <= id_c.B.wb;           exp_idex_c.B.wb     <= exp_id_c.B.wb;
            
            exmem.A.op      <= idex.A.op;           exp_exmem.A.op      <= idex.A.op;  
            exmem.A.rd      <= idex.A.rd;           exp_exmem.A.rd      <= exp_idex.A.rd;
            exmem.A.mem     <= idex_c.A.mem;        exp_exmem.A.mem     <= exp_idex_c.A.mem;
            exmem.A.wb      <= idex_c.A.wb;         exp_exmem.A.wb      <= exp_idex_c.A.wb; 
            
            exmem.B.op      <= idex.B.op;           exp_exmem.B.op      <= exp_idex.B.op;
            exmem.B.rd      <= idex.B.rd;           exp_exmem.B.rd      <= exp_idex.B.rd;
            exmem.B.mem     <= idex_c.B.mem;        exp_exmem.B.mem     <= exp_idex_c.B.mem; 
            exmem.B.wb      <= idex_c.B.wb;         exp_exmem.B.wb      <= exp_idex_c.B.wb;  
            
            memwb           <= exmem;               exp_memwb           <= exp_exmem;  
            #1;  // Let hazard signals update
            t.check();
        end

        // If there's any error, "Case covered summary" will not be display until everything is resolve
        if (pass == total_tests) begin
            $display("All %0d tests passed!", pass);
            $display("Case Covered Summary!!!");
            $display ("================== HAZARD A ===============================");
            $display("AA: EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", afa_emA, afa_emB, afa_mwA, afa_mwB, apfnA);
            $display("AB: EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", afb_emA, afb_emB, afb_mwA, afb_mwB, apfnB);
            $display("AS: A_STALL  : %0d, B_STALL  : %0d, NONE : %0d,", asA, asB, asn);
            $display ("================== HAZARD B ===============================");
            $display("BA: FFA      : %0d, EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", bfa_ffa, bfa_emA, bfa_emB, bfa_mwA, bfa_mwB, bpfnA);
            $display("BB: FFA      : %0d, EX_MEM_A : %0d, EX_MEM_B : %0d, MEM_WB_A : %0d, MEM_WB_B : %0d, NONE : %0d,", bfb_ffa, bfb_emA, bfb_emB, bfb_mwA, bfb_mwB, bpfnB);
            $display("BS: SFA      : %0d, A_STALL  : %0d, B_STALL  : %0d, NONE : %0d,", bsAA, bsA, bsB, bsn);

        end else begin
            $display("%0d tests failed out of %0d", fail, total_tests);
            if (fid     !== 0) $display("id     != exp_id     : %0d",  fid);
            if (fid_c   !== 0) $display("id_c   != exp_id_c   : %0d",  fid_c);
            if (fidex   !== 0) $display("idex   != exp_idex   : %0d",  fidex);
            if (fidex_c !== 0) $display("idex_c != exp_idex_c : %0d",  fidex_c);
            if (fexmem  !== 0) $display("exmem  != exp_exmem  : %0d",  fexmem);
            if (fmemwb  !== 0) $display("memwb  != exp_memwb  : %0d",  fmemwb);
            if (fh   !== 0) begin 
                $display("haz != exp_haz  : %0d",  fh);
                if (fhAA   !== 0) $display("A: forwA  : %0d",  fhAA);
                if (fhAB   !== 0) $display("A: forwB  : %0d",  fhAB);
                if (fhAS   !== 0) $display("A: stall  : %0d",  fhAS);
                if (fhBA   !== 0) $display("B: forwA  : %0d",  fhBA);
                if (fhBB   !== 0) $display("B: forwB  : %0d",  fhBB);
                if (fhBS   !== 0) $display("B: stall  : %0d",  fhBS);
            end
        end
       $stop;
    end
endmodule
