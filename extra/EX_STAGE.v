`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/18/2025 10:13:07 AM
// Design Name: Noridel Herron
// Module Name: EX_STAGE
// Project Name: Superscalar CPU
//////////////////////////////////////////////////////////////////////////////////
module EX(
    input  [31:0] ex_mem_A, ex_mem_B,    
    input  [31:0] mem_wb_A, mem_wb_B,
    input  [6:0] id_ex_op1, id_ex_op2, 
    input  [11:0] id_ex_imm12A, id_ex_imm12B,
    input  [19:0] id_ex_imm20A, id_ex_imm20B,
    input  [2:0]  id_ex_f3_1, id_ex_f3_2,
    input  [6:0]  id_ex_f7_1, id_ex_f7_2,
    input  [31:0] reg_1A, reg_1B, reg_2A,  reg_2B,
    input  [3:0]  forw_1A, forw_1B, stall_1,    
    input  [3:0]  forw_2A, forw_2B, stall_2,
    output [31:0] operand_1A, operand_1B,
    output [31:0] temp_2A, temp_2B,  
    output [31:0] storeVal_1, storeVal_2,
    output [31:0] result_A, result_B,
    output        Z_A, V_A, C_A, N_A,
    output        Z_B, V_B, C_B, N_B,
    output [4:0]  ALU_OP_A, ALU_OP_B                        
    );

    localparam FOUR           = 4;
    localparam DATA_WIDTH     = 32;
    
    // Wires for operand forwarding unit outputs
    wire [DATA_WIDTH-1:0] operand_2A, operand_2B;
    
    // Forwarding Unit Instance: calculates forwarding values for operands
    Forw_wrapper u_forw_wrapper (
        // inputs
        .A1_in(ex_mem_A), .A2_in(ex_mem_B),   
        .B1_in(mem_wb_A), .B2_in(mem_wb_B),
        .op1(id_ex_op1),  .imm12_1(id_ex_imm12A), .imm20_1(id_ex_imm20A),
        .op2(id_ex_op2),  .imm12_2(id_ex_imm12B), .imm20_2(id_ex_imm20B),
        .C1_in(reg_1A),   .C2_in(reg_1B), .C3_in(reg_2A), .C4_in(reg_2B),
        .forw1A(forw_1A), .forw1B(forw_1B), .stall1(stall_1),
        .forw2A(forw_2A), .forw2B(forw_2B), .stall2(stall_2),
        // outputs
        .D1A_out(operand_1A), .D1B_out(operand_1B), .D1S_out(storeVal_1),
        .D2A_out(operand_2A), .D2B_out(operand_2B), .D2S_out(storeVal_2)
    );

    // Mux logic to select ALU2 inputs, either forwarded from ALU1 result or normal operand
    assign temp_2A = (forw_2A == 4'h8) ? result_A : operand_2A;
    assign temp_2B = (forw_2B == 4'h8) ? result_A : operand_2B;

    // ALU Wrapper Instances for dual-issue ALU processing
    ALU_wrapper u_alu_wrapper1 (
        // inputs
        .A(operand_1A),
        .B(operand_1B),
        .f3(id_ex_f3_1),
        .f7(id_ex_f7_1),
        // outputs
        .operation(ALU_OP_A),
        .result(result_A),
        .Z_flag(Z_A),
        .V_flag(V_A),
        .C_flag(C_A),
        .N_flag(N_A)
    );

    ALU_wrapper u_alu_wrapper2 (
        // inputs
        .A(temp_2A),
        .B(temp_2B),
        .f3(id_ex_f3_2),
        .f7(id_ex_f7_2),
        // outputs
        .operation(ALU_OP_B),
        .result(result_B),
        .Z_flag(Z_B),
        .V_flag(V_B),
        .C_flag(C_B),
        .N_flag(N_B)
    );

endmodule
