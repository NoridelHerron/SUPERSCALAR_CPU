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
           -- inputs from ex_mem register
           ex_mem         : in  Inst_PC_N;
           exmem_content  : in  EX_CONTENT_N;
           mem_stall      : in  HAZ_SIG;
           -- inputs from mem stage
           memA_result    : in  std_logic_vector(DATA_WIDTH-1 downto 0); 
           -- outputs
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
            -- clear everything
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_MEM_CONTENT_N;
        
        elsif rising_edge(clk) then
            if ex_mem.A.is_valid = VALID then
                reg.A            <= ex_mem.A;
                -- A contents
                reg_content.A.alu <= exmem_content.A.alu.result;
                reg_content.A.rd  <= exmem_content.A.rd;
                reg_content.A.we  <= exmem_content.A.cntrl.wb;
                reg_content.A.me  <= exmem_content.A.cntrl.mem;
                
                if ex_mem.B.is_valid = VALID then
                    -- B contents 
                    reg.B             <= ex_mem.B;
                    reg_content.B.alu <= exmem_content.B.alu.result;
                    reg_content.B.rd  <= exmem_content.B.rd;
                    reg_content.B.we  <= exmem_content.B.cntrl.wb;
                    reg_content.B.me  <= exmem_content.B.cntrl.mem;
                end if;
                
                if (mem_stall = REL_A_WH) or (mem_stall = REL_A_NH) then
                    reg_content.A.mem <= memA_result;
                    if ex_mem.B.is_valid = VALID then
                        reg_content.B.mem <= (others => '0');
                    end if;
                elsif mem_stall = REL_B then
                    reg_content.A.mem <= (others => '0');
                    if ex_mem.B.is_valid = VALID then
                        reg_content.B.mem <= memA_result;
                    end if;
                else
                    reg_content.A.mem <= (others => '0');
                    if ex_mem.B.is_valid = VALID then
                        reg_content.B.mem <= (others => '0');
                    end if;
                end if;
                
           end if;
        end if;    
    end process;

    -- assign output
    mem_wb         <= reg;
    mem_wb_content <= reg_content;

end Behavioral;
