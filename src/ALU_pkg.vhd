
library ieee;
use ieee.std_logic_1164.all;
use work.Pipeline_Types.all;
use work.const_Types.all;   
use work.enum_types.all;
    
package ALU_pkg is
    
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
    
    type ALU_in is record
        A           : std_logic_vector(DATA_WIDTH-1 downto 0);   
        B           : std_logic_vector(DATA_WIDTH-1 downto 0);
        f3          : std_logic_vector(FUNCT3_WIDTH-1 downto 0);   
        f7          : std_logic_vector(FUNCT7_WIDTH-1 downto 0);
    end record;
    
    type ALU_out is record
        result      : std_logic_vector(DATA_WIDTH-1 downto 0);   
        Z           : FLAG_TYPE;
        V           : FLAG_TYPE;
        C           : FLAG_TYPE;
        N           : FLAG_TYPE;
    end record;

end package;