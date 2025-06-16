------------------------------------------------------------------------------
-- Noridel Herron
-- 6/13/2025
-- Function definition
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

use work.const_Types.all;
use work.Pipeline_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;

package MyFunctions is

  function get_decoded_val (rand_real, rs1, rs2, rd : real) return Decoder_Type;

  function Get_Control(opcode : std_logic_vector(OPCODE_WIDTH-1 downto 0)) return control_Type;
  
  function get_hazard_sig  (ID      : DECODER_N_INSTR;   
                            ID_EX   : DECODER_N_INSTR; 
                            ID_EX_c : control_Type_N;    
                            EX_MEM  : RD_CTRL_N_INSTR; 
                            MEM_WB  : RD_CTRL_N_INSTR) return HDU_OUT_N;

end MyFunctions;