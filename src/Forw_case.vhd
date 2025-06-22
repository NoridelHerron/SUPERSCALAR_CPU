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

entity Forw_case is
    Port ( reg      : in  EX_OPERAND_N;
           Forw     : in  HDU_OUT_N;  
           ID_EX    : in  DECODER_N_INSTR;
           alu1     : in  ALU_out;
           alu2     : out ALU_in
    );
end Forw_case;

architecture Behavioral of Forw_case is

begin
    process (reg, Forw, ID_EX, alu1)
    variable temp_alu_in2 : ALU_in := EMPTY_ALU_in;
    begin
        -- Forward A operand
        if Forw.B.forwA = FORW_FROM_A then
            temp_alu_in2.A := alu1.result;
        else
            temp_alu_in2.A := reg.two.A;
        end if;

        -- Forward B operand
        if Forw.B.forwB = FORW_FROM_A then
            temp_alu_in2.B := alu1.result;
        else
            temp_alu_in2.B := reg.two.B;
        end if;

        -- Function codes for second ALU
        if ID_EX.B.op = LOAD or ID_EX.B.op = S_TYPE then
            temp_alu_in2.f3  := ZERO_3bits;
            temp_alu_in2.f7  := ZERO_7bits;  
        elsif ID_EX.B.op = B_TYPE then
            temp_alu_in2.f3  := ZERO_3bits;
            temp_alu_in2.f7  := FUNC7_SUB;
        else
            temp_alu_in2.f3  := ID_EX.B.funct3;
            temp_alu_in2.f7  := ID_EX.B.funct7;
        end if;

        alu2 <= temp_alu_in2;

    end process;

end Behavioral;
