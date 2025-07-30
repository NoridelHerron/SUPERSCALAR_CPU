-----------------------------------------------------------------------------
-- Noridel Herron
-- 6/24/2025
-- Execute Stage (EX)
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;
use work.MyFunctions.all;

entity ID_STAGE is
    Port (  clk      : in  std_logic;     
            instr1   : in  std_logic_vector(DATA_WIDTH-1 downto 0);      
            instr2   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            ID_EX    : in  DECODER_N_INSTR; -- from the register between this stage and the ex stage
            ID_EX_c  : in  control_Type_N;
            EX_MEM   : in  EX_CONTENT_N; -- from register between ex and mem stage     
            MEM_WB   : in  MEM_CONTENT_N; -- from register between ex and mem stage
            WB       : in  WB_CONTENT_N_INSTR;
            ID       : out DECODER_N_INSTR;
            cntrl    : out control_Type_N;
            haz      : out HDU_OUT_N;       -- output from hdu
            datas    : out REG_DATAS        -- otput from the register
    );
end ID_STAGE;

architecture Behavioral of ID_STAGE is

signal decoded  : DECODER_N_INSTR := EMPTY_DECODER_N_INSTR; 
signal haz_temp : HDU_OUT_N       := EMPTY_HDU_OUT_N;

begin
--------------------------------------------------------
-- Decode the instructions
--------------------------------------------------------
    DECODER_1: entity work.DECODER
        port map (
            ID          => instr1, 
            ID_content  => decoded.A
        );
        
    DECODER_2: entity work.DECODER
        port map (
            ID          => instr2, 
            ID_content  => decoded.B
        );
--------------------------------------------------------
-- Generate Control Signal
--------------------------------------------------------     
  
    CONTROl_UNIT_1: entity work.control_gen
        port map (
            opcode      => decoded.A.op, 
            ctrl_sig    => cntrl.A
        );
        
    CONTROl_UNIT_2: entity work.control_gen
        port map (
            opcode      => decoded.B.op, 
            ctrl_sig    => cntrl.B
        );
--------------------------------------------------------
-- Detect Hazards
--------------------------------------------------------     
    HAZARD_DETECTOR: entity work.HDU
        port map (
            ID          => decoded, 
            ID_EX       => ID_EX,
            ID_EX_c     => ID_EX_c,
            EX_MEM      => EX_MEM,
            MEM_WB      => MEM_WB,
            result      => haz
        );
--------------------------------------------------------
-- write or read data to/from the register
--------------------------------------------------------  
    REGS: entity work.RegFile_wrapper
        port map (
            clk      => clk, 
            WB       => WB,
            ID       => decoded,
            reg_data => datas
        );
  
    ID <= decoded;
    
end Behavioral;
