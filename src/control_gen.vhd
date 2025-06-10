------------------------------------------------------------------------------
-- Noridel Herron
-- 6/7/2025
-- Generates control signals.
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.enum_types.all;

entity control_gen is
    Port ( 
            opcode     : in std_logic_vector(OPCODE_WIDTH-1 downto 0); 
            ctrl_sig   : out control_Type
         );
end control_gen;

architecture Behavioral of control_gen is

begin

    process (opcode)
    variable temp : control_Type := EMPTY_control_Type;
    begin   
        temp.alu_op      := NONE;
        temp.mem_read    := NONE;
        temp.mem_write   := NONE;
        temp.reg_write   := REG_WRITE;
        temp.mem_reg     := NONE;
        temp.branch      := NONE;
        temp.jump        := NONE;
        temp.imm         := NONE;
        
        case opcode is
            when R_Type =>
                
            when I_IMME => 
            when LOAD   =>
                temp.mem_read    := MEM_READ;
            when S_TYPE =>
                temp.mem_write   := MEM_WRITE;
                temp.reg_write   := NONE;
            when B_TYPE =>
                temp.reg_write   := NONE;
            when JAL =>
                temp.alu         := NONE;
            when JALR =>
                temp.alu         := NONE;
            when JALR =>
            when others =>
                temp  := EMPTY_control_Type;
        end case;  
        
        ctrl_sig  <= temp;
    end process;
    
end Behavioral;
