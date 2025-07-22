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
use work.ENUM_T.all; 

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
        temp.target := NONE_c;
        temp.alu    := IMM;
        temp.mem    := NONE_c;
        temp.wb     := REG_WRITE;

        case opcode is
            when R_Type =>   
                temp.target := ALU_REG;
                temp.alu    := RS2;
                
            when I_IMME => 
                temp.target := ALU_REG;
                
            when LOAD   =>
                temp.target := MEM_REG;
                temp.mem    := MEM_READ;
                
            when S_TYPE =>
                temp.target := MEM_REG;
                temp.mem    := MEM_WRITE;
                temp.wb     := NONE_c;
                
            when B_TYPE =>
                temp.alu    := RS2;
                temp.wb     := NONE_c;
                temp.target := BRANCH;
                
            when JAL =>
                temp.target := JUMP;
                temp.alu    := NONE_c;
   
            when others =>
                temp  := EMPTY_control_Type;
        end case;  
        
        ctrl_sig  <= temp;
    end process;
    
end Behavioral;
