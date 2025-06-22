------------------------------------------------------------------------------
-- Noridel Herron
-- 6/8/2025
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
    
    process (ID_EX, operands )
        variable temp_alu_in1 : ALU_in := EMPTY_ALU_in;
    begin
    temp_alu_in1.A   := operands.one.A;
    temp_alu_in1.B   := operands.one.B;
    if ID_EX.A.op = LOAD or ID_EX.A.op = S_TYPE then
        -- since f3 of lw and sw is 2, i need to modify it here without changing the actual f3 or f7
        temp_alu_in1.f3  := ZERO_3bits;
        temp_alu_in1.f7  := ZERO_7bits;
        -- We will be using the flags for branching. 
        -- So, the flags will help us determine if rs1 =, /=, >, <, >=, <=
    elsif ID_EX.A.op = B_TYPE then
        temp_alu_in1.f3  := ZERO_3bits;
        temp_alu_in1.f7  := FUNC7_SUB;
    else
        temp_alu_in1.f3  := ID_EX.A.funct3;
        temp_alu_in1.f7  := ID_EX.A.funct7;
    end if;
    
    alu_in1 <= temp_alu_in1;
    end process;
    
    --------------------------------------------------------------------------
    -- First ALU Instantiation
    --------------------------------------------------------------------------
    ALU1: entity work.ALU
        port map (
            input  => alu_in1,
            output => alu_out1
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
            input  => alu_in2,
            output => alu_out2
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

    -- Path B
    ex_out.B.operand.A  <= alu_in2.A;
    ex_out.B.operand.B  <= alu_in2.B;
    ex_out.B.alu        <= alu_out2;
    ex_out.B.S_data     <= operands.S_data2;
    ex_out.B.rd         <= ID_EX.B.rd;

end Behavioral;
