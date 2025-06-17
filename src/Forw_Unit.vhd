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
    variable temp       : EX_OPERAND_N                            := EMPTY_EX_OPERAND_N;
    begin
        temp.S_data1 := ZERO_32bits;
        temp.S_data2 := ZERO_32bits;
        temp.two.A   := ZERO_32bits;  
        temp.two.B   := ZERO_32bits;   
        case Forw.A.forwA is
            when EX_MEM_A    => temp.one.A := EX_MEM.A.alu.result;
            when EX_MEM_B    => temp.one.A := EX_MEM.B.alu.result;
            when MEM_WB_A    => temp.one.A := WB.A.data; 
            when MEM_WB_B    => temp.one.A := WB.B.data; 
            when others      => temp.one.A := reg.one.A; 
        end case;
        
        case Forw.A.forwB is
            when EX_MEM_A    => temp.one.B := EX_MEM.A.alu.result;
            when EX_MEM_B    => temp.one.B := EX_MEM.B.alu.result;
            when MEM_WB_A    => temp.one.B := WB.A.data; 
            when MEM_WB_B    => temp.one.B := WB.B.data; 
            when others      => 
                case ID_EX.A.op is
                    when R_TYPE | B_TYPE => 
                        temp.one.B := reg.one.B;
                    when I_IMME | LOAD =>
                        temp.one.B := std_logic_vector(resize(signed(ID_EX.A.imm12), 32));
                    when S_TYPE => 
                        temp.one.B   := std_logic_vector(resize(signed(ID_EX.A.imm12), 32)); 
                        temp.S_data1 := reg.one.B;
                    when others      => operands.one.B <= (others => '0');
                end case;        
        end case;
        
        temp.is_valid := B_INVALID;
        if Forw.B.is_hold = NONE then
            case Forw.B.forwA is
                when EX_MEM_A    => temp.two.A := EX_MEM.A.alu.result;
                when EX_MEM_B    => temp.two.A := EX_MEM.B.alu.result;
                when MEM_WB_A    => temp.two.A := WB.A.data; 
                when MEM_WB_B    => temp.two.A := WB.B.data; 
                when others      => temp.two.A := reg.two.A; 
            end case;
            
            case Forw.B.forwB is
                when EX_MEM_A    => temp.two.B := EX_MEM.A.alu.result;
                when EX_MEM_B    => temp.two.B := EX_MEM.B.alu.result;
                when MEM_WB_A    => temp.two.B := WB.A.data; 
                when MEM_WB_B    => temp.two.B := WB.B.data; 
                when others      => 
                    case ID_EX.B.op is
                        when R_TYPE | B_TYPE => 
                            temp.two.B := reg.two.B;
                        when I_IMME | LOAD =>
                            temp.two.B := std_logic_vector(resize(signed(ID_EX.B.imm12), 32));
                        when S_TYPE => 
                            temp.two.B   := std_logic_vector(resize(signed(ID_EX.B.imm12), 32));   
                            temp.S_data2 := reg.two.B;         
                        when others      => operands.two.B <= (others => '0');
                    end case;                 
            end case;
            
            temp.is_valid := NONE;
         end if;  
         -- If B is dependent to A, no need to send anything, but we need an identifier if the value shown is invalid.
         operands <= temp; 
    end process;

end Behavioral;
