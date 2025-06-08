
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.enum_types.all;
use work.ALU_pkg.all;

package initialize_records is

    constant EMPTY_inst_pc : Inst_PC := (
        instr       => x"00000013",
        pc          => ZERO_32bits
    );
    
    constant EMPTY_DECODER : Decoder_Type := (
        op          => ZERO_7bits,
        rd          => ZERO_5bits,
        funct3      => ZERO_3bits,
        rs1         => ZERO_5bits,
	    rs2         => ZERO_5bits,
        funct7      => ZERO_7bits,
        imm         => ZERO_32bits
    );

    constant EMPTY_control_Type : control_Type := (   
        mem_read    => NONE,
        mem_write   => NONE,
        reg_write   => NONE,
        alu         => NONE
    );

    constant EMPTY_BranchAndJump_Type : BranchAndJump_Type := (
        branch      => ZERO,
        target      => ZERO_32bits,
        rd_value    => ZERO_32bits
    );
    
    constant EMPTY_ALU_out : ALU_out := (   
        result      => ZERO_32bits,  
        Z           => NONE,
        V           => NONE,
        C           => NONE,
        N           => NONE
    );

end package;