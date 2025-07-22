-- File: instruction_generator.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ALL;

use work.const_Types.all;
use work.Pipeline_Types.all;
use work.initialize_records.all;

package decoder_function is

    subtype data_32 is std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Function declaration only
    function decode( ID : data_32) return Decoder_Type;

end decoder_function;

package body decoder_function is

    function decode( ID : data_32) return Decoder_Type is
        variable temp  : Decoder_Type := EMPTY_Decoder; 

    begin
        temp.funct7   := ID(31 downto 25);
        temp.rs2      := ID(24 downto 20);
        temp.rs1      := ID(19 downto 15);
        temp.funct3   := ID(14 downto 12);
        temp.rd       := ID(11 downto 7);
        temp.op       := ID(6 downto 0);
        temp.imm12    := ZERO_12bits;
        temp.imm20    := ZERO_20bits;
        
        case temp.op is
            when R_TYPE => 
                temp := temp;
                
            when I_IMME | LOAD | JALR | ECALL => 
                temp.imm12  := ID(31 downto 20);     
                temp.funct7 := ZERO_7bits;
                temp.rs2    := ZERO_5bits;
                
            when S_TYPE => 
                temp.imm12  := ID(31 downto 25) & ID(11 downto 7); 
                temp.funct7 := ZERO_7bits;
                temp.rd     := ZERO_5bits;       
                
            when B_TYPE => 
                temp.imm12  := ID(31) & ID(7) & ID(30 downto 25) & ID(11 downto 8);  
                temp.funct7 := ZERO_7bits;
                temp.rd     := ZERO_5bits;     
                
            when U_LUI | U_AUIPC =>  
                temp.imm20  := ID(31 downto 12); 
            
            when JAL =>  
                temp        := EMPTY_DECODER;
                temp.rd     := ID(11 downto 7);
                temp.op     := ID(6 downto 0);
                temp.imm20  := ID(31) & ID(18 downto 12) & ID(19) & ID(30 downto 20); 
                     
            when others => temp := EMPTY_DECODER;
        end case;

        return temp;
    end function;

end decoder_function;
