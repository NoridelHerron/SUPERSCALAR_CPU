
library ieee;
use ieee.std_logic_1164.all;
use work.const_Types.all;

package enum_types is

    type FLAG_TYPE is ( Z, V, Cf, N, NONE);
    
    type CONTROL_SIG is ( 
        -- memory and register control signal
        MEM_READ, MEM_WRITE, REG_WRITE, ALU_ON,
        -- R_type expected operation
        ALU_ADD, ALU_SUB, ALU_XOR, ALU_OR, ALU_AND,
        ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLT, ALU_SLTU,
        -- I_type expected operation
        ALU_ADDi, ALU_XORi, ALU_ORi, ALU_ANDi,
        ALU_SLLi, ALU_SRLi, ALU_SRAi, ALU_SLTi, ALU_SLTiU,
        NONE
    );

    
end package;