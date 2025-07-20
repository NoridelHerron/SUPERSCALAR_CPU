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
use work.MyFunctions.all;

entity Forw_Unit is
    Port ( 
            EX_MEM      : in EX_CONTENT_N; 
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
    variable temp       : EX_OPERAND_N     := EMPTY_EX_OPERAND_N;
    variable operA      : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA;
    variable operB      : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA;
    begin
        temp.S_data1 := ZERO_32bits;
        temp.S_data2 := ZERO_32bits;
        temp.two.A   := ZERO_32bits;  
        temp.two.B   := ZERO_32bits;   
        
        case Forw.A.forwA is
            when NONE_h      => temp.one.A := reg.one.A; 
            when EX_MEM_A    => temp.one.A := EX_MEM.A.alu.result;
            when EX_MEM_B    => temp.one.A := EX_MEM.B.alu.result;
            when MEM_WB_A    => temp.one.A := WB.A.data; 
            when MEM_WB_B    => temp.one.A := WB.B.data; 
            when others      => temp.one.A := ZERO_32bits;
        end case;
        
        case Forw.A.forwB is
            when NONE_h      =>
                operA        := get_operand_val (ID_EX.A.op, reg.one.B, ID_EX.A.imm12);
                temp.one.B   := operA.operand;
                temp.S_data1 := operA.S_data; 
            when EX_MEM_A    => temp.one.B := EX_MEM.A.alu.result;
            when EX_MEM_B    => temp.one.B := EX_MEM.B.alu.result;
            when MEM_WB_A    => temp.one.B := WB.A.data; 
            when MEM_WB_B    => temp.one.B := WB.B.data; 
            when others      => temp.one.B := ZERO_32bits;
                
        end case;

        if Forw.B.forwA /= FORW_FROM_A then
            case Forw.B.forwA is
                when NONE_h      => temp.two.A := reg.two.A; 
                when EX_MEM_A    => temp.two.A := EX_MEM.A.alu.result;
                when EX_MEM_B    => temp.two.A := EX_MEM.B.alu.result;
                when MEM_WB_A    => temp.two.A := WB.A.data; 
                when MEM_WB_B    => temp.two.A := WB.B.data; 
                when others      => temp.two.A := ZERO_32bits;
            end case;
        end if;
        
        if Forw.B.forwB /= FORW_FROM_A then    
            case Forw.B.forwB is
                when NONE_h =>
                    operB        := get_operand_val (ID_EX.B.op, reg.two.B, ID_EX.B.imm12);
                    temp.two.B   := operB.operand;
                    temp.S_data2 := operB.S_data;
                when EX_MEM_A    => temp.two.B := EX_MEM.A.alu.result;
                when EX_MEM_B    => temp.two.B := EX_MEM.B.alu.result;
                when MEM_WB_A    => temp.two.B := WB.A.data; 
                when MEM_WB_B    => temp.two.B := WB.B.data; 
                when others      => temp.two.B := ZERO_32bits;               
            end case;
         end if;  
         -- If B is dependent to A, no need to send anything, but we need an identifier if the value shown is invalid.
         operands <= temp; 
    end process;

end Behavioral;