//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/18/2025 10:13:07 AM
// Design Name: Noridel Herron
// Module Name: enum_helpers 
// Project Name: Superscalar CPU
// helper for waveform debugging
//////////////////////////////////////////////////////////////////////////////////
// enum_helpers.sv
package enum_helpers;

    typedef enum logic [2:0] {
        Z, V, Cf, N, NONE_f
    } alu_e;
    
    typedef enum logic [3:0] {
        ALU_ADD   = 4'h0,   ALU_SUB   = 4'h1,
        ALU_XOR   = 4'h2,   ALU_OR    = 4'h3,
        ALU_AND   = 4'h4,   ALU_SLL   = 4'h5, 
        ALU_SRL   = 4'h6,   ALU_SRA   = 4'h7, 
        ALU_SLT   = 4'h8,   ALU_SLTU  = 4'h9,
        NONE      = 4'ha,   ADD_SUB   = 4'hb
    } alu_op_t;

    typedef enum logic [3:0]{
        // instruction type
        R_TYPE_i = 4'h0, 
        I_IMM_i, 
        LOAD_i, 
        S_TYPE_i, 
        B_TYPE_i,
        JAL_i, 
        JALR_i, 
        LUI_i, 
        AUIPC_i, 
        ECALL_i, 
        NOP_i, 
        NONE_i
    } instruction_t;
    
    typedef enum logic [3:0]{
        // memory and register control signal
        MEM_READ = 4'h0, 
        MEM_WRITE, 
        REG_WRITE,           
        MEM_REG, 
        ALU_REG,    
        BRANCH, 
        JUMP, 
        RS2, 
        IMM,            
        VALID, 
        INVALID, 
        NONE_c,
        HOLD
    } control_signal_t;
    
    // HAZARD signal
    typedef enum logic [3:0]{
        A_STALL = 4'h0, 
        B_STALL, 
        STALL_FROM_A, 
        STALL_FROM_B,
        EX_MEM_A, 
        EX_MEM_B, 
        MEM_WB_A, 
        MEM_WB_B, 
        FORW_FROM_A, 
        HOLD_B, 
        B_INVALID, 
        NONE_h
    } hazard_signal_t;

    // Convert vector to enum
    // return enum alu_op type
    function automatic alu_op_t slv_to_aluE(logic [3:0] val);
        return alu_op_t'(val);
    endfunction
    
    // return enum instruction type
    function automatic instruction_t slv_to_instrE(logic [3:0] val);
        return instruction_t'(val);
    endfunction
    
    // return enum control_signal type
    function automatic control_signal_t slv_to_cntrlE(logic [3:0] val);
        return control_signal_t'(val);
    endfunction
    
    // return enum hazard type
    function automatic hazard_signal_t slv_to_hazE(logic [3:0] val);
        return hazard_signal_t'(val);
    endfunction
    
    
endpackage
