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
            EX_MEM   : in  RD_CTRL_N_INSTR; -- from register between ex and mem stage
            MEM_WB   : in  RD_CTRL_N_INSTR; -- from register between mem and wb stage
            rd1      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            wb_data1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            wb_we1   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            rd2      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            wb_data2 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            wb_we2   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            ID_out   : out DECODER_N_INSTR;
            cntrl    : out control_Type_N;
            haz      : out HDU_OUT_N;       -- output from hdu
            datas    : out REG_DATAS        -- otput from the register
    );
end ID_STAGE;

architecture Behavioral of ID_STAGE is

signal decoded      : DECODER_N_INSTR := EMPTY_DECODER_N_INSTR; 
signal cntrl_temp   : control_Type_N  := EMPTY_control_Type_N;
signal haz_temp     : HDU_OUT_N       := EMPTY_HDU_OUT_N;
signal datas_temp   : REG_DATAS       := EMPTY_REG_DATAS;

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
            ctrl_sig    => cntrl_temp.A
        );
        
    CONTROl_UNIT_2: entity work.control_gen
        port map (
            opcode      => decoded.B.op, 
            ctrl_sig    => cntrl_temp.B
        );
--------------------------------------------------------
-- Detect Hazards
--------------------------------------------------------        
    HAZARD_DETECTOR: entity work.HDU
        port map (
            ID          => decoded, 
            ID_EX       => ID_EX,
            ID_EX_c     => cntrl_temp,
            EX_MEM      => EX_MEM,
            MEM_WB      => MEM_WB,
            result      => haz_temp
        );
--------------------------------------------------------
-- write or read data to/from the register
--------------------------------------------------------  

REGS: entity work.RegFile_wrapper
        port map (
                   clk      => clk, 
                   rd1      => rd1, 
                   wb_data1 => wb_data1, 
                   wb_we1   => wb_we1, 
                   rd2      => rd2, 
                   wb_data2 => wb_data2, 
                   wb_we2   => wb_we2, 
                   rs1      => decoded.A.rs1, 
                   rs2      => decoded.A.rs2, 
                   rs3      => decoded.B.rs1,
                   rs4      => decoded.B.rs2,
                   reg_data => datas_temp
            );

-- output assignment
ID_out  <= decoded;
cntrl   <= cntrl_temp;
haz     <= haz_temp;
datas   <= datas_temp;
end Behavioral;
