`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/18/2025 10:13:07 AM
// Design Name: Noridel Herron
// Module Name: EX_STAGE
// Project Name: Superscalar CPU
//////////////////////////////////////////////////////////////////////////////////

localparam F3_WIDTH       = 3;
localparam FOUR           = 4;
localparam FIVE           = 5;
localparam REG_ADDR_WIDTH = 5;
localparam F7_WIDTH       = 7;
localparam OPCODE_WIDTH   = 7;
localparam IMM12_WIDTH    = 12;
localparam IMM20_WIDTH    = 20;
localparam DATA_WIDTH     = 32;

module EX_STAGE(
    input  [DATA_WIDTH-1:0]   ex_mem_A,  
    input  [DATA_WIDTH-1:0]   ex_mem_B,
    input  [DATA_WIDTH-1:0]   mem_wb_A,
    input  [DATA_WIDTH-1:0]   mem_wb_B,
    input  [OPCODE_WIDTH-1:0] id_ex_op1, 
    input  [IMM12_WIDTH-1:0]  id_ex_imm12A,
    input  [IMM20_WIDTH-1:0]  id_ex_imm20A,
    input  [F3_WIDTH-1:0]     id_ex_f3_1,
    input  [F7_WIDTH-1:0]     id_ex_f7_1,
    input  [OPCODE_WIDTH-1:0] id_ex_op2,
    input  [IMM12_WIDTH-1:0]  id_ex_imm12B,
    input  [IMM20_WIDTH-1:0]  id_ex_imm20B,
    input  [F3_WIDTH-1:0]     id_ex_f3_2,
    input  [F7_WIDTH-1:0]     id_ex_f7_2,
    input  [DATA_WIDTH-1:0]   reg_1A,
    input  [DATA_WIDTH-1:0]   reg_1B,
    input  [DATA_WIDTH-1:0]   reg_2A,
    input  [DATA_WIDTH-1:0]   reg_2B,
    input  [FOUR-1:0]         forw_1A,
    input  [FOUR-1:0]         forw_1B,
    input  [FOUR-1:0]         stall_1,
    input  [FOUR-1:0]         is_hold_1,
    input  [FOUR-1:0]         forw_2A,
    input  [FOUR-1:0]         forw_2B,
    input  [FOUR-1:0]         stall_2,
    input  [FOUR-1:0]         is_hold_2,
    output [FIVE-1:0]         ALU_OP_A,
    output [DATA_WIDTH-1:0]   result_A,
    output                    Z_A,
    output                    V_A,
    output                    C_A,
    output                    N_A,
    output [FIVE-1:0]         ALU_OP_B,
    output [DATA_WIDTH-1:0]   result_B,
    output                    Z_B,
    output                    V_B,
    output                    C_B,
    output                    N_B
    );

    // Wires for operand forwarding unit outputs
    wire [DATA_WIDTH-1:0] operand_1A;
    wire [DATA_WIDTH-1:0] operand_1B;
    wire [DATA_WIDTH-1:0] storeVal_1;
    wire [FOUR-1:0]       is_valid;
    wire [DATA_WIDTH-1:0] operand_2A;
    wire [DATA_WIDTH-1:0] operand_2B;
    wire [DATA_WIDTH-1:0] storeVal_2;

    // Forwarding Unit Instance: calculates forwarding values for operands
    Forw_wrapper u_forw_wrapper (
        .A1_in(ex_mem_A),
        .A2_in(ex_mem_B),
        .B1_in(mem_wb_A),
        .B2_in(mem_wb_B),
        .op1(id_ex_op1),
        .imm12_1(id_ex_imm12A),
        .imm20_1(id_ex_imm20A),
        .op2(id_ex_op2),
        .imm12_2(id_ex_imm12B),
        .imm20_2(id_ex_imm20B),
        .C1_in(reg_1A),
        .C2_in(reg_1B),
        .C3_in(reg_2A),
        .C4_in(reg_2B),
        .forw1A(forw_1A),
        .forw1B(forw_1B),
        .stall1(stall_1),
        .is_hold1(is_hold_1),
        .forw2A(forw_2A),
        .forw2B(forw_2B),
        .stall2(stall_2),
        .is_hold2(is_hold_2),
        .D1A_out(operand_1A),
        .D1B_out(operand_1B),
        .D1S_out(storeVal_1),
        .is_valid(is_valid),
        .D2A_out(operand_2A),
        .D2B_out(operand_2B),
        .D2S_out(storeVal_2)
    );

    // Mux logic to select ALU2 inputs, either forwarded from ALU1 result or normal operand
    wire [DATA_WIDTH-1:0] temp_2A = (forw_2A == 4'h8) ? result_A : operand_2A;
    wire [DATA_WIDTH-1:0] temp_2B = (forw_2B == 4'h8) ? result_A : operand_2B;

    // ALU Wrapper Instances for dual-issue ALU processing
    ALU_wrapper u_alu_wrapper1 (
        .A(operand_1A),
        .B(operand_1B),
        .f3(id_ex_f3_1),
        .f7(id_ex_f7_1),
        .operation(ALU_OP_A),
        .result(result_A),
        .Z_flag(Z_A),
        .V_flag(V_A),
        .C_flag(C_A),
        .N_flag(N_A)
    );

    ALU_wrapper u_alu_wrapper2 (
        .A(temp_2A),
        .B(temp_2B),
        .f3(id_ex_f3_2),
        .f7(id_ex_f7_2),
        .operation(ALU_OP_B),
        .result(result_B),
        .Z_flag(Z_B),
        .V_flag(V_B),
        .C_flag(C_B),
        .N_flag(N_B)
    );

endmodule
