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
            H       : in  HDU_in;  
            result  : out HDU_OUT_N
        );
end HDU;

architecture Behavioral of HDU is

begin
    process (H)
    variable temp : HDU_OUT_N := EMPTY_HDU_OUT_N;
    begin
         -- Forwarding logic (always active)
 -------------------------------------------------- INSTRUCTION A --------------------------------------------------
        -- Forward A
        if H.EX_MEM.A.readWrite = REG_WRITE and H.EX_MEM.A.rd /= ZERO_5bits and H.EX_MEM.A.rd = H.ID_EX.A.rs1 then
            temp.A.ForwA := EX_MEM_A;
        elsif H.EX_MEM.B.readWrite = REG_WRITE and H.EX_MEM.B.rd /= ZERO_5bits and H.EX_MEM.B.rd = H.ID_EX.A.rs1 then
            temp.A.ForwA := EX_MEM_B;
        elsif H.MEM_WB.A.readWrite = REG_WRITE and H.MEM_WB.A.rd /= ZERO_5bits and H.MEM_WB.A.rd = H.ID_EX.A.rs1 then
            temp.A.ForwA := MEM_WB_A;
        elsif H.MEM_WB.B.readWrite = REG_WRITE and H.MEM_WB.B.rd /= ZERO_5bits and H.MEM_WB.B.rd = H.ID_EX.A.rs1 then
            temp.A.ForwA := MEM_WB_B;
        else
            temp.A.ForwA := NONE;
        end if;
        -- Forward B
        if H.EX_MEM.A.readWrite = REG_WRITE and H.EX_MEM.A.rd /= ZERO_5bits and H.EX_MEM.A.rd = H.ID_EX.A.rs2 then
            temp.A.ForwB := EX_MEM_A;
        elsif H.EX_MEM.B.readWrite = REG_WRITE and H.EX_MEM.B.rd /= ZERO_5bits and H.EX_MEM.B.rd = H.ID_EX.A.rs2 then
            temp.A.ForwB := EX_MEM_B;
        elsif H.MEM_WB.A.readWrite = REG_WRITE and H.MEM_WB.A.rd /= ZERO_5bits and H.MEM_WB.A.rd = H.ID_EX.A.rs2 then
            temp.A.ForwB := MEM_WB_A;
        elsif H.MEM_WB.B.readWrite = REG_WRITE and H.MEM_WB.B.rd /= ZERO_5bits and H.MEM_WB.B.rd = H.ID_EX.A.rs2 then
            temp.A.ForwB := MEM_WB_B;
        else
            temp.A.ForwB := NONE;
        end if;
        
        -- STALL A
        if H.ID_EX.A.op = LOAD and  H.ID_EX.A.rd /= ZERO_5bits and (H.ID_EX.A.rd = H.ID.A.rs1 or H.ID_EX.A.rd = H.ID.A.rs2) then
            temp.A.stall := A_STALL;  
        elsif H.ID_EX.B.op = LOAD and  H.ID_EX.B.rd /= ZERO_5bits and (H.ID_EX.B.rd = H.ID.A.rs1 or H.ID_EX.B.rd = H.ID.A.rs2) then
            temp.A.stall := B_STALL;     
        else
            temp.A.stall := NONE;
        end if;

-------------------------------------------------- INSTRUCTION B --------------------------------------------------
        -- Forward A
        if ((H.ID_EX.A.op = R_TYPE) or (H.ID_EX.A.op = I_IMME) or (H.ID_EX.A.op = LOAD) or (H.ID_EX.A.op = JAL) or (H.ID_EX.A.op = JALR)
           or (H.ID_EX.A.op = U_LUI) or (H.ID_EX.A.op = U_AUIPC) ) and H.ID_EX.B.rs1 = H.ID_EX.A.rd and H.ID_EX.B.rd /= ZERO_5bits then
            temp.B.ForwA := FORW_FROM_A;
        elsif H.EX_MEM.A.readWrite = REG_WRITE and H.EX_MEM.A.rd /= ZERO_5bits and H.EX_MEM.A.rd = H.ID_EX.B.rs1 then
            temp.B.ForwA := EX_MEM_A;
        elsif H.EX_MEM.B.readWrite = REG_WRITE and H.EX_MEM.B.rd /= ZERO_5bits and H.EX_MEM.B.rd = H.ID_EX.B.rs1 then
            temp.B.ForwA := EX_MEM_B;
        elsif H.MEM_WB.A.readWrite = REG_WRITE and H.MEM_WB.A.rd /= ZERO_5bits and H.MEM_WB.A.rd = H.ID_EX.B.rs1 then
            temp.B.ForwA := MEM_WB_A;
        elsif H.MEM_WB.B.readWrite = REG_WRITE and H.MEM_WB.B.rd /= ZERO_5bits and H.MEM_WB.B.rd = H.ID_EX.B.rs1 then
            temp.B.ForwA := MEM_WB_B;
        else
            temp.B.ForwA := NONE;
        end if;
        
        if ((H.ID_EX.A.op = R_TYPE) or (H.ID_EX.A.op = I_IMME) or (H.ID_EX.A.op = LOAD) or (H.ID_EX.A.op = JAL) or (H.ID_EX.A.op = JALR)
           or (H.ID_EX.A.op = U_LUI) or (H.ID_EX.A.op = U_AUIPC) ) and H.ID_EX.B.rs2 = H.ID_EX.A.rd and H.ID_EX.B.rd /= ZERO_5bits then
            temp.B.ForwB := FORW_FROM_A;
        elsif H.EX_MEM.A.readWrite = REG_WRITE and H.EX_MEM.A.rd /= ZERO_5bits and H.EX_MEM.A.rd = H.ID_EX.B.rs2 then
            temp.B.ForwB := EX_MEM_A;
        elsif H.EX_MEM.B.readWrite = REG_WRITE and H.EX_MEM.B.rd /= ZERO_5bits and H.EX_MEM.B.rd = H.ID_EX.B.rs2 then
            temp.B.ForwB := EX_MEM_B;
        elsif H.MEM_WB.A.readWrite = REG_WRITE and H.MEM_WB.A.rd /= ZERO_5bits and H.MEM_WB.A.rd = H.ID_EX.B.rs2 then
            temp.B.ForwB := MEM_WB_A;
        elsif H.MEM_WB.B.readWrite = REG_WRITE and H.MEM_WB.B.rd /= ZERO_5bits and H.MEM_WB.B.rd = H.ID_EX.B.rs2 then
            temp.B.ForwB := MEM_WB_B;
        else
            temp.B.ForwB := NONE;
        end if;
 
        -- STALL B
        if H.ID_EX.A.op = LOAD and  H.ID_EX.A.rd /= ZERO_5bits and (H.ID_EX.A.rd = H.ID.A.rs1 or H.ID_EX.A.rd = H.ID.A.rs2) then
            temp.B.stall := STALL_FROM_A;  
        elsif H.ID_EX.B.op = LOAD and  H.ID_EX.B.rd /= ZERO_5bits and (H.ID_EX.B.rd = H.ID.A.rs1 or H.ID_EX.B.rd = H.ID.A.rs2) then
            temp.B.stall := STALL_FROM_A;
        elsif H.ID_EX.A.op = LOAD and  H.ID_EX.A.rd /= ZERO_5bits and (H.ID_EX.A.rd = H.ID.B.rs1 or H.ID_EX.A.rd = H.ID.B.rs2) then
            temp.B.stall := A_STALL;  
        elsif H.ID_EX.B.op = LOAD and  H.ID_EX.B.rd /= ZERO_5bits and (H.ID_EX.B.rd = H.ID.B.rs1 or H.ID_EX.B.rd = H.ID.B.rs2) then
            temp.B.stall := B_STALL;     
        else
            temp.B.stall := NONE;
        end if;

        result <= temp;
    end process;

end Behavioral;