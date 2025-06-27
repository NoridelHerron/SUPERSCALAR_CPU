

package InstrGenPkg;

    localparam logic [6:0] LOAD     = 7'b0000011;
    localparam logic [6:0] S_TYPE   = 7'b0100011;
    localparam logic [6:0] JAL      = 7'b1101111;
    localparam logic [6:0] B_TYPE   = 7'b1100011;
    localparam logic [6:0] I_IMME   = 7'b0010011;
    localparam logic [6:0] R_TYPE   = 7'b0110011;

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
            R_TYPE: begin temp.target = ALU_REG; temp.alu = RS2; end
            I_IMME: begin temp.target = ALU_REG; end
            LOAD:   begin temp.target = MEM_REG; temp.mem = MEM_READ; end
            S_TYPE: begin temp.target = MEM_REG; temp.mem = MEM_WRITE; temp.wb = NONE_c; end       
            B_TYPE: begin temp.target = BRANCH; temp.alu = RS2; temp.wb = NONE_c; end 
            JAL:    begin temp.target = JUMP; temp.alu = NONE_c; end 
            default: begin temp.alu = NONE_c; temp.wb = NONE_c; end 
        endcase
    
        return temp;
    endfunction

    // Function that decode instruction
    function automatic haz_t haz_gen(
        input id_ex_t ID,
        input id_ex_t ID_EX,
        input ctrl_N_t ID_EX_c,
        input rd_ctrl_N_t EX_MEM,
        input rd_ctrl_N_t MEM_WB
    );
        haz_t temp;
    
        // Forwarding A
        if (EX_MEM.A.wb == REG_WRITE && EX_MEM.A.rd != 5'd0 && EX_MEM.A.rd == ID_EX.A.rs1)
            temp.A.ForwA = EX_MEM_A;
        else if (EX_MEM.B.wb == REG_WRITE && EX_MEM.B.rd != 5'd0 && EX_MEM.B.rd == ID_EX.A.rs1)
            temp.A.ForwA = EX_MEM_B;
        else if (MEM_WB.A.wb == REG_WRITE && MEM_WB.A.rd != 5'd0 && MEM_WB.A.rd == ID_EX.A.rs1)
            temp.A.ForwA = MEM_WB_A;
        else if (MEM_WB.B.wb == REG_WRITE && MEM_WB.B.rd != 5'd0 && MEM_WB.B.rd == ID_EX.A.rs1)
            temp.A.ForwA = MEM_WB_B;
        else
            temp.A.ForwA = NONE_h;
    
        // Forwarding B
        if (EX_MEM.A.wb == REG_WRITE && EX_MEM.A.rd != 5'd0 && EX_MEM.A.rd == ID_EX.A.rs2)
            temp.A.ForwB = EX_MEM_A;
        else if (EX_MEM.B.wb == REG_WRITE && EX_MEM.B.rd != 5'd0 && EX_MEM.B.rd == ID_EX.A.rs2)
            temp.A.ForwB = EX_MEM_B;
        else if (MEM_WB.A.wb == REG_WRITE && MEM_WB.A.rd != 5'd0 && MEM_WB.A.rd == ID_EX.A.rs2)
            temp.A.ForwB = MEM_WB_A;
        else if (MEM_WB.B.wb == REG_WRITE && MEM_WB.B.rd != 5'd0 && MEM_WB.B.rd == ID_EX.A.rs2)
            temp.A.ForwB = MEM_WB_B;
        else
            temp.A.ForwB = NONE_h;
    
        // Stall A
        if (ID_EX_c.A.mem == MEM_READ && ID_EX.A.rd != 5'd0 &&
            (ID_EX.A.rd == ID.A.rs1 || ID_EX.A.rd == ID.A.rs2))
            temp.A.stall = A_STALL;
        else if (ID_EX.B.op == LOAD && ID_EX.B.rd != 5'd0 &&
                 (ID_EX.B.rd == ID.A.rs1 || ID_EX.B.rd == ID.A.rs2))
            temp.A.stall = B_STALL;
        else
            temp.A.stall = NONE_h;
    
        // Forwarding for ID_EX.B
        if (ID_EX_c.A.wb == REG_WRITE && ID_EX.B.rs1 == ID_EX.A.rd && ID_EX.A.rd != 5'd0)
            temp.B.ForwA = FORW_FROM_A;
        else if (EX_MEM.A.wb == REG_WRITE && EX_MEM.A.rd != 5'd0 && EX_MEM.A.rd == ID_EX.B.rs1)
            temp.B.ForwA = EX_MEM_A;
        else if (EX_MEM.B.wb == REG_WRITE && EX_MEM.B.rd != 5'd0 && EX_MEM.B.rd == ID_EX.B.rs1)
            temp.B.ForwA = EX_MEM_B;
        else if (MEM_WB.A.wb == REG_WRITE && MEM_WB.A.rd != 5'd0 && MEM_WB.A.rd == ID_EX.B.rs1)
            temp.B.ForwA = MEM_WB_A;
        else if (MEM_WB.B.wb == REG_WRITE && MEM_WB.B.rd != 5'd0 && MEM_WB.B.rd == ID_EX.B.rs1)
            temp.B.ForwA = MEM_WB_B;
        else
            temp.B.ForwA = NONE_h;
    
        if (ID_EX_c.A.wb == REG_WRITE && ID_EX.B.rs2 == ID_EX.A.rd && ID_EX.A.rd != 5'd0)
            temp.B.ForwB = FORW_FROM_A;
        else if (EX_MEM.A.wb == REG_WRITE && EX_MEM.A.rd != 5'd0 && EX_MEM.A.rd == ID_EX.B.rs2)
            temp.B.ForwB = EX_MEM_A;
        else if (EX_MEM.B.wb == REG_WRITE && EX_MEM.B.rd != 5'd0 && EX_MEM.B.rd == ID_EX.B.rs2)
            temp.B.ForwB = EX_MEM_B;
        else if (MEM_WB.A.wb == REG_WRITE && MEM_WB.A.rd != 5'd0 && MEM_WB.A.rd == ID_EX.B.rs2)
            temp.B.ForwB = MEM_WB_A;
        else if (MEM_WB.B.wb == REG_WRITE && MEM_WB.B.rd != 5'd0 && MEM_WB.B.rd == ID_EX.B.rs2)
            temp.B.ForwB = MEM_WB_B;
        else
            temp.B.ForwB = NONE_h;
    
        // Stall B
        if (temp.A.stall != NONE_h)
            temp.B.stall = STALL_FROM_A;
        else if (ID_EX_c.A.mem == MEM_READ && ID_EX.A.rd != 5'd0 &&
                 (ID_EX.A.rd == ID.B.rs1 || ID_EX.A.rd == ID.B.rs2))
            temp.B.stall = A_STALL;
        else if (ID_EX_c.B.mem == MEM_READ && ID_EX.B.rd != 5'd0 &&
                 (ID_EX.B.rd == ID.B.rs1 || ID_EX.B.rd == ID.B.rs2))
            temp.B.stall = B_STALL;
        else
            temp.B.stall = NONE_h;
    
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

endpackage
