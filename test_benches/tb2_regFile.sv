/////////////////////////////////
// Noridel Herron
// 6/22/2025
// Register File wrapper Testbench
/////////////////////////////////
`timescale 1ns / 1ps

module tb2_regFile;

    logic clk = 0;
    always #5 clk = ~clk;

    // Match CONTROL_SIG enum from VHDL
    typedef enum logic [3:0] {
        MEM_READ  = 4'd0,
        MEM_WRITE = 4'd1,
        REG_WRITE = 4'd2,
        MEM_REG   = 4'd3,
        ALU_REG   = 4'd4,
        BRANCH    = 4'd5,
        JUMP      = 4'd6,
        RS2       = 4'd7,
        IMM       = 4'd8,
        VALID     = 4'd9,
        INVALID   = 4'd10,
        NONE_c    = 4'd11
    } CONTROL_SIG;

    typedef struct packed {
        logic [31:0] data;
        logic [4:0]  rd;  
        CONTROL_SIG  we; // Enum for write enable
    } WritePort;

    typedef struct packed {
        WritePort A;
        WritePort B;
    } WB_CONTENT_N_INSTR;
    
    typedef struct packed {
        logic [31:0] A;
        logic [31:0] B;
    } data_per_instr;
    
    typedef struct packed {
        data_per_instr one;
        data_per_instr two;
    } data_N;

    WB_CONTENT_N_INSTR WB;
    data_N reg_data;
    logic [4:0] rs1, rs2, rs3, rs4;

    // Instantiate your VHDL wrapper module
    RegFile_wrapper dut (
        .clk(clk),
        .WB(WB),
        .rs1(rs1),
        .rs2(rs2),
        .rs3(rs3),
        .rs4(rs4),
        .reg_data(reg_data) 
    );

    // Golden reference model for register contents
    logic [31:0] golden_regs[31:0];

    class RegTest;
        rand bit [4:0] wr_idx1, wr_idx2;
        rand bit [31:0] wr_data1, wr_data2;
        rand CONTROL_SIG we1, we2;  // Enum type for we signals
        rand bit [4:0] rd_idx1, rd_idx2, rd_idx3, rd_idx4;

        constraint unique_addrs {
            wr_idx1 != 0;
            wr_idx2 != 0;
            wr_idx1 != wr_idx2;
        }
        
        // Limit we1 and we2 to either REG_WRITE or NONE_c only
        constraint we_values_limited {
            we1 inside {REG_WRITE, NONE_c};
            we2 inside {REG_WRITE, NONE_c};
        }

        function void apply();
            WB.A.rd   = wr_idx1;
            WB.A.data = wr_data1;
            WB.A.we   = we1;

            WB.B.rd   = wr_idx2;
            WB.B.data = wr_data2;
            WB.B.we   = we2;

            // Update golden_regs according to write priority rules
            if (we1 == REG_WRITE && wr_idx1 != 0)
                golden_regs[wr_idx1] = wr_data1;
            if (we2 == REG_WRITE && wr_idx2 != 0 && !(we1 == REG_WRITE && wr_idx1 == wr_idx2))
                golden_regs[wr_idx2] = wr_data2;

            rs1 = rd_idx1;
            rs2 = rd_idx2;
            rs3 = rd_idx3;
            rs4 = rd_idx4;
        endfunction

        task check();
            #1; // Wait for outputs to settle
            if (reg_data.one.A !== golden_regs[rd_idx1])
                $fatal("Mismatch rs1: got %h, expected %h", reg_data.one.A, golden_regs[rd_idx1]);
            if (reg_data.one.B !== golden_regs[rd_idx2])
                $fatal("Mismatch rs2: got %h, expected %h", reg_data.one.B, golden_regs[rd_idx2]);
            if (reg_data.two.A !== golden_regs[rd_idx3])
                $fatal("Mismatch rs3: got %h, expected %h", reg_data.two.A, golden_regs[rd_idx3]);
            if (reg_data.two.B !== golden_regs[rd_idx4])
                $fatal("Mismatch rs4: got %h, expected %h", reg_data.two.B, golden_regs[rd_idx4]);
        endtask
    endclass

    RegTest txn;

    initial begin
        $display("Starting SV testbench for VHDL RegFile_wrapper...");

        // Initialize inputs and golden reference
        WB.A.rd = 0; WB.B.rd = 0;
        WB.A.data = 0; WB.B.data = 0;
        WB.A.we = NONE_c; WB.B.we = NONE_c;
        rs1 = 0; rs2 = 0; rs3 = 0; rs4 = 0;
        golden_regs = '{default:0};

        // Run randomized tests
        repeat (20000) begin
            txn = new();
            void'(txn.randomize());
            @(posedge clk);
            txn.apply();
            @(posedge clk);
            txn.check();
        end

        $display("All 20000 tests passed.");
        $stop;
    end

endmodule
