//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/18/2025 10:13:07 AM
// Design Name: Noridel Herron
// Module Name: EX_STAGE
// Project Name: Superscalar CPU
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import enum_helpers::*;
import struct_helpers::*;
import myFunct_gen::*;

module tb_ex;
    
    // Structured inputs
    haz_val_t haz;
    regs_t   regs;     // from ID_EX register (register values)
    ex_mem_t ex_mem;   // from EX_MEM reg
    mem_wb_t mem_wb;   // from MEM_WB reg
    id_ex_t  id_ex;    // from ID_EX reg (decoded values)

    // Structured outputs
    ex_mem_t ex_mem_out;
    alu_t    alu_out;

    // Instantiate the DUT (Device Under Test)
    EX dut (
        .ex_mem_A(ex_mem.A.data), .ex_mem_B(ex_mem.B.data),
        .mem_wb_A(mem_wb.A.data), .mem_wb_B(mem_wb.B.data),
        .id_ex_op1(id_ex.A.op), .id_ex_op2(id_ex.B.op),
        .id_ex_imm12A(id_ex.A.imm12), .id_ex_imm12B(id_ex.B.imm12),
        .id_ex_imm20A(id_ex.A.imm20), .id_ex_imm20B(id_ex.B.imm20),
        .id_ex_f3_1(id_ex.A.funct3), .id_ex_f3_2(id_ex.B.funct3),
        .id_ex_f7_1(id_ex.A.funct7), .id_ex_f7_2(id_ex.B.funct7),
        .reg_1A(regs.one.A), .reg_1B(regs.one.B),
        .reg_2A(regs.two.A), .reg_2B(regs.two.B),
        .forw_1A(haz.A.fA), .forw_1B(haz.A.fB), .stall_1(haz.A.st),
        .forw_2A(haz.B.fA), .forw_2B(haz.B.fB), .stall_2(haz.B.st),
        .operand_1A(ex_mem_out.A.operand.A), .operand_1B(ex_mem_out.A.operand.B),
        .temp_2A(ex_mem_out.B.operand.A), .temp_2B(ex_mem_out.B.operand.B),
        .storeVal_1(ex_mem_out.A.S_data), .storeVal_2(ex_mem_out.B.S_data),
        .result_A(ex_mem_out.A.data), .result_B(ex_mem_out.B.data),
        .Z_A(ex_mem_out.A.Z), .V_A(ex_mem_out.A.V), .C_A(ex_mem_out.A.C), .N_A(ex_mem_out.A.N),
        .Z_B(ex_mem_out.B.Z), .V_B(ex_mem_out.B.V), .C_B(ex_mem_out.B.C), .N_B(ex_mem_out.B.N),
        .ALU_OP_A(alu_out.opA), .ALU_OP_B(alu_out.opB)
    );

    // Assign ALU OP enum decoding and hazard struct conversion
    always_comb begin
        ex_mem_out.A.haz.forwA = slv_to_hazE(haz.A.fA);      
        ex_mem_out.A.haz.forwB = slv_to_hazE(haz.A.fB); 
        ex_mem_out.A.haz.stall = slv_to_hazE(haz.A.st); 
        ex_mem_out.B.haz.forwA = slv_to_hazE(haz.B.fA);
        ex_mem_out.B.haz.forwB = slv_to_hazE(haz.B.fB);
        ex_mem_out.B.haz.stall = slv_to_hazE(haz.B.st); 
        ex_mem_out.A.op        = slv_to_aluE(alu_out.opA);
        ex_mem_out.B.op        = slv_to_aluE(alu_out.opB);
        ex_mem_out.A.rd        = id_ex.A.rd;
        ex_mem_out.B.rd        = id_ex.B.rd;
        mem_wb.A.rd            = ex_mem_out.A.rd;
        mem_wb.B.rd            = ex_mem_out.B.rd;
    end

    // Random stimulus class instance
    class EXStageStimulus;
        rand ex_mem_t ex_mem;
        rand mem_wb_t mem_wb;
        rand id_ex_t  id_ex;
        rand regs_t   regs;
        rand haz_val_t haz;
    endclass

    EXStageStimulus stim;

    initial begin
        $display("Randomized test starting...");
        stim = new();

        repeat (1000) begin
            assert(stim.randomize());

            // Apply stimulus
            id_ex   = stim.id_ex;
            ex_mem  = stim.ex_mem;
            mem_wb  = stim.mem_wb;
            regs    = stim.regs;
            haz     = stim.haz;

            #10; // Wait time for DUT to process
        end

        $display("Finished 1000 randomized tests.");
        $finish;
    end

endmodule
