------------------------------------------------------------------------------
-- Noridel Herron
-- 6/13/2025
-- Function definition
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

use work.const_Types.all;
use work.Pipeline_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;
package body MyFunctions is

    function get_decoded_val (rand_real, rs1, rs2, rd : real) return Decoder_Type is
    variable temp           : Decoder_Type                             := EMPTY_DECODER;
    variable imm12          : std_logic_vector(IMM12_WIDTH-1 downto 0) := ZERO_12bits;
    variable imm20          : std_logic_vector(IMM20_WIDTH-1 downto 0) := ZERO_20bits;
    begin
        if    rand_real < 0.02 then temp.op := ECALL;     
        elsif rand_real < 0.04 then temp.op := U_AUIPC;
        elsif rand_real < 0.06 then temp.op := U_LUI;
        elsif rand_real < 0.08 then temp.op := JALR;
        elsif rand_real < 0.1  then temp.op := LOAD;
        elsif rand_real < 0.2  then temp.op := S_TYPE;
        elsif rand_real < 0.3  then temp.op := JAL;
        elsif rand_real < 0.6  then temp.op := B_TYPE;
        elsif rand_real < 0.8  then temp.op := I_IMME;
        else temp.op := R_TYPE;
        end if;

        temp.rs1 := std_logic_vector(to_unsigned(integer(rs1 * 32.0), 5));
        temp.rs2 := std_logic_vector(to_unsigned(integer(rs2 * 32.0), 5));
        temp.rd  := std_logic_vector(to_unsigned(integer(rd * 32.0), 5));

        temp.funct3 := std_logic_vector(to_unsigned(integer(rand_real * 8.0), 3));
        temp.funct7 := std_logic_vector(to_unsigned(integer(rand_real * 128.0), 7));
        temp.imm12    := ZERO_12bits;
        temp.imm20    := ZERO_20bits;
        
        -- Adjust fields for types
            case temp.op is
                when R_TYPE =>
                    if temp.funct3 = "000" or temp.funct3 = "101" then
                        if rand_real > 0.5 then
                            temp.funct7 := ZERO_7bits;
                        else
                            temp.funct7 := THIRTY_TWO;
                        end if;
                    end if;
                    
                when I_IMME =>    
                    if temp.funct3 = "101" then
                        if rand_real > 0.5 then
                            temp.funct7 := ZERO_7bits;
                        else
                            temp.funct7 := THIRTY_TWO;
                        end if;
                    end if; 
                    temp.imm12  := temp.funct7 & temp.rs2;
                    
                when LOAD =>    
                    temp.funct3 := "010"; -- lw for 32 bits    
                    temp.imm12  := temp.funct7 & temp.rs2;
                    
                when JALR | ECALL => 
                    temp.imm12  := temp.funct7 & temp.rs2;
                    
                when S_TYPE => 
                    temp.imm12  := temp.funct7 & temp.rd;
                
                when B_TYPE =>
                    imm12        := temp.funct7 & temp.rd; 
                    temp.imm12   := imm12(11) & imm12(0) & imm12(10 downto 5) & imm12(4 downto 1);      
                    if temp.funct3 = "010" or temp.funct3 = "011" then
                        if rand_real > 0.5 then
                            temp.funct3 := ZERO_3bits;
                        else
                            temp.funct3 := "001";
                        end if;
                    end if;  
                
                when U_LUI | U_AUIPC =>  
                    temp.imm20  := temp.funct7 & temp.rs2 & temp.rs1 & temp.funct3;   

                when JAL =>  
                    imm20       := temp.funct7 & temp.rs2 & temp.rs1 & temp.funct3;
                    temp.imm20  := imm20(19) & imm20(7 downto 0) & imm20(8) & imm20(18 downto 9);        
                    
                when others => temp := EMPTY_DECODER;
           end case;  
           
        return temp;    
    end function;
    
    function get_contrl_sig  (op: std_logic_vector) return CONTROL_SIG is
    variable result : CONTROL_SIG := NONE;
    begin
        if (op = S_TYPE) or (op = ECALL) or (op = B_TYPE) then 
            result := NONE;
        else
            result := REG_WRITE;
        end if;
        
        return result;
    end function;
    
    function get_hazard_sig  (H: HDU_in) return HDU_OUT_N is
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
        if H.ID_EX.A.op = LOAD and (H.ID_EX.A.rd = H.ID.A.rs1 or H.ID_EX.A.rd = H.ID.A.rs2) then
            temp.A.stall := A_STALL;
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
        if ((H.ID_EX.A.op = R_TYPE) or (H.ID_EX.A.op = I_IMME) or (H.ID_EX.A.op = LOAD) or (H.ID_EX.A.op = JAL) or (H.ID_EX.A.op = JALR)
           or (H.ID_EX.A.op = U_LUI) or (H.ID_EX.A.op = U_AUIPC) ) and H.ID_EX.B.rs2 = H.ID_EX.A.rd and H.ID_EX.B.rd /= ZERO_5bits then
            temp.A.stall := STALL;
        elsif H.ID_EX.B.op = LOAD and (H.ID_EX.B.rd = H.ID.B.rs1 or H.ID_EX.B.rd = H.ID.B.rs2) then 
            temp.A.stall := A_STALL;
        else
            temp.A.stall := NONE;
        end if;
        
        return temp;
    end function;
    
end MyFunctions;
