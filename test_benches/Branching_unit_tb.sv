`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2025 16:28:04
// Design Name: 
// Module Name: Branching_tb
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


class Stimulus;
  rand bit [1:0] is_branch;
  rand bit [2:0] f3_way0, f3_way1;
  rand bit flags0_zero, flags0_negative, flags0_overflow, flags0_carry;
  rand bit flags1_zero, flags1_negative, flags1_overflow, flags1_carry;

  constraint c_f3_valid {
    f3_way0 inside {[0:7]};
    f3_way1 inside {[0:7]};
  }
endclass
  Stimulus stim;
module Branching_tb;
  // DUT interface signals
  logic [1:0] is_branch;
  logic [2:0] f3_way0, f3_way1;
  logic flags0_zero, flags0_negative, flags0_overflow, flags0_carry;
  logic flags1_zero, flags1_negative, flags1_overflow, flags1_carry;
  logic [1:0] is_flush;
  // Instantiate DUT
  Branching_unit dut (
    .is_branch(is_branch),
    .f3_way0(f3_way0),
    .f3_way1(f3_way1),
    .flags0_zero(flags0_zero),
    .flags0_negative(flags0_negative),
    .flags0_overflow(flags0_overflow),
    .flags0_carry(flags0_carry),
    .flags1_zero(flags1_zero),
    .flags1_negative(flags1_negative),
    .flags1_overflow(flags1_overflow),
    .flags1_carry(flags1_carry),
    .is_flush(is_flush)
  );

  // Branch funct3 opcodes
  localparam [2:0]
    BEQ  = 3'b000,
    BNE  = 3'b001,
    BLT  = 3'b100,
    BGE  = 3'b101,
    BLTU = 3'b110,
    BGEU = 3'b111;

  int errors = 0;

  function logic compute_flush(
    input bit branch,
    input bit [2:0] f3,
    input bit z, n, o, c
  );
    if (!branch) return 0;
    case (f3)
      BEQ:  return z;
      BNE:  return ~z;
      BLT:  return n ^ o;
      BGE:  return ~(n ^ o);
      BLTU: return ~c;
      BGEU: return c;
      default: return 0;
    endcase
  endfunction

  initial begin
    stim = new();

    for (int i = 0; i < 20000; i++) begin
      assert(stim.randomize());

      // Apply stimuli
      is_branch       = stim.is_branch;
      f3_way0         = stim.f3_way0;
      f3_way1         = stim.f3_way1;
      flags0_zero     = stim.flags0_zero;
      flags0_negative = stim.flags0_negative;
      flags0_overflow = stim.flags0_overflow;
      flags0_carry    = stim.flags0_carry;
      flags1_zero     = stim.flags1_zero;
      flags1_negative = stim.flags1_negative;
      flags1_overflow = stim.flags1_overflow;
      flags1_carry    = stim.flags1_carry;

      #1;

      // Assertions
      assert(is_flush[0] === compute_flush(is_branch[0], f3_way0, flags0_zero, flags0_negative, flags0_overflow, flags0_carry))
        else begin
          $display("[ASSERT FAIL] way0: is_flush=%b, expected=%b, f3=%b, flags={z=%b,n=%b,o=%b,c=%b}",
                   is_flush[0], compute_flush(is_branch[0], f3_way0, flags0_zero, flags0_negative, flags0_overflow, flags0_carry),
                   f3_way0, flags0_zero, flags0_negative, flags0_overflow, flags0_carry);
          errors++;
        end

      assert(is_flush[1] === compute_flush(is_branch[1], f3_way1, flags1_zero, flags1_negative, flags1_overflow, flags1_carry))
        else begin
          $display("[ASSERT FAIL] way1: is_flush=%b, expected=%b, f3=%b, flags={z=%b,n=%b,o=%b,c=%b}",
                   is_flush[1], compute_flush(is_branch[1], f3_way1, flags1_zero, flags1_negative, flags1_overflow, flags1_carry),
                   f3_way1, flags1_zero, flags1_negative, flags1_overflow, flags1_carry);
          errors++;
        end
    end

    $display("\nRandomized testing completed with %0d error(s) out of 20000 cases.", errors);
    if (errors == 0) $display("All assertions passed!\n");
    $finish;
  end
endmodule

