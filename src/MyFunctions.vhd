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

  subtype data_32 is std_logic_vector(DATA_WIDTH - 1 downto 0);
  subtype data_12 is std_logic_vector(IMM12_WIDTH-1 downto 0);
  subtype data_20 is std_logic_vector(IMM20_WIDTH-1 downto 0);
  subtype data_op is std_logic_vector(OPCODE_WIDTH-1 downto 0);
  
  -- generate 32 bits data
  function get_32bits_val(rand_real : real) return data_32;
  
  -- generate 12 bits
  function get_imm12_val(rand_real : real) return data_12;
  
  -- generate 20 bits data
  function get_imm20_val(rand_real : real) return data_20;
  
  -- generate 7 bits data for opcode
  function get_op (rand_real : real) return data_op;
  
  -- Generate forwarding status to determine the source of operands
  function get_forwStats (rand : real) return HAZ_SIG;
  
  function get_stall (op : std_logic_vector(OPCODE_WIDTH-1 downto 0); rand : real) return HAZ_SIG;
  
  -- Generate decoded value
  function get_decoded_val (rand_real, rs1, rs2, rd : real) return Decoder_Type;
  
  -- Generate control signal
  function Get_Control(opcode : std_logic_vector(OPCODE_WIDTH-1 downto 0)) return control_Type;
  -- Generate Hazard signal
  function get_hazard_sig  (ID      : DECODER_N_INSTR;   
                            ID_EX   : DECODER_N_INSTR; 
                            ID_EX_c : control_Type_N;    
                            EX_MEM  : EX_CONTENT_N; 
                            MEM_WB  : MEM_CONTENT_N) return HDU_OUT_N;
                            
  -- generate operandB value
  function get_operands ( isEnable  : std_logic;
                          EX_MEM    : EX_CONTENT_N; 
                          WB        : WB_CONTENT_N_INSTR;
                          ID_EX     : DECODER_N_INSTR;
                          reg       : REG_DATAS;
                          Forw      : HDU_OUT_N
                         ) return EX_OPERAND_N;      
                         
  function get_alu_res ( f3     : std_logic_vector(FUNCT3_WIDTH-1 downto 0); 
                         f7     : std_logic_vector(FUNCT7_WIDTH-1 downto 0); 
                         A      : std_logic_vector(DATA_WIDTH-1 downto 0);
                         B      : std_logic_vector(DATA_WIDTH-1 downto 0)
                       ) return  ALU_out;     
                         
  function get_alu1_input ( ID_EX       : DECODER_N_INSTR;
                            operands    : EX_OPERAND_N    
                          ) return  ALU_in;    
  
  function get_alu2_input ( reg   : EX_OPERAND_N;
                            Forw  : HDU_OUT_N;  
                            ID_EX : DECODER_N_INSTR;
                            alu1  : ALU_out        
                          ) return  ALU_in;    
                          
  -- Convert enum to std_logic_vector                        
 function encode_control_sig(sig : CONTROL_SIG) return std_logic_vector; 
 function slv_to_control_sig(slv : std_logic_vector(3 downto 0)) return CONTROL_SIG;
 function encode_HAZ_sig(sig : HAZ_SIG) return std_logic_vector;
 function slv_to_haz_sig(slv : std_logic_vector(3 downto 0)) return HAZ_SIG;
 -- return operand value
 function get_operand_val(op : std_logic_vector(6 downto 0); regVal : std_logic_vector(31 downto 0); imm : std_logic_vector(11 downto 0)) return OPERAND2_MEMDATA;

end MyFunctions;