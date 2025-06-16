------------------------------------------------------------------------------
-- Noridel Herron
-- Date: 6/16/2025
-- Forwarding Unit for Dual-Issue Superscalar RISC-V CPU
-- 
-- This module implements forwarding logic to resolve data hazards (RAW) 
-- between instructions issued in the same cycle (intra-cycle forwarding) 
-- as well as across pipeline stages (inter-cycle forwarding).
--
-- It determines operand sources dynamically, enabling correct and efficient 
-- execution without unnecessary stalls in a dual-issue pipeline.
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

entity Forw_Unit is
    Port ( 
            EX_MEM      : in EX_CONTENT_N_INSTR; 
            WB          : in WB_CONTENT_N_INSTR;
            ID_EX       : in DECODER_N_INSTR;
            reg         : in REG_DATAS;
            Forw        : in HDU_OUT_N;   
            operands    : out REG_DATAS
          );
end Forw_Unit;

architecture Behavioral of Forw_Unit is

begin
    process (EX_MEM, WB, ID_EX, reg, Forw)
    begin
        case Forw.A.forwA is
            when EX_MEM_A => operands.one.A <= EX_MEM.A.alu.result;
            when EX_MEM_B => operands.one.A <= EX_MEM.B.alu.result;
            when MEM_WB_A => operands.one.A <= WB.A.data; 
            when MEM_WB_B => operands.one.A <= WB.B.data; 
            when others   => operands.one.A <= reg.one.A; 
        end case;
        
        case Forw.A.forwB is
            when EX_MEM_A => operands.one.B <= EX_MEM.A.alu.result;
            when EX_MEM_B => operands.one.B <= EX_MEM.B.alu.result;
            when MEM_WB_A => operands.one.B <= WB.A.data; 
            when MEM_WB_B => operands.one.B <= WB.B.data; 
            when others   => operands.one.B <= reg.one.B; 
        end case;
        
        case Forw.B.forwA is
            when EX_MEM_A => operands.two.A <= EX_MEM.A.alu.result;
            when EX_MEM_B => operands.two.A <= EX_MEM.B.alu.result;
            when MEM_WB_A => operands.two.A <= WB.A.data; 
            when MEM_WB_B => operands.two.A <= WB.B.data; 
            when others   => operands.two.A <= reg.two.A; 
        end case;
        
        case Forw.B.forwB is
        when others => 
        end case;
        
    end process;

end Behavioral;
