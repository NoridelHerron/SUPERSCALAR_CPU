------------------------------------------------------------------------------
-- Noridel Herron
-- 6/7/2025
-- Extracts opcode, register values, function codes, and immediate values from a 32-bit instruction. 
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;

entity DECODER is
    Port (  -- inputs 
            ID          : in  Inst_PC;       
            ID_content  : out Decoder_Type      
        );
end DECODER;

architecture behavior of DECODER is

begin             
             
    process (ID)
    variable temp : Decoder_Type := EMPTY_DECODER;
    begin 
        temp.funct7   := ID.instr(31 downto 25);
        temp.rs2      := ID.instr(24 downto 20);
        temp.rs1      := ID.instr(19 downto 15);
        temp.funct3   := ID.instr(14 downto 12);
        temp.rd       := ID.instr(11 downto 7);
        temp.op       := ID.instr(6 downto 0);

        ID_content <= temp;
    end process;

end behavior;