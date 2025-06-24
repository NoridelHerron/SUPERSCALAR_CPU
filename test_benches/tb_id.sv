
//////////////////////////////////////////////////////////////////////////////////
// Noridel Herron
// 6/24/2025
// tb for id_stage
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
import enum_helpers::*;
import struct_helpers::*;

module tb_id_stage;

    // Clock generation
    logic clk = 0;
    always #5 clk = ~clk;

    // DUT ports and model
    logic [31:0] golden_regs[31:0];

    id_ex_t   ID_EX;
    rd_ctrl_N_t EX_MEM, MEM_WB;
    mem_wb_per_t WB;
    haz_t haz;
    regs_t datas;

    // DUT instantiation
    ID_STAGE dut (
        .clk(clk),
        .instr1(instr1),
        .instr2(instr2),
        .ID_EX(ID_EX),
        .EX_MEM(EX_MEM),
        .MEM_WB(MEM_WB),
        .WB(WB),
        .haz(haz),
        .datas(datas)
    );

    // Stimulus class
    class IDTest;
        rand bit [31:0] instr1, instr2;
        rand bit [31:0] wb_data1, wb_data2;
        rand bit [4:0]  wb_rd1, wb_rd2;
        rand control_signal_t cntrl1, cntrl2;

        rand bit [4:0] rs1_idx, rs2_idx, rs3_idx, rs4_idx;

        constraint valid_rd {
            wb_rd1 inside {[1:31]};
            wb_rd2 inside {[1:31]};
            wb_rd1 != wb_rd2;
        }

        constraint ctrl_values {
            cntrl1 inside {MEM_READ, MEM_WRITE, NONE_c};
            cntrl2 inside {MEM_READ, MEM_WRITE, NONE_c};
        }

        function void apply();
            // Assign instructions (for now, keep it random - decoder must tolerate garbage)
            IF_ID.A.instr = instr1;
            IF_ID.B.instr = instr2;

            // Apply WB signals
            WB.A.data = wb_data1;
            WB.A.rd   = wb_rd1;
            WB.A.cntrl = cntrl1;

            WB.B.data = wb_data2;
            WB.B.rd   = wb_rd2;
            WB.B.cntrl = cntrl2;

            // Update golden model
            if (cntrl1 == REG_WRITE && wb_rd1 != 0)
                golden_regs[wb_rd1] = wb_data1;

            if (cntrl2 == REG_WRITE && wb_rd2 != 0 && !(wb_rd2 == wb_rd1 && cntrl1 == REG_WRITE))
                golden_regs[wb_rd2] = wb_data2;

            // Randomize register file read indexes
            IF_ID.A.rs1 = rs1_idx;
            IF_ID.A.rs2 = rs2_idx;
            IF_ID.B.rs1 = rs3_idx;
            IF_ID.B.rs2 = rs4_idx;
        endfunction

        task check();
            #1;
            assert(datas.one.A === golden_regs[rs1_idx]) else
                $fatal("Mismatch at rs1: expected %h, got %h", golden_regs[rs1_idx], datas.one.A);

            assert(datas.one.B === golden_regs[rs2_idx]) else
                $fatal("Mismatch at rs2: expected %h, got %h", golden_regs[rs2_idx], datas.one.B);

            assert(datas.two.A === golden_regs[rs3_idx]) else
                $fatal("Mismatch at rs3: expected %h, got %h", golden_regs[rs3_idx], datas.two.A);

            assert(datas.two.B === golden_regs[rs4_idx]) else
                $fatal("Mismatch at rs4: expected %h, got %h", golden_regs[rs4_idx], datas.two.B);
        endtask
    endclass

    IDTest txn;

    // Test sequence
    initial begin
        $display("Starting ID_STAGE randomized testbench...");
        
        golden_regs = '{default:0};

        IF_ID.A.pc = 32'd0;
        IF_ID.B.pc = 32'd4;
        ID_EX = '0;
        EX_MEM = '0;
        MEM_WB = '0;
        WB = '0;

        repeat (20000) begin
            txn = new();
            void'(txn.randomize());
            @(posedge clk);
            txn.apply();
            @(posedge clk);
            txn.check();
        end

        $display("All 20,000 tests passed.");
        $stop;
    end

endmodule
