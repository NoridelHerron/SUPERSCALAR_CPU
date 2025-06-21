//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/19/2025 9:28:07 AM
// Design Name: Noridel Herron
// Module Name: struct_helpers
// Project Name: Superscalar CPU
// Helper for waveform debugging
//////////////////////////////////////////////////////////////////////////////////

package myFunct_gen;

    import struct_helpers::*;
    import enum_helpers::*;

    class DecoderGen;

        static function decoder_t get_decoded_val(real rand_real);
            decoder_t temp;

            // Default values
            temp = '{default: 0};

            // Choose op based on rand_real
            if      (rand_real < 0.02) temp.op = ECALL;
            else if (rand_real < 0.04) temp.op = U_AUIPC;
            else if (rand_real < 0.06) temp.op = U_LUI;
            else if (rand_real < 0.08) temp.op = JALR;
            else if (rand_real < 0.4 ) temp.op = LOAD;
            else if (rand_real < 0.5 ) temp.op = S_TYPE;
            else if (rand_real < 0.55) temp.op = JAL;
            else if (rand_real < 0.6 ) temp.op = B_TYPE;
            else if (rand_real < 0.9 ) temp.op = I_IMME;
            else                       temp.op = R_TYPE;

            // Convert float rs1/rs2/rd to 5-bit values
            temp.rs1 = $urandom_range(0, 31);  // You may use integer(rs1_r * 32.0) if you want deterministic mapping
            temp.rs2 = $urandom_range(0, 31);
            temp.rd  = $urandom_range(0, 31);

            temp.funct3 = $urandom_range(0, 7);
            temp.funct7 = $urandom_range(0, 127);
            temp.imm12  = 12'd0;
            temp.imm20  = 20'd0;

            // Adjust logic based on op
            unique case (temp.op)
                R_TYPE: begin
                    if (temp.funct3 == 3'b000 || temp.funct3 == 3'b101) begin
                        temp.funct7 = (rand_real > 0.5) ? 7'b0000000 : 7'b0100000;
                    end
                end

                I_IMME: begin
                    if (temp.funct3 == 3'b101) begin
                        temp.funct7 = (rand_real > 0.5) ? 7'b0000000 : 7'b0100000;
                    end
                    temp.imm12 = {temp.funct7, temp.rs2};
                end

                LOAD: begin
                    temp.funct3 = 3'b010; // lw
                    temp.imm12  = {temp.funct7, temp.rs2};
                end

                JALR, ECALL: begin
                    temp.imm12 = {temp.funct7, temp.rs2};
                end

                S_TYPE: begin
                    temp.imm12 = {temp.funct7, temp.rd};
                end

                B_TYPE: begin
                    logic [11:0] imm12_temp = {temp.funct7, temp.rd};
                    temp.imm12 = {imm12_temp[11], imm12_temp[0], imm12_temp[10:5], imm12_temp[4:1]};
                    if (temp.funct3 == 3'b010 || temp.funct3 == 3'b011) begin
                        temp.funct3 = (rand_real > 0.5) ? 3'b000 : 3'b001;
                    end
                end

                U_LUI, U_AUIPC: begin
                    temp.imm20 = {temp.funct7, temp.rs2, temp.rs1, temp.funct3};
                end

                JAL: begin
                    logic [19:0] imm20_temp = {temp.funct7, temp.rs2, temp.rs1, temp.funct3};
                    temp.imm20 = {imm20_temp[19], imm20_temp[7:0], imm20_temp[8], imm20_temp[18:9]};
                end

                default: begin
                    temp = '{default: 0};
                end
            endcase

            return temp;
        endfunction

    endclass

endpackage : myFunct_gen
