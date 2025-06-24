

package InstrGenPkg;

    localparam logic [6:0] LOAD     = 7'b0000011;
    localparam logic [6:0] S_TYPE   = 7'b0100011;
    localparam logic [6:0] JAL      = 7'b1101111;
    localparam logic [6:0] B_TYPE   = 7'b1100011;
    localparam logic [6:0] I_IMME   = 7'b0010011;
    localparam logic [6:0] R_TYPE   = 7'b0110011;

    //import enum_helpers::*;
    import struct_helpers::*;

    // Function to generate a random instruction word
    function automatic logic [31:0] gen_random_instr();
        real rand_real;
        logic [6:0] op;
        logic [4:0] rd, rs1, rs2;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [31:0] instr;

        // Generate uniform random number between 0 and 1
        void'($urandom(seed)); // update seed
        rand_real = $urandom_range(0, 10000) / 10000.0;

        // Select opcode based on probability ranges
        if (rand_real < 0.10)
            op = LOAD;
        else if (rand_real < 0.20)
            op = S_TYPE;
        else if (rand_real < 0.30)
            op = JAL;
        else if (rand_real < 0.60)
            op = B_TYPE;
        else if (rand_real < 0.80)
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
        decoder_t result;

    result.op      = instr[6:0];
    result.rd      = instr[11:7];
    result.funct3  = instr[14:12];
    result.rs1     = instr[19:15];
    result.rs2     = instr[24:20];
    result.funct7  = instr[31:25];
    result.imm12   = 12'd0;                
    result.imm20   = 20'd0;
    
    case (result.op)
    R_TYPE: begin
        // Handle R_TYPE instruction
    end
    
    LOAD: begin
        result.imm12   = instr[31:20]; 
    end
    
    S_TYPE: begin
        result.imm12   = {result.funct7, result.rd}; 
    end
    
    JAL: begin
        result.imm20   = {instr[31], instr[19], instr[18:12],  instr[30:20]}; 
    end
    
    B_TYPE: begin
        // Handle B_TYPE instruction
        result.imm12 = {instr[31], instr[7], instr[30:25],  instr[11:8]};
    end
    
    I_IMME: begin
        result.imm12   = instr[31:20]; 
    end
    
    default: begin
        // Handle unknown opcode
        result.op      = 7'd0; 
        result.rd      = 5'd0; 
        result.funct3  = 3'd0; 
        result.rs1     = 5'd0; 
        result.rs2     = 5'd0; 
        result.funct7  = 7'd0; 
        result.imm12   = 12'd0;                
        result.imm20   = 20'd0;
    end
endcase
    
    result.imm12   = instr[31:20];                 // I-type immediate
    result.imm20   = instr[31:12];                 // U-type or J-type upper

    return result;
endfunction

endpackage
