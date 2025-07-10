// Noridel Herron
// 7/8/2025
// Alu test bench
`timescale 1ns / 1ps

import enum_helpers::*;
import InstrGenPkg::*;

module alu_tb();
    logic clk = 0;
    always #5 clk = ~clk; // Clock: 10ns period
 
    localparam logic [2:0] FUNC3_ADD_SUB = 3'b000;
    localparam logic [2:0] FUNC3_SLL     = 3'b001;
    localparam logic [2:0] FUNC3_SLT     = 3'b010;
    localparam logic [2:0] FUNC3_SLTU    = 3'b011;
    localparam logic [2:0] FUNC3_XOR     = 3'b100;
    localparam logic [2:0] FUNC3_SRL_SRA = 3'b101;
    localparam logic [2:0] FUNC3_OR      = 3'b110;
    localparam logic [2:0] FUNC3_AND     = 3'b111;
    
    typedef struct packed {
        logic [31:0] A;
        logic [31:0] B;
        logic [2:0]  f3;
        logic [6:0]  f7;
    } alu_in;
    
    typedef struct packed {
        alu_op_t     op;
        logic [31:0] result;
        alu_e Z, V, C, N;
    } alu_out;
    
    typedef struct packed {
        logic [3:0]  op;
        logic [31:0] result;
        logic Z, V, C, N;
    } alu_act_out;
    
    alu_in      actual_in, expected_in;
    alu_act_out temp; 
    alu_out     actual_out, expected_out;

    // Instantiate DUT
    ALU_wrapper dut (
        .A(actual_in.A),
        .B(actual_in.B),
        .f3(actual_in.f3),
        .f7(actual_in.f7),
        // outputs
        .operation(temp.op),
        .result(temp.result),
        .Z_flag(temp.Z),
        .V_flag(temp.V),
        .C_flag(temp.C),
        .N_flag(temp.N)
    );
    
    int total_tests = 100000;
    // Keep track all the test and make sure it covers all the cases
    int pass = 0, fail = 0, invalid_cases = 0;
    int p0 = 0, p1 = 0, p2 = 0, p3 = 0, p4 = 0, p5 = 0, p6 = 0, p7 = 0;
    int p0a = 0, p0s = 0, p5a = 0, p5l = 0;
    // Help narrow down the bugs
    int fA = 0, fB = 0, ff3 = 0, ff7 = 0;
    int f0 = 0, f1 = 0, f2 = 0, f_3 = 0, f4 = 0, f5 = 0, f6 = 0, f_7 = 0;
    int fr = 0, fz = 0, fv = 0, fn = 0, fc = 0, f0a = 0, f0s = 0, f5a = 0, f5l = 0;
    
    class Alu_test;
        rand bit [31:0] rand_A,  rand_B;
        rand bit [2:0]  rand_f3; 
        rand bit [6:0]  rand_f7;
        
        // To check all the invalid cases, remove or comment the f7_condition and run simulation
        // You will see that it will pass any test cases
        constraint f7_condition {
            if (rand_f3 == 3'b000 || rand_f3 == 3'b101) {
                rand_f7 inside {7'd0, 7'd32};
            } else {
                rand_f7 == 7'd0;
            }
        }
    
        function void apply_inputs();
                actual_in.A  = rand_A;
                actual_in.B  = rand_B;
                actual_in.f3 = rand_f3;
                actual_in.f7 = rand_f7;
                
                expected_in.A  = rand_A;
                expected_in.B  = rand_B;
                expected_in.f3 = rand_f3;
                expected_in.f7 = rand_f7;
        endfunction
        
        function void transfer_outputs();
                actual_out.result = temp.result;
                actual_out.op     = encode_op_sig(temp.op);
                // Z flag
                if (temp.Z == 1'b1) begin
                    actual_out.Z = Z;
                end else begin
                    actual_out.Z = NONE_f;
                end
                // V flag
                if (temp.V == 1'b1) begin
                    actual_out.V = V;
                end else begin
                    actual_out.V = NONE_f;
                end
                // C flag
                if (temp.C == 1'b1) begin
                    actual_out.C = Cf;
                end else begin
                    actual_out.C = NONE_f;
                end
                // N flag
                if (temp.N == 1'b1) begin
                    actual_out.N = N;
                end else begin
                    actual_out.N = NONE_f;
                end        
        endfunction
        
        task check();
            #1; // wait for read combinational output
            
            expected_out.C = NONE_f;
            expected_out.V = NONE_f; 
            
            case (expected_in.f3)
                FUNC3_ADD_SUB: begin // ADD/SUB
                    if (expected_in.f7 == 7'd0) begin
                        expected_out.result = expected_in.A + expected_in.B;
                        expected_out.op     = ALU_ADD;   
                        
                        if (expected_out.result < expected_in.A || expected_out.result < expected_in.B)  begin
                            expected_out.C = Cf;
                        end else begin
                            expected_out.C = NONE_f;
                        end
            
                        if ((expected_in.A[31] == expected_in.B[31]) && 
                            (expected_out.result[31] != expected_in.A[31])) begin
                            expected_out.V = V;
                        end else begin
                            expected_out.V = NONE_f;
                        end
                        
                    end else begin 
                        if (expected_in.f7 == 7'd32) begin  
                            expected_out.result = expected_in.A - expected_in.B;
                            expected_out.op     = ALU_SUB; 
                            if (expected_in.A >= expected_in.B) begin
                                expected_out.C = Cf;
                            end else begin
                                expected_out.C = NONE_f;
                            end
                    
                            if ((expected_in.A[31] != expected_in.B[31]) && 
                                (expected_out.result[31] != expected_in.A[31])) begin
                                expected_out.V = V;
                            end else begin
                                expected_out.V = NONE_f;
                            end   
                        end else begin 
                            expected_out = '{ op : NONE, result : 32'b0, Z : NONE_f, N : NONE_f, C : NONE_f, V : NONE_f };
                        end
                    end
                end
            
                FUNC3_SLL: begin // SLL
                    expected_out.result = expected_in.A << expected_in.B[4:0];
                    expected_out.op     = ALU_SLL;
                end
            
                FUNC3_SLT: begin // SLT
                    if ($signed(expected_in.A) < $signed(expected_in.B)) begin
                        expected_out.result = 32'b1;  
                    end else begin
                        expected_out.result = 32'b0;
                    end
                    expected_out.op = ALU_SLT;
                end
            
                FUNC3_SLTU: begin // SLTU
                    if (expected_in.A < expected_in.B) begin
                        expected_out.result = 32'b1;  
                    end else begin
                        expected_out.result = 32'b0;
                    end
                    expected_out.op = ALU_SLTU;
                end
            
                FUNC3_XOR: begin // XOR
                    expected_out.result = expected_in.A ^ expected_in.B;
                    expected_out.op     = ALU_XOR;
                end
            
                FUNC3_SRL_SRA: begin 
                    if (expected_in.f7 == 7'd0) begin
                        expected_out.result = expected_in.A >> expected_in.B[4:0];
                        expected_out.op     = ALU_SRL;
                    end else begin
                        if (expected_in.f7 == 7'd32) begin  
                            expected_out.result = $signed(expected_in.A) >>> expected_in.B[4:0];
                            expected_out.op     = ALU_SRA;
                        end else begin
                            expected_out = '{ op : NONE, result : 32'b0, Z : NONE_f, N : NONE_f, C : NONE_f, V : NONE_f };
                        end
                    end
                end
            
                FUNC3_OR: begin 
                    expected_out.result = expected_in.A | expected_in.B; 
                    expected_out.op     = ALU_OR; 
                end
                
                FUNC3_AND: begin 
                    expected_out.result = expected_in.A & expected_in.B; 
                    expected_out.op     = ALU_AND; 
                end
            
                default: expected_out = '{ op : NONE, result : 32'b0, Z : NONE_f, N : NONE_f, C : NONE_f, V : NONE_f }; 
            endcase 
            
            // Check if result = 0
            if (expected_out.result == 32'b0) begin
                expected_out.Z = Z;
            end else begin
                expected_out.Z = NONE_f;
            end
            
            // Check if result is negative
            if (expected_out.result[31] == 1'b1) begin
                expected_out.N = N;
            end else begin
                expected_out.N = NONE_f;
            end  
    
            if ((actual_in === expected_in) && (actual_out === expected_out)) begin pass++;
                if (expected_out.op == NONE) begin
                    invalid_cases++;
                end else begin
                    case (expected_in.f3)
                        FUNC3_ADD_SUB: begin f0++; 
                            if (expected_in.f7 === 7'b0) begin p0a++; 
                            end else begin p0s++; 
                            end     
                        end
                        FUNC3_SLL:     begin p1++; end
                        FUNC3_SLT:     begin p2++; end
                        FUNC3_SLTU:    begin p3++; end
                        FUNC3_XOR:     begin p4++; end
                        FUNC3_SRL_SRA: begin p5++; 
                            if (expected_in.f7 === 7'b0) begin p5l++; 
                            end else begin p5a++; 
                            end     
                        end
                        FUNC3_OR:      begin p6++; end 
                        FUNC3_AND:     begin p7++; end 
                    endcase
               end
            end else begin fail++;
                
                if (actual_in.A !== expected_in.A)               fA++;
                if (actual_in.B !== expected_in.B)               fB++;
                if (actual_in.f3 !== expected_in.f3)             ff3++;
                if (actual_in.f7 !== expected_in.f7)             ff7++;
                
                if (actual_out !== expected_out) begin
                    case (actual_in.f3)
                        FUNC3_ADD_SUB: begin f0++; 
                            if (actual_in.f7 === 7'b0) begin f0a++; 
                            end else begin f0s++; 
                            end     
                        end
                        FUNC3_SLL:     begin f1++; end
                        FUNC3_SLT:     begin f2++; end
                        FUNC3_SLTU:    begin f_3++; end
                        FUNC3_XOR:     begin f4++; end
                        FUNC3_SRL_SRA: begin f5++; 
                            if (actual_in.f7 === 7'b0) begin f5l++; 
                            end else begin f5a++; 
                            end     
                        end
                        FUNC3_OR:      begin f6++; end 
                        FUNC3_AND:     begin f_7++; end 
                    endcase
                    if (actual_out.result !== expected_out.result) fr++;
                    if (actual_out.Z !== expected_out.Z)           fz++;
                    if (actual_out.V !== expected_out.V)           fv++;
                    if (actual_out.C !== expected_out.C)           fc++;
                    if (actual_out.N !== expected_out.N)           fn++;
                end
            end
        endtask
        
    endclass
    // Test variables
    Alu_test t;

    initial begin
        $display("Starting ALU randomized testbench...");
        
        actual_in    = '{ A : 32'b0, B : 32'b0, f3 : 3'b0, f7 : 7'b0};
        expected_in  = '{ A : 32'b0, B : 32'b0, f3 : 3'b0, f7 : 7'b0};
        temp         = '{ op : 4'ha, result : 32'b0, Z : 3'b100, N : 3'b100, C : 3'b100, V : 3'b100 };
        actual_out   = '{ op : NONE, result : 32'b0, Z : NONE_f, N : NONE_f, C : NONE_f, V : NONE_f };
        expected_out = '{ op : NONE, result : 32'b0, Z : NONE_f, N : NONE_f, C : NONE_f, V : NONE_f };
        
        repeat (total_tests) begin
            t = new();
            void'(t.randomize());
            @(posedge clk);
            t.apply_inputs();  
            @(posedge clk);
            t.transfer_outputs();
            t.check();
        end

        // If there's any error, "Case covered summary" will not be display until everything is resolve
        if (pass == total_tests) begin
            $display("All %0d tests passed!", pass);
            $display("Case Covered Summary!!!");
            $display("ADD  : %0d ", p0a);
            $display("SUB  : %0d ", p0s);
            $display("SLL  : %0d ", p1);
            $display("SLT  : %0d ", p2);
            $display("SLTU : %0d ", p3);
            $display("XOR  : %0d ", p4);
            $display("SRL  : %0d ", p5l);
            $display("SRA  : %0d ", p5a);
            $display("OR   : %0d ", p6);
            $display("AND  : %0d ", p7);
            $display("INV  : %0d ", invalid_cases);
        
        end else begin
            $display("%0d tests failed out of %0d", fail, total_tests);
            if (fA  !== 0) $display("A      : %0d", fA);
            if (fB  !== 0) $display("B      : %0d", fB);
            if (ff3 !== 0) $display("F3     : %0d", ff3);
            if (ff7 !== 0) $display("F7     : %0d", ff7);
            if (f0a !== 0) $display("ADD    : %0d ", f0a);
            if (f0s !== 0) $display("SUB    : %0d ", f0s);
            if (f1  !== 0) $display("SLL    : %0d ", f1);
            if (f2  !== 0) $display("SLT    : %0d ", f2);
            if (f_3 !== 0) $display("SLTU   : %0d ", f_3);
            if (f4  !== 0) $display("XOR    : %0d ", f4);
            if (f5l !== 0) $display("SRL    : %0d ", f5l);
            if (f5a !== 0) $display("SRA    : %0d ", f5a);
            if (f6  !== 0) $display("OR     : %0d ", f6);
            if (f_7 !== 0) $display("AND    : %0d ", f_7);
            if (fr  !== 0) $display("RESULT : %0d ", fr);
            if (fz  !== 0) $display("Z      : %0d ", fz);
            if (fv  !== 0) $display("V      : %0d ", fv);
            if (fn  !== 0) $display("N      : %0d ", fn);
            if (fc  !== 0) $display("C      : %0d ", fc);
        end
       $stop;
    end

endmodule
