
library ieee;
use ieee.std_logic_1164.all;
use work.const_Types.all;
use work.enum_types.all;

package Pipeline_Types is

    -- PC and instruction
    type Inst_PC is record
        instr       : std_logic_vector(DATA_WIDTH-1 downto 0);      -- instructions
        pc          : std_logic_vector(DATA_WIDTH-1 downto 0);      -- program counter
    end record;
    
    -- Decoder records 
    type Decoder_Type is record
        op          : std_logic_vector(OPCODE_WIDTH-1 downto 0);    -- opcode  
        rd          : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);  -- register destination
        funct3      : std_logic_vector(FUNCT3_WIDTH-1 downto 0);    -- type of operation
        rs1         : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);  -- register source 1
	    rs2         : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);  -- register source 2
        funct7      : std_logic_vector(FUNCT7_WIDTH-1 downto 0);    -- type of operation under funct3 
        imm12       : std_logic_vector(IMM12_WIDTH-1 downto 0); 
        imm20       : std_logic_vector(IMM20_WIDTH-1 downto 0); 
    end record;
    
    type control_Type is record
        mem_read    : CONTROL_SIG;
        mem_write   : CONTROL_SIG;
        reg_write   : CONTROL_SIG;
        alu         : CONTROL_SIG;
    end record;
    
    type BranchAndJump_Type is record
        branch      : std_logic;
        target      : std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_value    : std_logic_vector(DATA_WIDTH-1 downto 0);
    end record;
    
    
    
end package;