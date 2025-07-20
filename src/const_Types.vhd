
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
    constant DEPTH          : integer := 1024;
    constant LOG2DEPTH      : integer := 10;
    constant IMM12_WIDTH    : integer := 12;
    constant IMM20_WIDTH    : integer := 20;
    constant FLAGs_WIDTH    : integer := 3;
    constant SHIFT_WIDTH    : integer := 5;
    constant MAX            : integer := 2147483647;
    constant FIVE           : integer := 5;
    constant FOUR           : integer := 4;
    constant CNTRL_WIDTH    : integer := 4;
    constant HAZ_WIDTH      : integer := 4;
    
    constant isFORW_ON      : boolean := true;
    
    constant ONE            : std_logic                                   := '1';
    constant ZERO           : std_logic                                   := '0';
    constant ZERO_32bits    : std_logic_vector(DATA_WIDTH-1 downto 0)     := x"00000000";
    constant ONE_32bits     : std_logic_vector(DATA_WIDTH-1 downto 0)     := x"ffffffff";
    constant ZERO_20bits    : std_logic_vector(IMM20_WIDTH-1 downto 0)    := (others => '0');
    constant ZERO_12bits    : std_logic_vector(IMM12_WIDTH-1 downto 0)    := (others => '0');
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
    
    -- FUNCT3 codes
     -- ALU
    constant FUNC3_ADD_SUB : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "000";
    constant FUNC3_SLL     : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "001";
    constant FUNC3_SLT     : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "010";
    constant FUNC3_SLTU    : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "011";
    constant FUNC3_XOR     : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "100";
    constant FUNC3_SRL_SRA : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "101";
    constant FUNC3_OR      : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "110";
    constant FUNC3_AND     : std_logic_vector(FUNCT3_WIDTH-1 downto 0) := "111";
    
    -- FUNCT7 codes
    constant FUNC7_ADD     : std_logic_vector(FUNCT7_WIDTH-1 downto 0) := "0000000";  -- For ADD
    constant FUNC7_SUB     : std_logic_vector(FUNCT7_WIDTH-1 downto 0) := "0100000";  -- For SUB
    constant FUNC7_SRL     : std_logic_vector(FUNCT7_WIDTH-1 downto 0) := "0000000";  -- For SRL
    constant FUNC7_SRA     : std_logic_vector(FUNCT7_WIDTH-1 downto 0) := "0100000";  -- For SRA
    constant THIRTY_TWO    : std_logic_vector(FUNCT7_WIDTH-1 downto 0) := "0100000";

end package;