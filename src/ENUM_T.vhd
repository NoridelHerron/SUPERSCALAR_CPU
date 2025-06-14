
library ieee;
use ieee.std_logic_1164.all;
   
package ENUM_T is
    
    type FLAG_TYPE is ( Z, V, Cf, N, NONE);
    
    type ALU_OP is ( 
        -- R_type expected operation
        ALU_ADD, ALU_SUB, ALU_XOR, ALU_OR, ALU_AND,
        ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU,
        -- I_type expected operation
        ALU_ADDi, ALU_XORi, ALU_ORi, ALU_ANDi,
        ALU_SLLi, ALU_SRLi, ALU_SRAi, ALU_SLTi, ALU_SLTiU, 
        ADD, SUB, NONE
    );
    
    type INSTRUCTION_T is ( 
        -- instruction type
        R_TYPE_i, I_IMM_i, LOAD_i, S_TYPE_i, B_TYPE_i,
        JAL_i, JALR_i, LUI_i, AUIPC_i, ECALL_i, 
        NOP_i, NONE
    );

    type CONTROL_SIG is ( 
        -- memory and register control signal
        MEM_READ, MEM_WRITE, -- for load or store
        REG_WRITE,           -- wb
        MEM_REG, ALU_REG,    -- source result whether from alu or memory
        BRANCH, JUMP, 
        RS2, IMM,            -- for operand 2
        VALID, INVALID,
        NONE
    );
    
    -- HAZARD signal
    type HAZ_SIG is ( 
        A_STALL, B_STALL, STALL,
        EX_MEM_A, EX_MEM_B, MEM_WB_A, MEM_WB_B, FORW_FROM_A,
        NONE
    );

end package;