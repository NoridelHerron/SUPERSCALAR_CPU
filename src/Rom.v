// ========================================== 
// ROM Module for RISC-V Instruction Memory.
// Generates 2 instructions at a time on clock edge.
// Allowed Types: I-type Immediate, Load, JAL,  S-type,  B-type.
// ===============================================================

module rom (
    input  wire        clk,
    input  wire [9:0]  addr,    // PC >> 2 for word indexing
    output reg  [31:0] instr1,
    output reg  [31:0] instr2
);

    reg [31:0] rom [0:1023];
    reg [31:0] temp, temp2;
    reg [4:0] temp_rs1, temp_rs2, temp_rd;

    //===== RISC-V Opcodes (Only allowed types)=====
    localparam [6:0]
        OPCODE_I_IMM  = 7'b0010011,
        OPCODE_LOAD   = 7'b0000011,
        OPCODE_JAL    = 7'b1101111,
        OPCODE_S_TYPE = 7'b0100011,
        OPCODE_R_TYPE = 7'b0110011,
        OPCODE_B_TYPE = 7'b1100011;

    // ============= Function to generate the instructions ======================

    function [31:0] generate_instruction;
        input integer type_sel;
        reg [4:0]  rd, rs1, rs2;
        reg [2:0]  funct3;
        reg [6:0]  funct7;
        reg [11:0] imm12;
        reg [19:0] imm20;
        reg [31:0] instr;

        begin
            rd     = $urandom_range(0, 31);
            rs1    = $urandom_range(0, 31);
            rs2    = $urandom_range(0, 31);
            funct3 = $urandom_range(0, 7);
            funct7 = $urandom_range(0, 127);

            case (type_sel)

                //==== I-type Immediate ====
                0: begin
                    imm12 = $urandom_range(0, 4095); // 12-bit immediate
                    instr = {imm12, rs1, funct3, rd, OPCODE_I_IMM};
                end

                // ==== Load (e.g., LW) ====
                1: begin
                    funct3 = 3'b010; // Force LW
                    imm12  = $urandom_range(0, 4095);
                    instr  = {imm12, rs1, funct3, rd, OPCODE_LOAD};
                end

                // ==== JAL Logic ====
                2: begin
                    imm20 = $urandom_range(0, 1048575); // 20-bit signed immediate
                    instr = {
                        imm20[19],     // bit 31
                        imm20[9:0],    // bits 30:21
                        imm20[10],     // bit 20
                        imm20[18:11],  // bits 19:12
                        rd,            // bits 11:7
                        OPCODE_JAL     // bits 6:0
                    };
                end

                // ===== S-type logic (e.g., store) ===
                3: begin
                    imm12 = $urandom_range(0, 4095);
                    instr = {
                        imm12[11:5], rs2, rs1, funct3,
                        imm12[4:0], OPCODE_S_TYPE
                    };
                end

                //==== B-type logic (e.g., beq) ====
                4: begin
                    imm12 = $urandom_range(0, 4095);
                    instr = {
                        imm12[11], imm12[10:5], rs2, rs1, funct3,
                        imm12[4:1], imm12[0], OPCODE_B_TYPE
                    };
                end

                //==== R-type logic (e.g., add, sub, srl, sra) ====
                5: begin
                    if (funct3 == 3'b000 || funct3 == 3'b101) begin
                        funct7 = $urandom_range(0, 1) ? 7'd0 : 7'd32;  // ADD/SRL or SUB/SRA
                    end else begin
                        funct7 = $urandom_range(0, 127);              // other R-type
                    end
                    instr = {funct7, rs2, rs1, funct3, rd, OPCODE_R_TYPE};
                end

                //==== Default (NOP) ====
                default: instr = 32'h00000013;

            endcase

            generate_instruction = instr;
        end
    endfunction
   
    // ================= ROM and instruction Initializations ===================
    integer i, j, k, h = 0;
    initial begin
        
        instr1 = 32'h00000013;
        instr2 = 32'h00000013;
        temp   = 32'h00000013;
        temp2  = 32'h00000013;
        /*
        for (i = 0; i < 1024; i = i + 1) begin
            rom[i] = generate_instruction($urandom_range(0, 5)); // Include R-type
            $display("ROM[%0d] = %h", i, rom[i]);
        end
        */
        for (i = 0; i < 10; i = i + 1) begin
            temp  = $urandom_range(0, 127);
            rom[i] = { 7'b0, temp[4:0], 3'b010,  temp[4:0], OPCODE_I_IMM}; //  I_IMME
            $display("ROM[%0d] = %h", i, rom[i]);
        end
        
        for (i = 10; i < 20; i = i + 1) begin  //  Include S-type
            temp_rs2 = $urandom_range(0, 31);
            temp = rom[i - 10];
            rom[i] = { 7'b0, temp_rs2, temp[19:15], 3'b010, 5'b0, OPCODE_S_TYPE};
            $display("ROM[%0d] = %h", i, rom[i]);
        end
        
        for (i = 20; i < 50; i = i + 1) begin
            j = $urandom_range(0, 19);
            k = $urandom_range(0, 19);
            h = $urandom_range(0, 3);
            temp  = rom[j];
            temp2 = rom[k];
            if (k < 10 || j < 10) begin 
                case (h)
                   0 : begin temp_rs1 = temp[19:15]; temp_rs2 = temp2[19:15]; temp_rd = temp2[24:20]; end 
                   1 : begin temp_rs2 = temp[19:15]; temp_rs1 = temp2[19:15]; temp_rd = temp2[24:20]; end
                   2 : begin temp_rd = temp[19:15]; temp_rs2 = temp2[19:15]; temp_rs1 = temp2[24:20]; end  
                   3 : begin temp_rd = temp[19:15]; temp_rs1 = temp2[19:15]; temp_rs2 = temp2[24:20]; end  
                   default:;
                endcase
            end else begin
                case (h)
                   0 : begin temp_rs1 = temp[19:15]; temp_rs2 = temp2[19:15]; temp_rd = temp2[24:20]; end 
                   1 : begin temp_rs2 = temp2[24:20]; temp_rs1 = temp2[19:15]; temp_rd = temp[19:15]; end
                   2 : begin temp_rd = temp[19:15]; temp_rs2 = temp2[24:20]; temp_rs1 = temp2[24:20]; end  
                   3 : begin temp_rd = temp[19:15]; temp_rs1 = temp2[19:15]; temp_rs2 = temp2[24:20]; end  
                   default:;
                endcase
            end
            rom[i] = {7'b0, temp_rs2, temp_rs1, 3'b0, temp_rd, OPCODE_R_TYPE}; 
            $display("ROM[%0d] = %h", i, rom[i]);
        end
        
        for (i = 50; i < 1024; i = i + 1) begin
            rom[i] = 32'h00000013; // NOP
            $display("ROM[%0d] = %h", i, rom[i]);
        end
  
        
    end

    // ================= Output 2 Instructions =================

    always @(posedge clk) begin
        instr1 <= rom[addr];       // addr must be PC >> 2
        instr2 <= rom[addr + 1];   // fetch next word
       // $display("1 = %0h, 2 = %0h", instr1, instr2);
    end

endmodule
