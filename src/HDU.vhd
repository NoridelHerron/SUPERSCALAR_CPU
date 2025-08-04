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

entity HDU is
    Port ( 
            ID          : in  DECODER_N_INSTR;   
            ID_EX       : in  DECODER_N_INSTR; 
            ID_EX_c     : in  control_Type_N;    
            EX_MEM      : in  EX_CONTENT_N; 
            MEM_WB      : in  MEM_CONTENT_N; 
            result      : out HDU_OUT_N
        );
end HDU;

architecture Behavioral of HDU is

begin
    process (ID, ID_EX, ID_EX_c, EX_MEM, MEM_WB)
    variable temp         : HDU_OUT_N := EMPTY_HDU_OUT_N;
    begin
         -- Forwarding logic (always active)
 -------------------------------------------------- INSTRUCTION A --------------------------------------------------
        -- Forward A
        
        if EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.A.rs1 then
            temp.A.ForwA := EX_MEM_B;
        elsif EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.A.rs1 then
            temp.A.ForwA := EX_MEM_A;
        elsif MEM_WB.B.we = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.A.rs1 then
            temp.A.ForwA := MEM_WB_B;
        elsif MEM_WB.A.we = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.A.rs1 then
            temp.A.ForwA := MEM_WB_A;
        else
            temp.A.ForwA := NONE_h;
        end if;
        
        -- Forward B
        if EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.A.rs2 then
            temp.A.ForwB := EX_MEM_B;
        elsif EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.A.rs2 then
            temp.A.ForwB := EX_MEM_A;
        elsif MEM_WB.B.we = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.A.rs2 then
            temp.A.ForwB := MEM_WB_B;
        elsif MEM_WB.A.we = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.A.rs2 then
            temp.A.ForwB := MEM_WB_A;
        else
            temp.A.ForwB := NONE_h;
        end if;
        
        -- STALL A
        if ID_EX_c.A.mem = MEM_READ and  ID_EX.A.rd /= ZERO_5bits and (ID_EX.A.rd = ID.A.rs1 or ID_EX.A.rd = ID.A.rs2) then
            temp.A.stall := A_STALL;  
        elsif ID_EX_c.B.mem = MEM_READ and  ID_EX.B.rd /= ZERO_5bits and (ID_EX.B.rd = ID.A.rs1 or ID_EX.B.rd = ID.A.rs2) then
            temp.A.stall := B_STALL; 
        else
            temp.A.stall := NONE_h;
        end if;

-------------------------------------------------- INSTRUCTION B --------------------------------------------------
        -- In dual-issue, intra-instruction dependencies are checked first  
        -- since they provide the latest register values.
        -- Forward A
        if ID_EX_c.A.wb = REG_WRITE and ID_EX.B.rs1 = ID_EX.A.rd and ID_EX.A.rd /= ZERO_5bits then
            temp.B.ForwA := FORW_FROM_A;
        elsif EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.B.rs1 then
            temp.B.ForwA := EX_MEM_B;
        elsif EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.B.rs1 then
            temp.B.ForwA := EX_MEM_A;
        elsif MEM_WB.B.we = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.B.rs1 then
            temp.B.ForwA := MEM_WB_B;
        elsif MEM_WB.A.we = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.B.rs1 then
            temp.B.ForwA := MEM_WB_A;
        else
            temp.B.ForwA := NONE_h;
        end if;
        
        if ID_EX_c.A.wb = REG_WRITE and ID_EX.B.rs2 = ID_EX.A.rd and ID_EX.A.rd /= ZERO_5bits then
            temp.B.ForwB := FORW_FROM_A; 
        elsif EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.B.rs2 then
            temp.B.ForwB := EX_MEM_B;
        elsif EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.B.rs2 then
            temp.B.ForwB := EX_MEM_A;
        elsif MEM_WB.B.we = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.B.rs2 then
            temp.B.ForwB := MEM_WB_B;
        elsif MEM_WB.A.we = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.B.rs2 then
            temp.B.ForwB := MEM_WB_A;
        else
            temp.B.ForwB := NONE_h;
        end if;
 
        -- STALL B
        -- regular data hazard due to lw
        if ID.A.op = LOAD and  ID.A.rd /= ZERO_5bits and (ID.A.rd = ID.B.rs1 or ID.A.rd = ID.B.rs2)then
            temp.B.stall := STALL_FROM_A; 
        elsif ID_EX_c.A.mem = MEM_READ and  ID_EX.A.rd /= ZERO_5bits and (ID_EX.A.rd = ID.B.rs1 or ID_EX.A.rd = ID.B.rs2) then
            temp.B.stall := A_STALL;  
        elsif ID_EX_c.B.mem = MEM_READ and  ID_EX.B.rd /= ZERO_5bits and (ID_EX.B.rd = ID.B.rs1 or ID_EX.B.rd = ID.B.rs2) then
            temp.B.stall := B_STALL;   
        -- Structural hazard 
       -- elsif ((ID_EX.A.op = LOAD or ID_EX.A.op = S_TYPE) and (ID_EX.B.op = LOAD or ID_EX.B.op = S_TYPE)) then
          --  temp.B.stall := AB_BUSY; 
        elsif ((ID.A.op = LOAD or ID.A.op = S_TYPE) and (ID.B.op = LOAD or ID.B.op = S_TYPE)) then
            temp.B.stall := AB_BUSY; 
        elsif (ID.A.op = LOAD or ID.A.op = S_TYPE) then
            temp.B.stall := REL_A; 
        elsif (ID.B.op = LOAD or ID.B.op = S_TYPE) then
            temp.B.stall := REL_B; 
        else
           temp.B.stall := NONE_h;
        end if;

        result  <= temp;  
    end process;

end Behavioral;