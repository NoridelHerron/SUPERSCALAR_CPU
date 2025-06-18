----------------------------------------------------------------------------------
-- Noridel Herron
-- Create Date: 06/18/2025 10:49:46 AM
-- Module Name: ALU_wrapper - RTL
-- Project Name: Superscalar CPU
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 
use work.initialize_records.all;

entity Forw_wrapper is
    Port (  -- inputs from EM_MEM 
            A1_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
            A2_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0); 
            -- inputs from MEM_WB inputs  
            B1_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
            B2_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0); 
            -- inputs from ID_EX 
            op1         : in  std_logic_vector(OPCODE_WIDTH-1 downto 0);  
            imm12_1     : in  std_logic_vector(IMM12_WIDTH-1 downto 0);
            imm20_1     : in  std_logic_vector(IMM20_WIDTH-1 downto 0);
            op2         : in  std_logic_vector(OPCODE_WIDTH-1 downto 0);  
            imm12_2     : in  std_logic_vector(IMM12_WIDTH-1 downto 0);
            imm20_2     : in  std_logic_vector(IMM20_WIDTH-1 downto 0);
            -- inputs from the registers
            C1_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
            C2_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0);   
            C3_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
            C4_in       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            -- inputs from HDU
            forw1A      : in  std_logic_vector(FOUR-1 downto 0);
            forw1B      : in  std_logic_vector(FOUR-1 downto 0);
            stall1      : in  std_logic_vector(FOUR-1 downto 0);
            is_hold1    : in  std_logic_vector(FOUR-1 downto 0);
            forw2A      : in  std_logic_vector(FOUR-1 downto 0);
            forw2B      : in  std_logic_vector(FOUR-1 downto 0);
            stall2      : in  std_logic_vector(FOUR-1 downto 0);
            is_hold2    : in  std_logic_vector(FOUR-1 downto 0); 
            -- outputs
            D1A_out     : out std_logic_vector(DATA_WIDTH-1 downto 0);  
            D1B_out     : out std_logic_vector(DATA_WIDTH-1 downto 0);   
            D1S_out     : out std_logic_vector(DATA_WIDTH-1 downto 0);
            is_valid    : out std_logic_vector(FOUR-1 downto 0);  
            D2A_out     : out std_logic_vector(DATA_WIDTH-1 downto 0);  
            D2B_out     : out std_logic_vector(DATA_WIDTH-1 downto 0);
            D2S_out     : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
end Forw_wrapper;

architecture rtl of Forw_wrapper is

    signal EX_MEM   : EX_CONTENT_N_INSTR := EMPTY_EX_CONTENT_N_INSTR; 
    signal WB       : WB_data_N_INSTR    := EMPTY_WB_data_N_INSTR; 
    signal ID_EX    : DecForw_N_INSTR    := EMPTY_DecForw_N_INSTR; 
    signal reg      : REG_DATAS          := EMPTY_REG_DATAS; 
    signal Forw     : HDU_OUT_N          := EMPTY_HDU_OUT_N;  
    signal operands : EX_OPERAND_N       := EMPTY_EX_OPERAND_N; 
    
begin
-- Map inputs to records
EX_MEM.A        <= A1_in;       EX_MEM.B        <= A2_in;
WB.A            <= B1_in;       WB.B            <= B2_in;
ID_EX.A.op      <= op1;         ID_EX.B.op      <= op2;      
ID_EX.A.imm12   <= imm12_1;     ID_EX.B.imm12   <= imm12_2;
ID_EX.A.imm20   <= imm20_1;     ID_EX.B.imm20   <= imm20_2;
reg.one.A       <= C1_in;       reg.two.A       <= C3_in;
reg.one.B       <= C2_in;       reg.two.B       <= C4_in;

Forw.A.forwA    <= HAZ_SIG'val(TO_INTEGER(unsigned(forw1A))); 
Forw.A.forwB    <= HAZ_SIG'val(TO_INTEGER(unsigned(forw1B)));   
Forw.A.stall    <= HAZ_SIG'val(TO_INTEGER(unsigned(stall1)));    
Forw.A.is_hold  <= HAZ_SIG'val(TO_INTEGER(unsigned(is_hold1))); 
   
Forw.B.forwA    <= HAZ_SIG'val(TO_INTEGER(unsigned(forw2A)));  
Forw.B.forwB    <= HAZ_SIG'val(TO_INTEGER(unsigned(forw2B)));
Forw.B.stall    <= HAZ_SIG'val(TO_INTEGER(unsigned(stall2)));    
Forw.B.is_hold  <= HAZ_SIG'val(TO_INTEGER(unsigned(is_hold2)));  

-- Map record to outputs
D1A_out         <= operands.one.A;
D1B_out         <= operands.one.B;
D1S_out         <= operands.S_data1;
is_valid        <= std_logic_vector(to_unsigned(HAZ_SIG'pos(operands.is_valid), FOUR));
D2A_out         <= operands.two.A;   
D2B_out         <= operands.two.B;
D2S_out         <= operands.S_data2;

U_Forw_Unit: entity work.Forw_Unit port map (
    EX_MEM    => EX_MEM,
    WB        => WB,
    ID_EX     => ID_EX,
    reg       => reg,
    Forw      => Forw,
    operands  => operands
  );
end rtl;    
