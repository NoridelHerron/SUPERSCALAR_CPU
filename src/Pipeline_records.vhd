
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
    
    -- PC and instruction for two instructions
    type Inst_PC_N is record
        A           : Inst_PC;     
        B           : Inst_PC;   
    end record;
    
    type Inst_N is record
        A           : std_logic_vector(DATA_WIDTH-1 downto 0); 
        B           : std_logic_vector(DATA_WIDTH-1 downto 0);  
    end record;
    
    type PC_N is record
        A           : std_logic_vector(DATA_WIDTH-1 downto 0);  
        B           : std_logic_vector(DATA_WIDTH-1 downto 0);
    end record;
    
    type valid_N is record
        A           : CONTROL_SIG;  
        B           : CONTROL_SIG;
    end record;
       
-----------------------------------------ID STAGE------------------------------------------
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

    type HDU_r is record
        forwA       : HAZ_SIG;
        forwB       : HAZ_SIG;
        stall       : HAZ_SIG;
    end record;
    
    type HDU_OUT_N is record
        A          : HDU_r;
        B          : HDU_r;
    end record;
    
    type HDU_rV is record
        forwA       : std_logic_vector(HAZ_WIDTH-1 downto 0);
        forwB       : std_logic_vector(HAZ_WIDTH-1 downto 0);
        stall       : std_logic_vector(HAZ_WIDTH-1 downto 0);
    end record;
    
    type HDU_OUT_NV is record
        A          : HDU_rV;
        B          : HDU_rV;
    end record;
    
    -- control signals
    type control_Type is record
        target     : CONTROL_SIG; -- operand2, branch and jump control signal
        alu        : CONTROL_SIG; -- which data to send as 2nd operand rs2 or imm  
        mem        : CONTROL_SIG; -- for read or write
        wb         : CONTROL_SIG; -- reg
    end record;
    
    type control_Type_N is record
        A          : control_Type;
        B          : control_Type;
    end record;
    
    type control_TypeV is record
        target     : std_logic_vector(CNTRL_WIDTH-1 downto 0);   -- operand2, branch and jump control signal
        alu        : std_logic_vector(CNTRL_WIDTH-1 downto 0);   -- which data to send as 2nd operand rs2 or imm  
        mem        : std_logic_vector(CNTRL_WIDTH-1 downto 0);   -- for read or write
        wb         : std_logic_vector(CNTRL_WIDTH-1 downto 0);   -- reg
    end record;
    
    type control_Type_NV is record
        A          : control_TypeV;
        B          : control_TypeV;
    end record;
    
    type RD_CTRL is record
        cntrl       : control_Type;
        rd          : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
    end record;
    
    type RD_CTRL_N_INSTR is record
        A           : RD_CTRL;
        B           : RD_CTRL;
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

    type BranchAndJump_Type is record
        target      : std_logic_vector(DATA_WIDTH-1 downto 0);
        rd_value    : std_logic_vector(DATA_WIDTH-1 downto 0);
    end record;
    
    -----------------------------------------FORWARDING UNIT------------------------------------------ 

    type EX_CONTENT is record
        operand  : REG_DATA_PER;
        alu      : ALU_out;
        S_data   : std_logic_vector(DATA_WIDTH-1 downto 0); 
        cntrl    : control_Type;
        rd       : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
    end record;
    
    type EX_CONTENT_N is record
        A        : EX_CONTENT; 
        B        : EX_CONTENT;  
    end record;
    
    -----------------------------------------MEM STAGE------------------------------------------
    type MEM_CONTENT is record 
        alu       : std_logic_vector(DATA_WIDTH-1 downto 0);
        mem       : std_logic_vector(DATA_WIDTH-1 downto 0);
        rd        : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        we        : CONTROL_SIG; -- write enable
        me        : CONTROL_SIG; -- Determine if memory read
    end record;
    
    type MEM_CONTENT_N is record
        A           : MEM_CONTENT;
        B           : MEM_CONTENT;
    end record;
    
    -----------------------------------------WB STAGE------------------------------------------ 
    
    type WB_CONTENT is record
        data        : std_logic_vector(DATA_WIDTH-1 downto 0);
        rd          : std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        we          : CONTROL_SIG; 
    end record;
    
    type WB_CONTENT_N_INSTR is record
        A           : WB_CONTENT;
        B           : WB_CONTENT;
    end record;
    
    type EX_OPERAND_N is record
        one      : REG_DATA_PER;
        S_data1  : std_logic_vector(DATA_WIDTH-1 downto 0); 
        two      : REG_DATA_PER;
        S_data2  : std_logic_vector(DATA_WIDTH-1 downto 0);
    end record;
    
    type OPERAND2_MEMDATA is record
        operand  : std_logic_vector(DATA_WIDTH-1 downto 0); 
        S_data   : std_logic_vector(DATA_WIDTH-1 downto 0); 
    end record;
end package;