
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ALU_pkg.all;
--use work.control_types.all;

package initialize_records is

    constant EMPTY_inst_pc : Inst_PC := (
        instr       => x"00000013",
        pc          => ZERO_32bits
    );
    
    constant EMPTY_DECODER : Decoder_Type := (
        op          => I_IMME,
        rd          => ZERO_5bits,
        funct3      => ZERO_3bits,
        rs1         => ZERO_5bits,
	    rs2         => ZERO_5bits,
        funct7      => ZERO_7bits,
        imm12       => ZERO_12bits,
        imm20       => ZERO_20bits
    );

    constant EMPTY_control_Type : control_Type := ( 
        target      => NONE,
        alu         => NONE,
        mem         => NONE,
        wb          => NONE
    );

    constant EMPTY_BranchAndJump_Type : BranchAndJump_Type := (
        target      => ZERO_32bits,
        rd_value    => ZERO_32bits
    );
    
    constant EMPTY_ALU_add_sub : ALU_add_sub := (    
        result      => ZERO_32bits,  
        CB          => ZERO  
    );
    
    constant EMPTY_ALU_in : ALU_in := (   
        A           => ZERO_32bits,  
        B           => ZERO_32bits,  
        f3          => ZERO_3bits,  
        f7          => ZERO_7bits  
    );
    
    constant EMPTY_ALU_out : ALU_out := (   
        operation   => NONE,
        result      => ZERO_32bits,  
        Z           => NONE,
        V           => NONE,
        C           => NONE,
        N           => NONE
    );

end package;