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
    generic (ENABLE_FORWARDING : boolean := isFORW_ON);
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
    if ENABLE_FORWARDING then   
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
            if ID_EX.A.op = S_TYPE and Forw.A.forwB /= NONE_h then
                operA        := get_operand_val (ID_EX.A.op, temp.one.B, ID_EX.A.imm12);
                temp.one.B   := operA.operand;
                temp.S_data1 := operA.S_data;
            end if;
        
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
                when EX_MEM_A    => 
                    temp.two.B := EX_MEM.A.alu.result;
                when EX_MEM_B    => 
                    temp.two.B := EX_MEM.B.alu.result;
                when MEM_WB_A    => 
                    temp.two.B := WB.A.data; 
                when MEM_WB_B    => 
                    temp.two.B := WB.B.data; 
                when others      => 
                    temp.two.B := ZERO_32bits;               
            end case;
            if ID_EX.B.op = S_TYPE and Forw.B.forwB /= NONE_h then
                operB        := get_operand_val (ID_EX.B.op, temp.two.B, ID_EX.B.imm12);
                temp.two.B   := operB.operand;
                temp.S_data2 := operB.S_data;
            end if;
         end if;  
    else
        
        temp.one.A   := reg.one.A;
        temp.two.A   := reg.two.A; 
        
        if ID_EX.A.op = S_TYPE or ID_EX.A.op = LOAD or ID_EX.A.op = I_IMME then
            temp.one.B   := std_logic_vector(resize(signed(ID_EX.A.imm12), 32)); 
            if ID_EX.A.op = S_TYPE then
                temp.S_data1 := reg.one.B;
            end if;
        else
            temp.one.B := reg.one.B;
        end if; 
        
        if ID_EX.B.op = S_TYPE or ID_EX.B.op = LOAD or ID_EX.B.op = I_IMME then
            temp.two.B   := std_logic_vector(resize(signed(ID_EX.B.imm12), 32)); 
            if ID_EX.B.op = S_TYPE then
                temp.S_data2 := reg.two.B;
            end if;
        else
            temp.two.B := reg.two.B;
        end if; 
       
    end if;
    
         operands <= temp; 
    end process;

end Behavioral;