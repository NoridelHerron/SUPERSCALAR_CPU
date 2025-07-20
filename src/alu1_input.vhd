------------------------------------------------------------------------------
-- Noridel Herron
-- Date: 6/22/2025
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 
use work.initialize_records.all;

entity alu1_input is
    Port ( 
            ID_EX    : in  DECODER_N_INSTR;
            operands : in  EX_OPERAND_N;
            alu1     : out ALU_in
    );
end alu1_input;

architecture Behavioral of alu1_input is

begin
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
    
    alu1 <= temp_alu_in1;
    end process;

end Behavioral;
