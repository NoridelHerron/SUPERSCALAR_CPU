`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/19/2025 9:28:07 AM
// Design Name: Noridel Herron
// Module Name: struch_helpers 
// Project Name: Superscalar CPU
// helper for waveform debugging
//////////////////////////////////////////////////////////////////////////////////


package struct_helpers;
    
    import enum_helpers::*;
    
    typedef struct packed {
        logic [31:0]     pc; 
        logic [31:0]     instr;
        control_signal_t is_valid;
    } Inst_PC;
    
    typedef struct packed {
        Inst_PC A; 
        Inst_PC B;
    } Inst_PC_N;
    
    typedef struct packed {
        logic [31:0] A;
        logic [31:0] B;
    } regs_per_t;
    
    typedef struct packed {
        regs_per_t one;
        regs_per_t two;
    } regs_t;
    
    typedef struct packed {
        logic [6:0] op;
        logic [4:0] rd;
        logic [2:0] funct3;
        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [6:0] funct7;
        logic [11:0] imm12;
        logic [19:0] imm20;
    } decoder_t;
    
    typedef struct packed {
        decoder_t A;
        decoder_t B;
    } id_ex_t;

    typedef struct packed {
        hazard_signal_t forwA;
        hazard_signal_t forwB;
        hazard_signal_t stall;
    } haz_per_t;
    
    typedef struct packed {
        haz_per_t A;
        haz_per_t B;
    } haz_t;
    
    typedef struct packed {
        logic [3:0] fA;
        logic [3:0] fB;
        logic [3:0] st;
    } haz_val_per_t;
    
    typedef struct packed {
        haz_val_per_t A;
        haz_val_per_t B;
    } haz_val_t;
    
    typedef struct packed {
        haz_per_t    haz;
        regs_per_t   operand;
        alu_op_t     op;
        logic [31:0] data;
        logic        Z, V, C, N;
        logic [31:0] S_data;
        logic [4:0]  rd;
    } ex_mem_per_t;
    
    typedef struct packed {
        ex_mem_per_t A;
        ex_mem_per_t B;
    } ex_mem_t;
    
    typedef struct packed {
        logic [31:0]     data;
        logic [4:0]      rd;
        control_signal_t cntrl;
    } mem_wb_per_t;
    
    typedef struct packed {
        mem_wb_per_t A;
        mem_wb_per_t B;
    } mem_wb_t;
    
    typedef struct packed {
        control_signal_t cntrl;
        logic [4:0]      rd;
    } rd_ctrl_t;
    
    typedef struct packed {
        rd_ctrl_t A;
        rd_ctrl_t B;
    } rd_ctrl_N_t;
    
    typedef struct packed {
        logic [4:0]  opA; 
        logic [4:0]  opB;
    } alu_t;
    
    
endpackage