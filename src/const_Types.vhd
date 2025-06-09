
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package const_Types is
    
    -- scalability 
    constant OPCODE_WIDTH   : integer := 7;
    constant DATA_WIDTH     : integer := 32;
    constant REG_ADDR_WIDTH : integer := 5;
    constant FUNCT3_WIDTH   : integer := 3;
    constant FUNCT7_WIDTH   : integer := 7;
    constant DEPTH          : integer := 4;
    constant LOG2DEPTH      : integer := 2;
    constant IMM_WIDTH      : integer := 12;
    constant IMMJ_WIDTH     : integer := 20;
    constant FLAGs_WIDTH    : integer := 3;
    constant SHIFT_WIDTH    : integer := 5;
    constant MAX            : integer := 2147483647;
    
    constant ONE            : std_logic                                   := '1';
    constant ZERO           : std_logic                                   := '0';
    constant ZERO_32bits    : std_logic_vector(DATA_WIDTH-1 downto 0)     := "00000000000000000000000000000000";
    constant ONE_32bits     : std_logic_vector(DATA_WIDTH-1 downto 0)     := "11111111111111111111111111111111";
    constant ZERO_20bits    : std_logic_vector(IMMJ_WIDTH-1 downto 0)     := (others => '0');
    constant ZERO_12bits    : std_logic_vector(IMM_WIDTH-1 downto 0)      := (others => '0');
    constant ZERO_7bits     : std_logic_vector(FUNCT7_WIDTH-1 downto 0)   := (others => '0');
    constant ZERO_5bits     : std_logic_vector(REG_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant ZERO_3bits     : std_logic_vector(FUNCT3_WIDTH-1 downto 0)   := (others => '0');

    -- NOP
    constant NOP            : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000013";

    -- OPCODE TYPE
    constant R_TYPE         : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0110011";
    constant I_IMME         : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0010011";
    constant LOAD           : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0000011";
    constant S_TYPE         : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0100011";
    constant B_TYPE         : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1100011";
    constant JAL            : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1101111";
    constant JALR           : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1100111";  
    constant U_LUI          : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0110111";
    constant U_AUIPC        : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "0010111";
    constant ECALL          : std_logic_vector(OPCODE_WIDTH-1 downto 0) := "1110111";
    
    -- BRANCHING
    constant BEQ           : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "000";
    constant BNE           : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "001";
    constant BLT           : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "100";
    constant BGE           : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "101";
    constant BLTU          : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "110";
    constant BGEU          : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "111";

end package;