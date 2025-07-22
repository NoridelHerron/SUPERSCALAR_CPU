-- File: instruction_generator.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ALL;

use work.const_Types.all;
use work.Pipeline_Types.all;
use work.initialize_records.all;

package instruction_generator is

    subtype data_32 is std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Function declaration only
    function instr_gen(rand_real : real) return data_32;

end instruction_generator;

package body instruction_generator is

    function instr_gen(rand_real : real) return data_32 is
        variable result  : data_32       := (others => '0'); 
        variable temp    : Decoder_Type  := EMPTY_DECODER;
       
    begin
        if    rand_real < 0.4  then temp.op := R_TYPE;
        elsif rand_real < 0.5  then temp.op := S_TYPE;
      --  elsif rand_real < 0.3  then temp.op := JAL;
      --  elsif rand_real < 0.6  then temp.op := B_TYPE;
        elsif rand_real < 0.9  then temp.op := I_IMME;
        else temp.op := LOAD;
        end if;

        temp.rd := std_logic_vector(to_unsigned(integer(rand_real * 2.0 * 32.0), 5));   
        temp.rs1 := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));
        temp.rs2 := std_logic_vector(to_unsigned(integer(rand_real * 3.0 * 32.0), 5));
        temp.funct3 := std_logic_vector(to_unsigned(integer(rand_real * 8.0), 3));
        temp.funct7 := std_logic_vector(to_unsigned(integer(rand_real * 128.0), 7));
        
        case temp.op is
            when R_TYPE | I_IMME =>
                if temp.funct3 = "000" or temp.funct7 = "101" then
                    if rand_real > 0.5 then
                        temp.funct7 := ZERO_7bits;
                    else
                        temp.funct7 := THIRTY_TWO;
                    end if;
                end if;
                 
            when LOAD =>    
                    temp.funct3 := "010"; -- lw for 32 bits    
            
            when others => temp := EMPTY_DECODER;
        end case;
 
        return temp.funct7 & temp.rs2 & temp.rs1 & temp.funct3 & temp.rd & temp.op;
    end function;

end instruction_generator;
