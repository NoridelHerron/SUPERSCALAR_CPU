------------------------------------------------------------------------------
-- Noridel Herron
-- 7/16/2025
-- MEM_WB Register
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;
--use work.MyFunctions.all;
entity MEM_WB is
    Port ( 
           clk            : in   std_logic; 
           reset          : in   std_logic; 
           ex_mem         : in  Inst_PC_N;
           exmem_content  : in  EX_CONTENT_N;
           ex_cntrl       : in  control_Type_N;
           memA_result    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
           memB_result    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
           mem_wb         : out Inst_PC_N;  
           mem_wb_content : out MEM_CONTENT_N  
        );
        
end MEM_WB;

architecture Behavioral of MEM_WB is

signal reg         : Inst_PC_N      := EMPTY_Inst_PC_N;
signal reg_content : MEM_CONTENT_N := EMPTY_MEM_CONTENT_N;

begin
    process(clk, reset)
    begin
        if reset = '1' then  
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_MEM_CONTENT_N;
        
        elsif rising_edge(clk) then
            reg               <= ex_mem;
            -- A contents
            reg_content.A.mem <= memA_result;
            reg_content.A.alu <= exmem_content.A.alu.result;
            reg_content.A.rd  <= exmem_content.A.rd;
            reg_content.A.we  <= ex_cntrl.A.wb;
            reg_content.A.me  <= ex_cntrl.A.mem;
            -- B contents
            reg_content.B.mem <= memB_result;
            reg_content.B.alu <= exmem_content.B.alu.result;
            reg_content.B.rd  <= exmem_content.B.rd;
            reg_content.B.we  <= ex_cntrl.B.wb;
            reg_content.B.me  <= ex_cntrl.B.mem;
        end if;    
    end process;

    mem_wb         <= reg;
    mem_wb_content <= reg_content;


end Behavioral;
