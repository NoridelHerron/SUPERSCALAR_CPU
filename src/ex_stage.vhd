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
use work.MyFunctions.all;

entity ex_stage is
    generic (ENABLE_FORWARDING : boolean := isFORW_ON);
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
    signal temp_o   : EX_OPERAND_N := EMPTY_EX_OPERAND_N;
    signal operands : EX_OPERAND_N := EMPTY_EX_OPERAND_N;
    
    signal isEnable : std_logic    := '0';
    
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
            operands => temp_o
        );
    
    --isEnable <= '1' when ENABLE_FORWARDING else '0'; 
    process(temp_o)
    variable temp     : EX_OPERAND_N := EMPTY_EX_OPERAND_N;
    variable operA    : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA;
    variable operB    : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA;
    begin 
        if ENABLE_FORWARDING then
            temp := temp_o;
        else
            operA      := get_operand_val (ID_EX.A.op, reg.one.B, ID_EX.A.imm12);
            operB      := get_operand_val (ID_EX.B.op, reg.two.B, ID_EX.B.imm12);
            
            temp.one.A   := reg.one.A;
            temp.one.B   := operA.operand;
            temp.S_data1 := operA.S_data;
            
            temp.two.A   := reg.two.A;
            temp.two.B   := operB.operand;
            temp.S_data2 := operB.S_data;
        end if;
        operands <= temp;
    end process;
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
