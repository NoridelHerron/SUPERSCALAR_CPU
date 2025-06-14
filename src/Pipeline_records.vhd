
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.const_Types.all;
use work.ENUM_T.all;

package Pipeline_Types is

    -- PC and instruction
    type Inst_PC is record
        pc          : std_logic_vector(DATA_WIDTH-1 downto 0);      -- program counter
        instr       : std_logic_vector(DATA_WIDTH-1 downto 0);      -- instructions
        is_valid    : CONTROL_SIG;
    end record;
       
-----------------------------------------ID STAGE------------------------------------------
    -- RS values 
    type REG_DATA_PER is record
        A           : std_logic_vector(DATA_WIDTH-1 downto 0);      
        B           : std_logic_vector(DATA_WIDTH-1 downto 0);      
    end record;
    
    type REG_DATAS is record
        one         : REG_DATA_PER;      
        two         : REG_DATA_PER;      
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
    
    type DECODER_N_INSTR is record
        A           : Decoder_Type;
        B           : Decoder_Type;
    end record;
    
    type RD_CTRL is record
        readWrite   : CONTROL_SIG;
        rd          : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
    end record;
    
    type RD_CTRL_N_INSTR is record
        A           : RD_CTRL;
        B           : RD_CTRL;
    end record;
    
    type HDU_r is record
        forwA       : HAZ_SIG;
        forwB       : HAZ_SIG;
        stall       : HAZ_SIG;
    end record;
    
    type HDU_OUT_N is record
        A          : HDU_r;
        B          : HDU_r;
    end record;
    
    -- control signals
    type control_Type is record
        target     : CONTROL_SIG; -- operand2, branch and jump control signal
        alu        : CONTROL_SIG; -- which data to send as 2nd operand rs2 or imm  
        mem        : CONTROL_SIG; -- for read or write
        wb         : CONTROL_SIG; -- reg
    end record;
   
   -----------------------------------------EX STAGE------------------------------------------
    type ALU_add_sub is record
        result      : std_logic_vector(DATA_WIDTH-1 downto 0);   
        CB          : std_logic;
    end record;
    
    type ALU_in is record
        A           : std_logic_vector(DATA_WIDTH-1 downto 0);   
        B           : std_logic_vector(DATA_WIDTH-1 downto 0);
        f3          : std_logic_vector(FUNCT3_WIDTH-1 downto 0);   
        f7          : std_logic_vector(FUNCT7_WIDTH-1 downto 0);
    end record;
    
    type ALU_out is record
        operation   : ALU_OP;
        result      : std_logic_vector(DATA_WIDTH-1 downto 0);   
        Z           : FLAG_TYPE;
        V           : FLAG_TYPE;
        C           : FLAG_TYPE;
        N           : FLAG_TYPE;
    end record;
    
   type EX_CONTENT is record
        instrType  : INSTRUCTION_T;
        reg_values : REG_DATA_PER;
        alu        : ALU_out; 
    end record;
    
    type EX_CONTENT_N_INSTR is record
        A           : EX_CONTENT;
        B           : EX_CONTENT;
    end record;

    type BranchAndJump_Type is record
        target      : std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_value    : std_logic_vector(DATA_WIDTH-1 downto 0);
    end record;
    
    -----------------------------------------MEM STAGE------------------------------------------
    
    ----------------------------------------- HDU I/O ------------------------------------------   
    type HDU_in is record
        ID          : DECODER_N_INSTR;   
        ID_EX       : DECODER_N_INSTR;   
        EX_MEM      : RD_CTRL_N_INSTR; 
        MEM_WB      : RD_CTRL_N_INSTR;
    end record;
    
end package;