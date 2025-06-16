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
            operands    : out EX_OPERAND_N
          );
end Forw_Unit;

architecture Behavioral of Forw_Unit is

begin
    process (EX_MEM, WB, ID_EX, reg, Forw)
    variable is_B : HAZ_SIG;
    begin
        case Forw.A.forwA is
            when EX_MEM_A    => operands.one.A <= EX_MEM.A.alu.result;
            when EX_MEM_B    => operands.one.A <= EX_MEM.B.alu.result;
            when MEM_WB_A    => operands.one.A <= WB.A.data; 
            when MEM_WB_B    => operands.one.A <= WB.B.data; 
            when others      => operands.one.A <= reg.one.A; 
        end case;
        
        case Forw.A.forwB is
            when EX_MEM_A    => operands.one.B <= EX_MEM.A.alu.result;
            when EX_MEM_B    => operands.one.B <= EX_MEM.B.alu.result;
            when MEM_WB_A    => operands.one.B <= WB.A.data; 
            when MEM_WB_B    => operands.one.B <= WB.B.data; 
            when others      => 
                case ID_EX.A.op is
                    when R_TYPE | B_TYPE => 
                        operands.one.B <= reg.one.B;
                    when I_IMME | LOAD =>
                        operands.one.B <= std_logic_vector(resize(signed(ID_EX.A.imm12), 32));
                    when S_TYPE => 
                        operands.one.B <= std_logic_vector(resize(signed(ID_EX.A.imm12 & '0'), 32));
                     when JAL =>
                        operands.one.B <= std_logic_vector(resize(signed(ID_EX.A.imm20 & '0'), 32));
                    when others      => operands.one.B <= (others => '0');
                end case;        
        end case;
        
        is_B := B_INVALID;
        if Forw.B.is_hold = NONE then
            case Forw.B.forwA is
                when EX_MEM_A    => operands.two.A <= EX_MEM.A.alu.result;
                when EX_MEM_B    => operands.two.A <= EX_MEM.B.alu.result;
                when MEM_WB_A    => operands.two.A <= WB.A.data; 
                when MEM_WB_B    => operands.two.A <= WB.B.data; 
                when others      => operands.two.A <= reg.two.A; 
            end case;
            
            case Forw.B.forwB is
                when EX_MEM_A    => operands.two.B <= EX_MEM.A.alu.result;
                when EX_MEM_B    => operands.two.B <= EX_MEM.B.alu.result;
                when MEM_WB_A    => operands.two.B <= WB.A.data; 
                when MEM_WB_B    => operands.two.B <= WB.B.data; 
                when others      => 
                    case ID_EX.B.op is
                    when R_TYPE | B_TYPE => 
                        operands.two.B <= reg.two.B;
                    when I_IMME | LOAD =>
                        operands.two.B <= std_logic_vector(resize(signed(ID_EX.A.imm12), 32));
                    when S_TYPE => 
                        operands.two.B <= std_logic_vector(resize(signed(ID_EX.A.imm12 & '0'), 32));
                    when JAL =>
                        operands.two.B <= std_logic_vector(resize(signed(ID_EX.A.imm20 & '0'), 32));
                    when others      => operands.two.B <= (others => '0');
                end case;
                 
            end case;
            
            is_B := NONE;
         end if;  
         -- If B is dependent to A, no need to send anything, but we need an identifier if the value shown is invalid.
         operands.is_valid <= is_B; 
    end process;

end Behavioral;
