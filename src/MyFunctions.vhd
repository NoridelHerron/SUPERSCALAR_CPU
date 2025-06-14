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

  function get_decoded_val (rand_real : real) return Decoder_Type;

  function get_contrl_sig  (op: std_logic_vector) return CONTROL_SIG;
  
  function get_hazard_sig  (H: HDU_in) return HDU_OUT_N;

end MyFunctions;
