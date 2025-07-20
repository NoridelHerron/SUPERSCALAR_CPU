------------------------------------------------------------------------------
-- Noridel Herron
-- 6/13/2025
-- Detects data hazards
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 
use work.initialize_records.all;
use work.MyFunctions.all;

entity hdu_wrapper is
    Port (  ida_rs1     : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            ida_rs2     : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idb_rs1     : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idb_rs2     : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexa_rd    : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexa_rs1   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexa_rs2   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexa_mem   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            idexa_wb    : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            idexb_rd    : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexb_rs1   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexb_rs2   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            idexb_mem   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            idexb_wb    : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            exmema_wb   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            exmema_rd   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            exmemb_wb   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            exmemb_rd   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            memwba_wb   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            memwba_rd   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            memwbb_wb   : in  std_logic_vector(CNTRL_WIDTH-1 downto 0);
            memwbb_rd   : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
            aforwa      : out std_logic_vector(HAZ_WIDTH-1 downto 0);
            aforwb      : out std_logic_vector(HAZ_WIDTH-1 downto 0);
            aforws      : out std_logic_vector(HAZ_WIDTH-1 downto 0);
            bforwa      : out std_logic_vector(HAZ_WIDTH-1 downto 0);
            bforwb      : out std_logic_vector(HAZ_WIDTH-1 downto 0);
            bforws      : out std_logic_vector(HAZ_WIDTH-1 downto 0)
        );
end hdu_wrapper;

architecture Behavioral of hdu_wrapper is

signal ID          : DECODER_N_INSTR := EMPTY_DECODER_N_INSTR;  
signal ID_EX       : DECODER_N_INSTR := EMPTY_DECODER_N_INSTR;  
signal ID_EX_c     : control_Type_N  := EMPTY_control_Type_N; 
signal EX_MEM      : EX_CONTENT_N    := EMPTY_EX_CONTENT_N; 
signal MEM_WB      : MEM_CONTENT_N   := EMPTY_MEM_CONTENT_N; 
signal result      : HDU_OUT_N       := EMPTY_HDU_OUT_N;

begin
    ID.A.rs1            <= ida_rs1;
    ID.A.rs2            <= ida_rs2;
    ID.B.rs1            <= idb_rs1;
    ID.B.rs2            <= idb_rs2;
    ID_EX.A.rd          <= idexa_rd;
    ID_EX.A.rs1         <= idexa_rs1;
    ID_EX.A.rs2         <= idexa_rs2;
    ID_EX_c.A.mem       <= slv_to_control_sig(idexa_mem);
    ID_EX_c.A.wb        <= slv_to_control_sig(idexa_wb);
    ID_EX.B.rd          <= idexb_rd;
    ID_EX.B.rs1         <= idexb_rs1;
    ID_EX.B.rs2         <= idexb_rs2;
    ID_EX_c.B.mem       <= slv_to_control_sig(idexb_mem);
    ID_EX_c.B.wb        <= slv_to_control_sig(idexb_wb);
    EX_MEM.A.rd         <= exmema_rd;
    EX_MEM.A.cntrl.wb   <= slv_to_control_sig(exmema_wb);
    EX_MEM.B.rd         <= exmemb_rd;
    EX_MEM.B.cntrl.wb   <= slv_to_control_sig(exmemb_wb);
    MEM_WB.A.rd         <= memwba_rd;
    MEM_WB.A.we         <= slv_to_control_sig(memwba_wb);
    MEM_WB.B.rd         <= memwbb_rd;
    MEM_WB.B.we         <= slv_to_control_sig(memwbb_wb);
    
    U_HDU: entity work.HDU
        port map (
            ID          => ID,
            ID_EX       => ID_EX,
            ID_EX_c     => ID_EX_c,
            EX_MEM      => EX_MEM,
            MEM_WB      => MEM_WB,
            result      => result
        );
        
    -- ASSIGN OUTPUT
    aforwa  <= encode_HAZ_sig(result.A.forwA);
    aforwb  <= encode_HAZ_sig(result.A.forwB);
    aforws  <= encode_HAZ_sig(result.A.stall);
    bforwa  <= encode_HAZ_sig(result.B.forwA);
    bforwb  <= encode_HAZ_sig(result.B.forwB);
    bforws  <= encode_HAZ_sig(result.B.stall);

end Behavioral;
