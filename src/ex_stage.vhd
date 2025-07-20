------------------------------------------------------------------------------
-- Noridel Herron
-- Execute Stage (EX)
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;

entity ex_stage is
    Port ( 
        EX_MEM   : in  EX_CONTENT_N; 
        WB       : in  WB_CONTENT_N_INSTR;
        ID_EX    : in  DECODER_N_INSTR;
        ID_EX_c  : in  control_Type_N;
        reg      : in  REG_DATAS;
        Forw     : in  HDU_OUT_N;   
        ex_out   : out EX_CONTENT_N
    );
end ex_stage;

architecture Behavioral of ex_stage is

    -- Operand forwarding result
    signal operands : EX_OPERAND_N := EMPTY_EX_OPERAND_N;

    -- ALU I/O signals
    signal alu_in1  : ALU_in  := EMPTY_ALU_in;
    signal alu_out1 : ALU_out := EMPTY_ALU_out;
    signal alu_in2  : ALU_in  := EMPTY_ALU_in;
    signal alu_out2 : ALU_out := EMPTY_ALU_out;

begin

    --------------------------------------------------------------------------
    -- Forwarding Unit Instantiation
    --------------------------------------------------------------------------
    Forwarding: entity work.Forw_Unit
        port map (
            EX_MEM   => EX_MEM,
            WB       => WB,
            ID_EX    => ID_EX,
            reg      => reg,
            Forw     => Forw,
            operands => operands
        );

    --------------------------------------------------------------------------
    -- First ALU Input Assignment
    --------------------------------------------------------------------------
    input_ALU1 : entity work.alu1_input
        port map (
            ID_EX    => ID_EX,
            operands => operands, 
            alu1     => alu_in1
        );
    
    --------------------------------------------------------------------------
    -- First ALU Instantiation
    --------------------------------------------------------------------------
    ALU1: entity work.ALU
        port map (
            alu_input  => alu_in1,
            alu_output => alu_out1
        );

    --------------------------------------------------------------------------
    -- Second ALU Input Assignment with Forwarding Logic
    --------------------------------------------------------------------------
    ALU2_input: entity work.Forw_case
        port map (
            reg     => operands,
            Forw    => Forw,
            ID_EX   => ID_EX,
            alu1    => alu_out1,
            alu2    => alu_in2
        );

    --------------------------------------------------------------------------
    -- Second ALU Instantiation
    --------------------------------------------------------------------------
    ALU2: entity work.ALU
        port map (
            alu_input  => alu_in2,
            alu_output => alu_out2
        );

    --------------------------------------------------------------------------
    -- EX Output Assignments
    --------------------------------------------------------------------------
    -- Path A
    ex_out.A.operand.A  <= alu_in1.A;
    ex_out.A.operand.B  <= alu_in1.B;
    ex_out.A.alu        <= alu_out1;
    ex_out.A.S_data     <= operands.S_data1;
    ex_out.A.rd         <= ID_EX.A.rd;
    ex_out.A.cntrl      <= ID_EX_c.A;

    -- Path B
    ex_out.B.operand.A  <= alu_in2.A;
    ex_out.B.operand.B  <= alu_in2.B;
    ex_out.B.alu        <= alu_out2;
    ex_out.B.S_data     <= operands.S_data2;
    ex_out.B.rd         <= ID_EX.B.rd;
    ex_out.B.cntrl      <= ID_EX_c.B;

end Behavioral;
