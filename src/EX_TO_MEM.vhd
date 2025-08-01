------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- ID_EX Register
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

entity EX_TO_MEM is
    Port ( 
            clk            : in  std_logic; 
            reset          : in  std_logic;  -- added reset input 
            haz            : in  HDU_OUT_N;
            EX             : in  Inst_PC_N;
            EX_val         : in  EX_CONTENT_N; 
          --  is_ready       : out  std_logic;
            is_busy        : out  HAZ_SIG;
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

signal reg         : Inst_PC_N    := EMPTY_Inst_PC_N;
signal reg_content : EX_CONTENT_N := EMPTY_EX_CONTENT_N;
signal is_memHaz   : HAZ_SIG      := NONE_h;
signal is_check    : std_logic    := '0';
--signal isSend      : std_logic    := '0';

begin
    
    process(clk, reset)
    variable reg_v         : Inst_PC_N      := EMPTY_Inst_PC_N;
    variable reg_content_v : EX_CONTENT_N   := EMPTY_EX_CONTENT_N;
    begin
        if reset = '1' then  
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;
     
        elsif rising_edge(clk) then
            if haz.B.stall = AB_BUSY and is_check = '0' then
                reg.A           <= EX.A;
                reg.B.is_valid  <= INVALID;
                is_memHaz       <= A_BUSY;
                is_check        <= '1';
                
            elsif is_check = '1' and is_memHaz = A_BUSY then
                reg.B           <= EX.B;
                reg.A.is_valid  <= INVALID;
                is_memHaz       <= B_BUSY;
                is_check        <= '1';
                
               -- if haz.A.stall = B_STILL_BUSY then
               --     isSend <= '0';
              --  else
               --     isSend <= '1';
               -- end if;
  
            elsif is_check = '1' and is_memHaz = B_BUSY and haz.A.stall = B_STILL_BUSY then
                reg.A.is_valid  <= INVALID;
                reg.B.is_valid  <= INVALID;
                is_memHaz       <= B_STILL_BUSY;
                is_check        <= '0'; 
                
            else
                reg             <= EX;
                reg_content     <= EX_val;     
                is_check        <= '0';    
                is_memHaz       <= SEND_BOTH;
              
            end if;
        
        end if; 
    end process;
    
    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;
    is_busy        <= is_memHaz;
  --  is_ready
    
end Behavioral;
