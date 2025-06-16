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
        elsif rand_real < 0.4  then temp.op := LOAD;
        elsif rand_real < 0.5  then temp.op := S_TYPE;
        elsif rand_real < 0.55  then temp.op := JAL;
        elsif rand_real < 0.6  then temp.op := B_TYPE;
        elsif rand_real < 0.9  then temp.op := I_IMME;
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
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    function Get_Control(opcode : std_logic_vector(OPCODE_WIDTH-1 downto 0)) return control_Type is
    variable temp : control_Type := EMPTY_control_Type;
    begin
        -- Default settings
        temp.target := NONE;
        temp.alu    := IMM;
        temp.mem    := NONE;
        temp.wb     := REG_WRITE;
    
        case opcode is
            when R_Type =>
                temp.target := ALU_REG;
                temp.alu    := RS2;
    
            when I_IMME =>
                temp.target := ALU_REG;
    
            when LOAD =>
                temp.target := MEM_REG;
                temp.mem    := MEM_READ;
    
            when S_TYPE =>
                temp.target := MEM_REG;
                temp.mem    := MEM_WRITE;
                temp.wb     := NONE;
    
            when B_TYPE =>
                temp.alu    := RS2;
                temp.wb     := NONE;
                temp.target := BRANCH;
    
            when JAL =>
                temp.target := JUMP;
                temp.alu    := NONE;
    
            when others =>
                temp := EMPTY_control_Type;
        end case;
    
        return temp;
    end function;

    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
   function get_hazard_sig  (ID      : DECODER_N_INSTR;   
                             ID_EX   : DECODER_N_INSTR; 
                             ID_EX_c : control_Type_N;    
                             EX_MEM  : RD_CTRL_N_INSTR; 
                             MEM_WB  : RD_CTRL_N_INSTR) return HDU_OUT_N is
    variable temp            : HDU_OUT_N := EMPTY_HDU_OUT_N;
    begin
        temp.B.is_hold := NONE; 
         -- Forwarding logic (always active)
 -------------------------------------------------- INSTRUCTION A --------------------------------------------------
         -- Forward A
        if EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.A.rs1 then
            temp.A.ForwA := EX_MEM_A;
        elsif EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.A.rs1 then
            temp.A.ForwA := EX_MEM_B;
        elsif MEM_WB.A.cntrl.wb = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.A.rs1 then
            temp.A.ForwA := MEM_WB_A;
        elsif MEM_WB.B.cntrl.wb = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.A.rs1 then
            temp.A.ForwA := MEM_WB_B;
        else
            temp.A.ForwA := NONE;
        end if;
        -- Forward B
        if EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.A.rs2 then
            temp.A.ForwB := EX_MEM_A;
        elsif EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.A.rs2 then
            temp.A.ForwB := EX_MEM_B;
        elsif MEM_WB.A.cntrl.wb = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.A.rs2 then
            temp.A.ForwB := MEM_WB_A;
        elsif MEM_WB.B.cntrl.wb = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.A.rs2 then
            temp.A.ForwB := MEM_WB_B;
        else
            temp.A.ForwB := NONE;
        end if;
        
        -- STALL A
        if ID_EX_c.A.mem = MEM_READ and  ID_EX.A.rd /= ZERO_5bits and (ID_EX.A.rd = ID.A.rs1 or ID_EX.A.rd = ID.A.rs2) then
            temp.A.stall := A_STALL;  
        elsif ID_EX.B.op = LOAD and  ID_EX.B.rd /= ZERO_5bits and (ID_EX.B.rd = ID.A.rs1 or ID_EX.B.rd = ID.A.rs2) then
            temp.A.stall := B_STALL;     
        else
            temp.A.stall := NONE;
        end if;

-------------------------------------------------- INSTRUCTION B --------------------------------------------------
        -- Forward A
        if ID_EX_c.A.wb = REG_WRITE and ID_EX.B.rs1 = ID_EX.A.rd and ID_EX.A.rd /= ZERO_5bits then
            temp.B.ForwA := FORW_FROM_A;
        elsif EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.B.rs1 then
            temp.B.ForwA := EX_MEM_A;
        elsif EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.B.rs1 then
            temp.B.ForwA := EX_MEM_B;
        elsif MEM_WB.A.cntrl.wb = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.B.rs1 then
            temp.B.ForwA := MEM_WB_A;
        elsif MEM_WB.B.cntrl.wb = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.B.rs1 then
            temp.B.ForwA := MEM_WB_B;
        else
            temp.B.ForwA := NONE;
        end if;
        
        if ID_EX_c.A.wb = REG_WRITE and ID_EX.B.rs2 = ID_EX.A.rd and ID_EX.A.rd /= ZERO_5bits then
            temp.B.ForwB := FORW_FROM_A;
        elsif EX_MEM.A.cntrl.wb = REG_WRITE and EX_MEM.A.rd /= ZERO_5bits and EX_MEM.A.rd = ID_EX.B.rs2 then
            temp.B.ForwB := EX_MEM_A;
        elsif EX_MEM.B.cntrl.wb = REG_WRITE and EX_MEM.B.rd /= ZERO_5bits and EX_MEM.B.rd = ID_EX.B.rs2 then
            temp.B.ForwB := EX_MEM_B;
        elsif MEM_WB.A.cntrl.wb = REG_WRITE and MEM_WB.A.rd /= ZERO_5bits and MEM_WB.A.rd = ID_EX.B.rs2 then
            temp.B.ForwB := MEM_WB_A;
        elsif MEM_WB.B.cntrl.wb = REG_WRITE and MEM_WB.B.rd /= ZERO_5bits and MEM_WB.B.rd = ID_EX.B.rs2 then
            temp.B.ForwB := MEM_WB_B;
        else
            temp.B.ForwB := NONE;
        end if;
 
        -- STALL B
        if temp.B.ForwA = FORW_FROM_A or temp.B.ForwB = FORW_FROM_A or temp.A.stall /= NONE then
            temp.B.stall := STALL_FROM_A; 
            temp.B.is_hold := HOLD_B; 
        elsif ID_EX_c.A.mem = MEM_READ and  ID_EX.A.rd /= ZERO_5bits and (ID_EX.A.rd = ID.B.rs1 or ID_EX.A.rd = ID.B.rs2) then
            temp.B.stall := A_STALL;  
        elsif ID_EX_c.B.mem = MEM_READ and  ID_EX.B.rd /= ZERO_5bits and (ID_EX.B.rd = ID.B.rs1 or ID_EX.B.rd = ID.B.rs2) then
            temp.B.stall := B_STALL;    
        else
            temp.B.stall := NONE;
        end if;
        
        return temp;
    end function;
    
end MyFunctions;
