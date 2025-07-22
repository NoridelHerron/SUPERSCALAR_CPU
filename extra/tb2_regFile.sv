`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2025 18:36:42
// Design Name: 
// Module Name: tb_regfile_4r2w
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


module tb2_regFile();
    logic clk = 0;

    // DUT signals
    logic [4:0] rd1, rd2;
    logic [31:0] wb_data1, wb_data2;
    logic [3:0] wb_we1, wb_we2;
    logic [4:0] rs1, rs2, rs3, rs4;
    
    typedef struct packed {
        logic [31:0] A;
        logic [31:0] B;
    } REG_DATA_PER_s;

    typedef struct packed {
        REG_DATA_PER_s one;
        REG_DATA_PER_s two;
    } REG_DATAS_s;
    
    REG_DATAS_s reg_data;
    
    // Instantiate DUT
    RegFile_wrapper dut (
        .clk(clk),
        .rd1(rd1), .wb_data1(wb_data1), .wb_we1(wb_we1),
        .rd2(rd2), .wb_data2(wb_data2), .wb_we2(wb_we2),
        .rs1(rs1), .rs2(rs2), .rs3(rs3), .rs4(rs4),
        .reg_data(reg_data)
    );
    

    // Clock generation
    always #5 clk = ~clk;

    // Reference model
    logic [31:0] golden_regs[31:0];

    // Transaction class for stimulus
    class RegTest;
        rand bit [4:0] wr_idx1, wr_idx2;
        rand bit [31:0] wr_data1, wr_data2;
        rand bit [3:0] we1, we2;
        rand bit [4:0] rd_idx1, rd_idx2, rd_idx3, rd_idx4;

        constraint unique_addrs {
            wr_idx1 != 0;
            wr_idx2 != 0;
            wr_idx1 != wr_idx2;
        }
        
        constraint we_constraint {
        we1 inside {4'd2, 4'd11};
        we2 inside {4'd2, 4'd11};
    }

        function void apply();
            // Apply writes
            wb_we1 = we1;
            wb_we2 = we2;
            rd1 = wr_idx1;
            rd2 = wr_idx2;
            wb_data1 = wr_data1;
            wb_data2 = wr_data2;

            // Update reference model on posedge clk
            if (we1 == 4'd2 && wr_idx1 != 0)
                golden_regs[wr_idx1] = wr_data1;
            if (we2 == 4'd2 && wr_idx2 != 0 && !(we1 == 4'd2 && wr_idx1 == wr_idx2))
                golden_regs[wr_idx2] = wr_data2;

            // Apply reads
            rs1 = rd_idx1;
            rs2 = rd_idx2;
            rs3 = rd_idx3;
            rs4 = rd_idx4;
        endfunction

        task check();
            #1; // wait for read combinational output
            assert(reg_data.one.A === golden_regs[rd_idx1]) else $fatal("Mismatch rs1");
            assert(reg_data.one.B === golden_regs[rd_idx2]) else $fatal("Mismatch rs2");
            assert(reg_data.two.A === golden_regs[rd_idx3]) else $fatal("Mismatch rs3");
            assert(reg_data.two.B === golden_regs[rd_idx4]) else $fatal("Mismatch rs4");

        endtask
    endclass
RegTest txn;
    // Test logic
    initial begin
        $display("Starting SystemVerilog randomized testbench...");
        
        // Initialize signals to known values
        rd1 = 0;
        rd2 = 0;
        wb_data1 = 0;
        wb_data2 = 0;
        wb_we1 = 0;
        wb_we2 = 0;
        rs1 = 0;
        rs2 = 0;
        rs3 = 0;
        rs4 = 0;

        golden_regs = '{default:0};

       // RegTest txn;

        repeat (20000) begin
            txn = new();
            void'(txn.randomize());
            @(posedge clk);
            txn.apply();
            @(posedge clk);
            txn.check();
        end

        $display(" All 20000 tests passed.");
        $stop;
    end
endmodule