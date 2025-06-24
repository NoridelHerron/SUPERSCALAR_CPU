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
    Port (  clk     : in  std_logic;     
            instr1  : in  std_logic_vector(DATA_WIDTH-1 downto 0);      
            instr2  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            ID_EX   : in  DECODER_N_INSTR; -- from the register between this stage and the ex stage
            EX_MEM  : in  RD_CTRL_N_INSTR; -- from register between ex and mem stage
            MEM_WB  : in  RD_CTRL_N_INSTR; -- from register between mem and wb stage
            WB      : in  WB_CONTENT_N_INSTR; 
            haz     : out HDU_OUT_N;       -- output from hdu
            datas   : out REG_DATAS        -- otput from the register
    );
end ID_STAGE;

architecture Behavioral of ID_STAGE is

signal decoded  : DECODER_N_INSTR := EMPTY_DECODER_N_INSTR; 
signal cntrl    : control_Type_N  := EMPTY_control_Type_N;
signal we1, we2 : std_logic_vector(CNTRL_WIDTH-1 downto 0) := (others => '0');

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
            ID_EX_c     => cntrl,
            EX_MEM      => EX_MEM,
            MEM_WB      => MEM_WB,
            result      => haz
        );
--------------------------------------------------------
-- write or read data to/from the register
--------------------------------------------------------  
we1 <= encode_control_sig(WB.A.we);
we2 <= encode_control_sig(WB.B.we);
    
REGS: entity work.RegFile_wrapper
        port map (
                   clk      => clk, 
                   rd1      => WB.A.rd, 
                   wb_data1 => WB.A.data, 
                   wb_we1   => we1, 
                   rd2      => WB.B.rd, 
                   wb_data2 => WB.B.data, 
                   wb_we2   => we2, 
                   rs1      => decoded.A.rs1, 
                   rs2      => decoded.A.rs2, 
                   rs3      => decoded.B.rs1,
                   rs4      => decoded.B.rs2,
                   reg_data => datas
            );
 
end Behavioral;
