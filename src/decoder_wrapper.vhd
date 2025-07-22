------------------------------------------------------------------------------
-- Noridel Herron
-- 7/11/2025
-- This wrapper is written for the testbench written in sv
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;

entity decoder_wrapper is
    Port (  instr   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            op      : out std_logic_vector(OPCODE_WIDTH-1 downto 0);    -- opcode  
            rd      : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);  -- register destination
            funct3  : out std_logic_vector(FUNCT3_WIDTH-1 downto 0);    -- type of operation
            rs1     : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);  -- register source 1
            rs2     : out std_logic_vector(REG_ADDR_WIDTH-1 downto 0);  -- register source 2
            funct7  : out std_logic_vector(FUNCT7_WIDTH-1 downto 0);    -- type of operation under funct3 
            imm12   : out std_logic_vector(IMM12_WIDTH-1 downto 0); 
            imm20   : out std_logic_vector(IMM20_WIDTH-1 downto 0) 
        );
end decoder_wrapper;

architecture Behavioral of decoder_wrapper is

signal decoded : Decoder_Type := EMPTY_DECODER;  

begin

    U_DECODER: entity work.DECODER
        port map (
            ID          => instr, 
            ID_content  => decoded
        );
    process (decoded)
    begin
        op      <= decoded.op;
        rd      <= decoded.rd;
        funct3  <= decoded.funct3;
        rs1     <= decoded.rs1;
        rs2     <= decoded.rs2;
        funct7  <= decoded.funct7;
        imm12   <= decoded.imm12;
        imm20   <= decoded.imm20;
    end process;
    
end Behavioral;
