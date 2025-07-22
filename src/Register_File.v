`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2025 18:18:44
// Design Name: 
// Module Name: Register_file
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


module Register_file(
    input clk,
//rd=write_address
//rs=read_address
//wb_we=write enable
//rs_data=read_outpot
//wb_data=write_input

    // Write Port 1
    input [4:0]  rd1,
    input [31:0] wb_data1,
    input [3:0]  wb_we1,

    // Write Port 2
    input [4:0]  rd2,
    input [31:0] wb_data2,
    input [3:0]  wb_we2,

    // Read Ports
    input [4:0] rs1, rs2, rs3, rs4,
    output [31:0] rs1_data, rs2_data, rs3_data, rs4_data
    );
    
    reg [31:0] regs [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    always @(posedge clk) begin
        
        // Write Port 1 (higher priority)
        if (wb_we1 == 4'd2 && rd1 != 5'd0)
            regs[rd1] <= wb_data1;

        // Write Port 2 (only if not same as rd1)
        if (wb_we2 == 4'd2 && rd2 != 5'd0 && !(wb_we1 == 4'd2 && rd1 == rd2))
            regs[rd2] <= wb_data2;

    end

    // Read logic (combinational)
    assign rs1_data = (rs1 == 0) ? 32'b0 : regs[rs1];
    assign rs2_data = (rs2 == 0) ? 32'b0 : regs[rs2];
    assign rs3_data = (rs3 == 0) ? 32'b0 : regs[rs3];
    assign rs4_data = (rs4 == 0) ? 32'b0 : regs[rs4];
endmodule