
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 

package initialize_records is

    constant EMPTY_inst_pc : Inst_PC := (
        pc          => ZERO_32bits,
        instr       => NOP,
        is_valid    => INVALID
    );
    
    constant EMPTY_Inst_PC_N : Inst_PC_N := (
        A          => EMPTY_inst_pc,
        B          => EMPTY_inst_pc
    );
    
    
    constant tbA_inst_pc : Inst_PC := (
        pc          => ZERO_32bits,
        instr       => ONE_32bits,
        is_valid    => VALID
    ); 
    
    constant tbB_inst_pc : Inst_PC := (
        pc          => x"00000004",
        instr       => ONE_32bits,
        is_valid    => VALID
    ); 
    
     constant init_Inst_PC_N : Inst_PC_N := (
        A          => tbA_inst_pc,
        B          => tbB_inst_pc
    );
    
    constant NOP_Inst_N : Inst_N := (
        A          => NOP,
        B          => NOP
    );
    
    constant EMPTY_PC_N : PC_N := (
        A          => ZERO_32bits,
        B          => ZERO_32bits
    );
    
    constant NOT_valid : valid_N := (
        A          => INVALID,
        B          => INVALID
    );
    
    constant BOTH_valid : valid_N := (
        A          => VALID,
        B          => VALID
    );
    
    -----------------------------------------ID STAGE------------------------------------------
    constant EMPTY_REG_DATA_PER : REG_DATA_PER := (
        A          => ZERO_32bits,
        B          => ZERO_32bits
    );
    
    constant EMPTY_REG_DATAS : REG_DATAS := (
        one        => EMPTY_REG_DATA_PER,
        two        => EMPTY_REG_DATA_PER
    );
    
    constant EMPTY_DECODER : Decoder_Type := (
        op          => ZERO_7bits,
        rd          => ZERO_5bits,
        funct3      => ZERO_3bits,
        rs1         => ZERO_5bits,
	    rs2         => ZERO_5bits,
        funct7      => ZERO_7bits,
        imm12       => ZERO_12bits,
        imm20       => ZERO_20bits
    );
    
    constant EMPTY_DECODER_N_INSTR : DECODER_N_INSTR := (
        A          => EMPTY_DECODER,
        B          => EMPTY_DECODER
    );

    constant EMPTY_HDU_r : HDU_r := (
        forwA      => NONE_h,
        forwB      => NONE_h,
        stall      => NONE_h
    );
    
    constant EMPTY_HDU_OUT_N : HDU_OUT_N := (
        A          => EMPTY_HDU_r,
        B          => EMPTY_HDU_r
    );
    
    constant EMPTY_control_Type : control_Type := ( 
        target      => NONE_c,
        alu         => NONE_c,
        mem         => NONE_c,
        wb          => NONE_c
    );
    
    constant EMPTY_control_Type_N : control_Type_N := (
        A          => EMPTY_control_Type,
        B          => EMPTY_control_Type
    );
    
    constant EMPTY_RD_CTRL : RD_CTRL := (
        cntrl      => EMPTY_control_Type,
        rd         => ZERO_5bits
    );
    
    constant EMPTY_RD_CTRL_N_INSTR : RD_CTRL_N_INSTR := (
        A          => EMPTY_RD_CTRL,
        B          => EMPTY_RD_CTRL
    );
-----------------------------------------EX STAGE------------------------------------------
    
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
    
    constant EMPTY_BranchAndJump_Type : BranchAndJump_Type := (
        target      => ZERO_32bits,
        rd_value    => ZERO_32bits
    );
    
     -----------------------------------------FORWARDING UNIT------------------------------------------ 

    constant EMPTY_EX_CONTENT : EX_CONTENT := (  
        operand    => EMPTY_REG_DATA_PER,
        alu        => EMPTY_ALU_out,
        S_data     => ZERO_32bits,
        cntrl      => EMPTY_control_Type,
        rd         => ZERO_5bits
    );
    
    constant EMPTY_EX_CONTENT_N : EX_CONTENT_N := (
        A          => EMPTY_EX_CONTENT,
        B          => EMPTY_EX_CONTENT
    );
    
    -----------------------------------------MEM STAGE------------------------------------------ 
    constant EMPTY_MEM_CONTENT : MEM_CONTENT := (
        alu         => ZERO_32bits,
        mem         => ZERO_32bits,
        rd          => ZERO_5bits,
        we          => NONE_c,
        me          => NONE_c
    );
    
    constant EMPTY_MEM_CONTENT_N : MEM_CONTENT_N := (
        A          => EMPTY_MEM_CONTENT,
        B          => EMPTY_MEM_CONTENT
    );

    -----------------------------------------WB STAGE------------------------------------------ 
    constant EMPTY_WB_CONTENT : WB_CONTENT := (
        data        => ZERO_32bits,
        rd          => ZERO_5bits,
        we          => NONE_c
    );
    
    constant EMPTY_WB_CONTENT_N_INSTR : WB_CONTENT_N_INSTR := (
        A          => EMPTY_WB_CONTENT,
        B          => EMPTY_WB_CONTENT
    );

    constant EMPTY_EX_OPERAND_N : EX_OPERAND_N := (
        one        => EMPTY_REG_DATA_PER,
        S_data1    => ZERO_32bits,
        two        => EMPTY_REG_DATA_PER,
        S_data2    => ZERO_32bits     
    );
end package;