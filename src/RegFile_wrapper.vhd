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
           rd1      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           wb_data1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
           wb_we1   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
           rd2      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           wb_data2 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
           wb_we2   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
           rs1      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           rs2      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           rs3      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           rs4      : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
           reg_data : out REG_DATAS
    );
end RegFile_wrapper;

architecture Behavioral of RegFile_wrapper is

signal rs1_data, rs2_data, rs3_data, rs4_data : std_logic_vector(DATA_WIDTH-1 downto 0);

    component Register_file
        port (
            clk       : in  std_logic;
            rd1       : in  std_logic_vector(4 downto 0);
            wb_data1  : in  std_logic_vector(31 downto 0);
            wb_we1    : in  std_logic_vector(3 downto 0);
            rd2       : in  std_logic_vector(4 downto 0);
            wb_data2  : in  std_logic_vector(31 downto 0);
            wb_we2    : in  std_logic_vector(3 downto 0);
            rs1       : in  std_logic_vector(4 downto 0);
            rs2       : in  std_logic_vector(4 downto 0);
            rs3       : in  std_logic_vector(4 downto 0);
            rs4       : in  std_logic_vector(4 downto 0);
            rs1_data  : out std_logic_vector(31 downto 0);
            rs2_data  : out std_logic_vector(31 downto 0);
            rs3_data  : out std_logic_vector(31 downto 0);
            rs4_data  : out std_logic_vector(31 downto 0)
        );
    end component;

begin
   
    -- Instantiate original ALU
    u_alu: Register_file port map (
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
