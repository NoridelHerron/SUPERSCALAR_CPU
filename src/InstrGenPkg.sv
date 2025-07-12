

package InstrGenPkg;

    localparam logic [6:0] LOAD     = 7'b0000011;
    localparam logic [6:0] S_TYPE   = 7'b0100011;
    localparam logic [6:0] JAL      = 7'b1101111;
    localparam logic [6:0] B_TYPE   = 7'b1100011;
    localparam logic [6:0] I_IMME   = 7'b0010011;
    localparam logic [6:0] R_TYPE   = 7'b0110011;
    localparam logic [6:0] ECALL    = 7'b1110111;
    localparam logic [6:0] JALR     = 7'b1100111;
    localparam logic [6:0] U_LUI    = 7'b0110111;
    localparam logic [6:0] U_AUIPC  = 7'b0010111;
    localparam logic [6:0] EBREAK   = 7'b1110011;

    //import enum_helpers::*;
    import struct_helpers::*;
    import enum_helpers::*;

    // Function to generate a random instruction word
    function automatic logic [31:0] gen_random_instr(int seed);
        real rand_real;
        logic [6:0] op;
        logic [4:0] rd, rs1, rs2;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [31:0] instr;

        // Generate uniform random number between 0 and 1
        rand_real = $urandom_range(0, 10000) / 10000.0;

        // Select opcode based on probability ranges
        if (rand_real < 0.20)
            op = LOAD;
        else if (rand_real < 0.4)
            op = S_TYPE;
        else if (rand_real < 0.6)
            op = JAL;
        else if (rand_real < 0.8)
            op = B_TYPE;
        else if (rand_real < 0.9)
            op = I_IMME;
        else
            op = R_TYPE;

        // Generate random registers and function fields
        rd     = $urandom_range(1,31);
        rs1    = $urandom_range(0,31);
        rs2    = $urandom_range(0,31);
        funct3 = $urandom_range(0,7);
        funct7 = $urandom_range(0,127);
        
        if (op == R_TYPE) begin
            if (funct3 == 3'd0 || funct3 == 3'd5) begin
                // restrict funct7 to either 0 or 32
                if ($urandom_range(0,1) == 0)
                    funct7 = 7'd0;
                else
                    funct7 = 7'd32;
                end
            end 
        else if (op == I_IMME) begin
            if (funct3 == 3'd5) begin
                // restrict funct7 to 0 or 32 as well
                if ($urandom_range(0,1) == 0)
                    funct7 = 7'd0;
                else
                    funct7 = 7'd32;
            end
        end 

        // Build instruction: default R-type format
        instr = {funct7, rs2, rs1, funct3, rd, op};

        return instr;
    endfunction
    
    // Function that decode instruction
    function automatic decoder_t decode(input logic [31:0] instr);
        decoder_t result = '0;
        decoder_t temp   = '0;
        logic [11:0] imm12 = '0; 
        logic [19:0] imm20 = '0;
    
        temp.op      = instr[6:0];
        temp.rd      = instr[11:7];
        temp.funct3  = instr[14:12];
        temp.rs1     = instr[19:15];
        temp.rs2     = instr[24:20];
        temp.funct7  = instr[31:25];
        temp.imm12   = 12'd0;                
        temp.imm20   = 20'd0;
    
        case (temp.op)
            // Handle R_TYPE instruction
            R_TYPE: begin end
            // Handle LOAD instruction
            LOAD: begin 
                temp.imm12   = instr[31:20]; 
                temp.funct7  = 7'd0;
                temp.rs2     = 5'd0;
            end
            
            // Handle S_TYPE instruction
            S_TYPE: begin 
                temp.imm12   = {instr[31:25], instr[11:7]}; 
                temp.funct7  = 7'd0;
                temp.rd      = 5'd0; 
            end
            
            // Handle JAL instruction
            JAL: begin 
                temp       = '{default: 0};
                temp.rd    = instr[11:7];
                temp.op    = instr[6:0];
                temp.imm20 = {instr[31], instr[18:12], instr[19], instr[30:20]}; 
               
            end
            
            // Handle B_TYPE instruction
            B_TYPE: begin 
                temp.imm12 = { instr[31], instr[7], instr[30:25],  instr[11:8]};
                temp.funct7  = 7'd0;
                temp.rd      = 5'd0; 
            end
            // Handle I_IMME instruction
            I_IMME: begin 
                temp.imm12   = instr[31:20];
                temp.funct7  = 7'd0;
                temp.rs2     = 5'd0; 
            end
            // Handle unknown opcode
            default: temp = '{default: 0};
        endcase
    
    result = temp;
    return result;
    endfunction
    
    // Function that decode instruction
    function automatic ctrl_t cntrl_gen(input logic [6:0] op);
        ctrl_t temp;
        temp.target = NONE_c;
        temp.alu    = IMM;
        temp.mem    = NONE_c;
        temp.wb     = REG_WRITE;
       
        case (op)
            R_TYPE:  begin temp.target = ALU_REG; temp.alu = RS2; end
            I_IMME:  begin temp.target = ALU_REG; end
            LOAD:    begin temp.target = MEM_REG; temp.mem = MEM_READ; end
            S_TYPE:  begin temp.target = MEM_REG; temp.mem = MEM_WRITE; temp.wb = NONE_c; end       
            B_TYPE:  begin temp.target = BRANCH; temp.alu = RS2; temp.wb = NONE_c; end 
            JAL:     begin temp.target = JUMP; temp.alu = NONE_c; end 
            JALR:    begin temp.target = JUMP; temp.alu = NONE_c; end 
            ECALL:   begin temp.target = NONE_c; temp.alu = NONE_c; temp.wb = NONE_c;end 
            U_LUI:   begin temp.target = NONE_c; temp.alu = NONE_c; end 
            U_AUIPC: begin temp.alu = NONE_c; end 
            default: begin temp.alu = NONE_c; temp.wb = NONE_c; end 
        endcase
    
        return temp;
    endfunction

    // DATA HAZARD DETECTOR for instruction 1
    function automatic hazard_signal_t haz_forw1( 
        input logic [6:0] exmema_op, input logic [4:0] exmema_rd,
        input logic [6:0] exmemb_op, input logic [4:0] exmemb_rd,
        input logic [6:0] memwba_op, input logic [4:0] memwba_rd,
        input logic [6:0] memwbb_op, input logic [4:0] memwbb_rd,
        input logic [4:0] idex_rs
    );
        hazard_signal_t temp;
    
        if (((exmemb_op == R_TYPE) || (exmemb_op == I_IMME) || (exmemb_op == LOAD) || (exmemb_op == JAL)
            || (exmemb_op == JALR) || (exmemb_op == U_LUI) || (exmemb_op == U_AUIPC))&& 
            exmemb_rd != 5'd0 && exmemb_rd == idex_rs)
            temp = EX_MEM_B;
        else if (((exmema_op == R_TYPE) || (exmema_op == I_IMME) || (exmema_op == LOAD) || (exmema_op == JAL)
            || (exmema_op == JALR) || (exmema_op == U_LUI) || (exmema_op == U_AUIPC))&& 
            exmema_rd != 5'd0 && exmema_rd == idex_rs)
            temp = EX_MEM_A;
        else if (((memwbb_op == R_TYPE) || (memwbb_op == I_IMME) || (memwbb_op == LOAD) || (memwbb_op == JAL)
            || (memwbb_op == JALR) || (memwbb_op == U_LUI) || (memwbb_op == U_AUIPC))&& 
            memwbb_rd != 5'd0 && memwbb_rd == idex_rs)
            temp = EX_MEM_B;
        else if (((memwba_op == R_TYPE) || (memwba_op == I_IMME) || (memwba_op == LOAD) || (memwba_op == JAL)
            || (memwba_op == JALR) || (memwba_op == U_LUI) || (memwba_op == U_AUIPC))&& 
            memwba_rd != 5'd0 && memwba_rd == idex_rs)
            temp = EX_MEM_A;
        else
            temp = NONE_h;

        return temp;
    endfunction
    
    function automatic hazard_signal_t haz_stall1( 
        input logic [6:0] idexa_op, input logic [4:0] idexa_rd, 
        input logic [6:0] idexb_op, input logic [4:0] idexb_rd,
        input logic [4:0] id_rs1,  input logic [4:0] id_rs2
    );
        hazard_signal_t temp;
  
        if (idexa_op == LOAD && idexa_rd != 5'b0 && (idexa_rd == id_rs1 || idexa_rd == id_rs2 ))
            temp = A_STALL;
        else if (idexb_op == LOAD && idexb_rd != 5'b0 && (idexb_rd == id_rs1 || idexb_rd == id_rs2 ))
            temp = B_STALL; 
        else
            temp = NONE_h;

        return temp;
    endfunction
    
    // DATA HAZARD DETECTOR for instruction 2
    function automatic hazard_signal_t haz_forw2( 
        input logic [6:0] exmema_op, input logic [4:0] exmema_rd,
        input logic [6:0] exmemb_op, input logic [4:0] exmemb_rd,
        input logic [6:0] memwba_op, input logic [4:0] memwba_rd,
        input logic [6:0] memwbb_op, input logic [4:0] memwbb_rd,
        input logic [6:0] idex_op,   input logic [4:0] idexa_rd,
        input logic [4:0] idex_rs
    );
        hazard_signal_t temp;
    
        if (((idex_op == R_TYPE) || (idex_op == I_IMME) || (idex_op == LOAD) || (idex_op == JAL)
            || (idex_op == JALR) || (idex_op == U_LUI) || (idex_op == U_AUIPC))&& 
            idexa_rd != 5'd0 && idexa_rd == idex_rs)
            temp = FORW_FROM_A; 
        else if (((exmemb_op == R_TYPE) || (exmemb_op == I_IMME) || (exmemb_op == LOAD) || (exmemb_op == JAL)
            || (exmemb_op == JALR) || (exmemb_op == U_LUI) || (exmemb_op == U_AUIPC))&& 
            exmemb_rd != 5'd0 && exmemb_rd == idex_rs)
            temp = EX_MEM_B;
        else if (((exmema_op == R_TYPE) || (exmema_op == I_IMME) || (exmema_op == LOAD) || (exmema_op == JAL)
            || (exmema_op == JALR) || (exmema_op == U_LUI) || (exmema_op == U_AUIPC))&& 
            exmema_rd != 5'd0 && exmema_rd == idex_rs)
            temp = EX_MEM_A;
        else if (((memwbb_op == R_TYPE) || (memwbb_op == I_IMME) || (memwbb_op == LOAD) || (memwbb_op == JAL)
            || (memwbb_op == JALR) || (memwbb_op == U_LUI) || (memwbb_op == U_AUIPC))&& 
            memwbb_rd != 5'd0 && memwbb_rd == idex_rs)
            temp = EX_MEM_B;
        else if (((memwba_op == R_TYPE) || (memwba_op == I_IMME) || (memwba_op == LOAD) || (memwba_op == JAL)
            || (memwba_op == JALR) || (memwba_op == U_LUI) || (memwba_op == U_AUIPC))&& 
            memwba_rd != 5'd0 && memwba_rd == idex_rs)
            temp = EX_MEM_A;
        else
            temp = NONE_h;

        return temp;
    endfunction
    
    // DATA HAZARD DETECTOR for instruction 2
    function automatic hazard_signal_t haz_stall2( 
        input logic [6:0] idexa_op, input logic [4:0] idexa_rd, 
        input logic [6:0] idexb_op, input logic [4:0] idexb_rd,
        input logic [6:0] id_op,    input logic [4:0] id_rd,
        input logic [4:0] id_rs1,  input logic [4:0] id_rs2
    );
        hazard_signal_t temp;
        if (id_op == LOAD && id_rd != 5'b0 && (id_rd == id_rs1 || id_rd == id_rs2 ))
            temp = A_STALL;
        else if (idexa_op == LOAD && idexa_rd != 5'b0 && (idexa_rd == id_rs1 || idexa_rd == id_rs2 ))
            temp = A_STALL;
        else if (idexb_op == LOAD && idexb_rd != 5'b0 && (idexb_rd == id_rs1 || idexb_rd == id_rs2 ))
            temp = B_STALL; 
        else
            temp = NONE_h;

        return temp;
    endfunction
    
    function automatic hazard_signal_t encode_HAZ_sig(input logic [3:0] sig);
        case (sig)
            4'b0000: return A_STALL;
            4'b0001: return B_STALL;
            4'b0010: return STALL_FROM_A;
            4'b0011: return STALL_FROM_B;
            4'b0100: return EX_MEM_A;
            4'b0101: return EX_MEM_B;
            4'b0110: return MEM_WB_A;
            4'b0111: return MEM_WB_B;
            4'b1000: return FORW_FROM_A;
            4'b1001: return HOLD_B;
            4'b1010: return B_INVALID;
            4'b1011: return NONE_h;
            default: return NONE_h; // optional: catch-all for safety
        endcase
    endfunction
    
    function automatic logic [3:0] decode_HAZ_sig(input hazard_signal_t sig);
        case (sig)
            A_STALL      : return 4'b0000;
            B_STALL      : return 4'b0001;
            STALL_FROM_A : return 4'b0010;
            STALL_FROM_B : return 4'b0011;
            EX_MEM_A     : return 4'b0100;
            EX_MEM_B     : return 4'b0101;
            MEM_WB_A     : return 4'b0110;
            MEM_WB_B     : return 4'b0111;
            FORW_FROM_A  : return 4'b1000;
            HOLD_B       : return 4'b1001;
            B_INVALID    : return 4'b1010;
            NONE_h       : return 4'b1011;
            default      : return 4'b1111; // Optional: unknown encoding
        endcase
    endfunction
    
    function string control_signal_to_string(input control_signal_t val);
        case (val)
            MEM_READ  : control_signal_to_string = "MEM_READ";
            MEM_WRITE : control_signal_to_string = "MEM_WRITE";
            REG_WRITE : control_signal_to_string = "REG_WRITE";
            MEM_REG   : control_signal_to_string = "MEM_REG";
            ALU_REG   : control_signal_to_string = "ALU_REG";
            BRANCH    : control_signal_to_string = "BRANCH";
            JUMP      : control_signal_to_string = "JUMP";
            RS2       : control_signal_to_string = "RS2";
            IMM       : control_signal_to_string = "IMM";
            VALID     : control_signal_to_string = "VALID";
            INVALID   : control_signal_to_string = "INVALID";
            NONE_c    : control_signal_to_string = "NONE_c";
            default   : control_signal_to_string = "UNKNOWN";
        endcase
    endfunction
    
    function automatic alu_e encode_flag_sig(input logic [2:0] sig);
        case (sig)
            3'b000: return Z;
            3'b001: return V;
            3'b010: return Cf;
            3'b011: return N;
            default: return NONE_f; // optional: catch-all for safety
        endcase
    endfunction
    
    function automatic alu_op_t encode_op_sig(input logic [3:0] sig);
        case (sig)
            4'b0000: return ALU_ADD;
            4'b0001: return ALU_SUB;
            4'b0010: return ALU_XOR;
            4'b0011: return ALU_OR;
            4'b0100: return ALU_AND;
            4'b0101: return ALU_SLL;
            4'b0110: return ALU_SRL;
            4'b0111: return ALU_SRA;
            4'b1000: return ALU_SLT;
            4'b1001: return ALU_SLTU;
            4'b1011: return ADD_SUB;
            default: return NONE; // optional: catch-all for safety
        endcase
    endfunction

endpackage
