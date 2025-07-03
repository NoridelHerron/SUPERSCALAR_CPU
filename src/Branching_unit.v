`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 11:29:43
// Design Name: 
// Module Name: Branching_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Branching_unit(
    input  wire [1:0]         is_branch,      // 1: branch, 0: no branch
    input  wire [2:0]         f3_way0,        // funct3 for way 0
    input  wire [2:0]         f3_way1,        // funct3 for way 1

    // ALU flags for way 0
    input  wire               flags0_zero,
    input  wire               flags0_negative,
    input  wire               flags0_overflow,
    input  wire               flags0_carry,

    // ALU flags for way 1
    input  wire               flags1_zero,
    input  wire               flags1_negative,
    input  wire               flags1_overflow,
    input  wire               flags1_carry,

    output reg  [1:0]         is_flush        // 1: flush, 0: no action
);

// funct3 opcodes
localparam [2:0]
    BEQ  = 3'b000,
    BNE  = 3'b001,
    BLT  = 3'b100,
    BGE  = 3'b101,
    BLTU = 3'b110,
    BGEU = 3'b111;

// Way 0
always @(*) begin
    if (is_branch[0]) begin
        case (f3_way0)
            BEQ:  is_flush[0] = flags0_zero;
            BNE:  is_flush[0] = ~flags0_zero;
            BLT:  is_flush[0] = flags0_negative ^ flags0_overflow;
            BGE:  is_flush[0] = ~(flags0_negative ^ flags0_overflow);
            BLTU: is_flush[0] = ~flags0_carry;
            BGEU: is_flush[0] =  flags0_carry;
            default: is_flush[0] = 1'b0;
        endcase
    end else begin
        is_flush[0] = 1'b0;
    end
end

// Way 1
always @(*) begin
    if (is_branch[1]) begin
        case (f3_way1)
            BEQ:  is_flush[1] = flags1_zero;
            BNE:  is_flush[1] = ~flags1_zero;
            BLT:  is_flush[1] = flags1_negative ^ flags1_overflow;
            BGE:  is_flush[1] = ~(flags1_negative ^ flags1_overflow);
            BLTU: is_flush[1] = ~flags1_carry;
            BGEU: is_flush[1] =  flags1_carry;
            default: is_flush[1] = 1'b0;
        endcase
    end else begin
        is_flush[1] = 1'b0;
    end
end

endmodule
