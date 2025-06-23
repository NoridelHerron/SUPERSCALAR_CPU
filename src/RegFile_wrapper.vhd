------------------------------------------------------------------------------
-- Noridel Herron
-- 6/22/2025
-- Register File wrapper
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

entity RegFile_wrapper is
    Port ( clk      : in  std_logic; 
           WB       : in WB_CONTENT_N_INSTR;
           rs1      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           rs2      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           rs3      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           rs4      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           reg_data : out REG_DATAS
    );
end RegFile_wrapper;

architecture Behavioral of RegFile_wrapper is

-- Signals for Verilog Register_file ports
signal rd1      : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
signal wb_data1 : std_logic_vector(DATA_WIDTH-1 downto 0);
signal wb_we1   : std_logic;

signal rd2      : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
signal wb_data2 : std_logic_vector(DATA_WIDTH-1 downto 0);
signal wb_we2   : std_logic;

signal rs1_data, rs2_data, rs3_data, rs4_data : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

wb_we1   <= '1' when WB.A.we = REG_WRITE else '0';
rd1      <= WB.A.rd;
wb_data1 <= WB.A.data;

wb_we2   <= '1' when WB.B.we = REG_WRITE else '0';
rd2      <= WB.B.rd;
wb_data2 <= WB.B.data;
   
    -- Instantiate original ALU
    u_alu: entity work.Register_file port map (
            clk      => clk,
            rd1      => rd1,
            wb_data1 => wb_data1,
            wb_we1   => wb_we1,
            rd2      => rd2,
            wb_data2 => wb_data2,
            wb_we2   => wb_we2,
            rs1      => rs1,
            rs2      => rs2,
            rs3      => rs3,
            rs4      => rs4,
            rs1_data => rs1_data,
            rs2_data => rs2_data,
            rs3_data => rs3_data,
            rs4_data => rs4_data
            );
            
    -- Assign outputs
    reg_data.one.A <= rs1_data;
    reg_data.one.B <= rs2_data;
    reg_data.two.A <= rs3_data;
    reg_data.two.B <= rs4_data;
    
end Behavioral;
