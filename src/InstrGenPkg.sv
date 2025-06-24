

package InstrGenPkg;

    import enum_helpers::*;

    // Function to generate a random instruction word
    function automatic logic [31:0] gen_random_instr(ref int unsigned seed);
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
        rd     = $urandom_range(0,31);
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

endpackage
