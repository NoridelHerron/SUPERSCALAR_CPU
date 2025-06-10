
library ieee;
use ieee.std_logic_1164.all;
use work.const_Types.all;

package Pipeline_Types is

    type CONTROL_SIG is ( 
        -- memory and register control signal
        MEM_READ, MEM_WRITE, -- for load or store
        REG_WRITE,           -- wb
        MEM_REG, ALU_REG,    -- source result whether from alu or memory
        BRANCH, JUMP, 
        RS2, IMM,            -- for operand 2
        NONE
    );

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
    
    -- control signals
    type control_Type is record
        target  : CONTROL_SIG; -- operand2, branch and jump control signal
        alu     : CONTROL_SIG; -- which data to send as 2nd operand rs2 or imm  
        mem     : CONTROL_SIG; -- for read or write
        wb      : CONTROL_SIG; -- reg
    end record;

    type BranchAndJump_Type is record
        target      : std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_value    : std_logic_vector(DATA_WIDTH-1 downto 0);
    end record;
    
    
    
end package;