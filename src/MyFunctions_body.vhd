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
    
    -- generate 32 bits data
    function get_32bits_val(rand_real : real) return data_32 is
    begin
        return std_logic_vector(to_unsigned(integer(rand_real * 2147483648.0), 32)); 
    end function;
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- generate 12 bits data
    function get_imm12_val(rand_real : real) return data_12 is
    begin
        return std_logic_vector(to_unsigned(integer(rand_real * 4096.0), 12)); 
    end function;
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- generate 20 bits data
    function get_imm20_val(rand_real : real) return data_20 is
    begin
        return std_logic_vector(to_unsigned(integer(rand_real * 1048576.0), 20)); 
    end function;
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- generate 7 bits data for opcode
    function get_op (rand_real : real) return data_op is
    variable temp : std_logic_vector(OPCODE_WIDTH-1 downto 0) := ZERO_7bits;
    begin    
        if    rand_real < 0.3  then temp := LOAD;
        elsif rand_real < 0.45  then temp := S_TYPE;
        elsif rand_real < 0.8  then temp := B_TYPE;
        elsif rand_real < 0.9  then temp := I_IMME;
        else temp := R_TYPE; end if;
        return temp; 
    end function;
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- Generate forwarding status to determine the source of operands
    function get_forwStats (rand : real) return HAZ_SIG is
    variable temp : HAZ_SIG := NONE_h;
    begin
        if    rand < 0.1  then temp := EX_MEM_A;
        elsif rand < 0.2  then temp := EX_MEM_B;
        elsif rand < 0.3  then temp := MEM_WB_A;
        elsif rand < 0.4  then temp := MEM_WB_B;
        elsif rand < 0.5  then temp := FORW_FROM_A;
        else  temp := NONE_h; end if;
        return temp; 
    end function;
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- Generate forwarding status to determine the source of operands
    function get_stall (op : std_logic_vector(OPCODE_WIDTH-1 downto 0); rand : real) return HAZ_SIG is
    variable temp : HAZ_SIG := NONE_h;
    begin
        if (op = LOAD) then
            if rand < 0.05 then
                temp := A_STALL;
            elsif rand < 0.1 then
                 temp := B_STALL;
            elsif rand < 0.15 then
                 temp := STALL_FROM_A;     
            elsif rand < 0.2 then
                 temp := STALL_FROM_B; 
            else
                 temp := NONE_h;    
            end if;
        else 
            temp := NONE_h;    
        end if;
        return temp; 
    end function;
    
    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- Generate decoded value
    function get_decoded_val (rand_real, rs1, rs2, rd : real) return Decoder_Type is
    variable temp           : Decoder_Type                             := EMPTY_DECODER;
    variable imm12          : std_logic_vector(IMM12_WIDTH-1 downto 0) := ZERO_12bits;
    variable imm20          : std_logic_vector(IMM20_WIDTH-1 downto 0) := ZERO_20bits;
    begin
       -- if    rand_real < 0.02 then temp.op := ECALL;     
      --  elsif rand_real < 0.04 then temp.op := U_AUIPC;
      --  elsif rand_real < 0.06 then temp.op := U_LUI;
      --  elsif rand_real < 0.08 then temp.op := JALR;
        if    rand_real < 0.4  then temp.op := LOAD;
        elsif rand_real < 0.5  then temp.op := S_TYPE;
       -- elsif rand_real < 0.55  then temp.op := JAL;
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
                    if temp.funct3 = "000" or temp.funct7 = "101" then
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
    -- Generate control signal
    function Get_Control(opcode : std_logic_vector(OPCODE_WIDTH-1 downto 0)) return control_Type is
    variable temp : control_Type := EMPTY_control_Type;
    begin
        -- Default settings
        temp.target := NONE_c;
        temp.alu    := IMM;
        temp.mem    := NONE_c;
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
                temp.wb     := NONE_c;
    
            when B_TYPE =>
                temp.alu    := RS2;
                temp.wb     := NONE_c;
                temp.target := BRANCH;
    
            when JAL =>
                temp.target := JUMP;
                temp.alu    := NONE_c;
    
            when others =>
                temp := EMPTY_control_Type;
        end case;
    
        return temp;
    end function;

    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- Generate Hazard signal
   function get_hazard_sig  (ID      : DECODER_N_INSTR;   
                             ID_EX   : DECODER_N_INSTR; 
                             ID_EX_c : control_Type_N;    
                             EX_MEM  : EX_CONTENT_N; 
                             MEM_WB  : MEM_CONTENT_N) return HDU_OUT_N is
    variable temp : HDU_OUT_N := EMPTY_HDU_OUT_N;
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
        if ID.A.op = "0000011" and  ID.A.rd /= ZERO_5bits and (ID.A.rd = ID.B.rs1 or ID.A.rd = ID.B.rs2)then
            temp.B.stall := STALL_FROM_A;
        elsif ID_EX_c.A.mem = MEM_READ and  ID_EX.A.rd /= ZERO_5bits and (ID_EX.A.rd = ID.B.rs1 or ID_EX.A.rd = ID.B.rs2) then
            temp.B.stall := A_STALL;  
        elsif ID_EX_c.B.mem = MEM_READ and  ID_EX.B.rd /= ZERO_5bits and (ID_EX.B.rd = ID.B.rs1 or ID_EX.B.rd = ID.B.rs2) then
            temp.B.stall := B_STALL;    
        else
            temp.B.stall := NONE_h;
        end if;
        
        return temp;
    end function;
    

    -----------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------------------------------------------------------
    -- GENERATE Forwarding Unit Result
    function get_operands ( isEnable  : std_logic;
                            EX_MEM    : EX_CONTENT_N; 
                            WB        : WB_CONTENT_N_INSTR;
                            ID_EX     : DECODER_N_INSTR;
                            reg       : REG_DATAS;
                            Forw      : HDU_OUT_N
                         ) return EX_OPERAND_N is
    variable result : EX_OPERAND_N := EMPTY_EX_OPERAND_N; 
    begin
         result.S_data1 := ZERO_32bits;
         result.S_data2 := ZERO_32bits;    
    if isEnable = '1' then     
         case Forw.A.forwA is
            when NONE_h      => result.one.A := reg.one.A; 
            when EX_MEM_A    => result.one.A := EX_MEM.A.alu.result;
            when EX_MEM_B    => result.one.A := EX_MEM.B.alu.result;
            when MEM_WB_A    => result.one.A := WB.A.data; 
            when MEM_WB_B    => result.one.A := WB.B.data; 
            when others      => result.one.A := ZERO_32bits;
        end case;
        
        case Forw.A.forwB is
            when NONE_h      => 
                case ID_EX.A.op is
                    when R_TYPE | B_TYPE => result.one.B := reg.one.B;
                    when I_IMME | LOAD => result.one.B := std_logic_vector(resize(signed(ID_EX.A.imm12), 32));
                    when S_TYPE => result.one.B := std_logic_vector(resize(signed(ID_EX.A.imm12), 32));  
                         result.S_data1 := reg.one.B;
                    when others =>result.one.B := (others => '0');
                end case;        
            when EX_MEM_A    => result.one.B := EX_MEM.A.alu.result;
            when EX_MEM_B    => result.one.B := EX_MEM.B.alu.result;
            when MEM_WB_A    => result.one.B := WB.A.data; 
            when MEM_WB_B    => result.one.B := WB.B.data; 
            when others      => result.one.B := ZERO_32bits;
                
        end case;
        
        if Forw.B.forwA /= FORW_FROM_A then
            case Forw.B.forwA is
                when NONE_h      => result.two.A := reg.two.A; 
                when EX_MEM_A    => result.two.A := EX_MEM.A.alu.result;
                when EX_MEM_B    => result.two.A := EX_MEM.B.alu.result;
                when MEM_WB_A    => result.two.A := WB.A.data; 
                when MEM_WB_B    => result.two.A := WB.B.data; 
                when others      => result.two.A := ZERO_32bits;
            end case;
        end if;  
        
        if Forw.B.forwB /= FORW_FROM_A then  
            case Forw.B.forwB is
                when NONE_h      => 
                    case ID_EX.B.op is
                        when R_TYPE | B_TYPE => result.two.B := reg.two.B;
                        when I_IMME | LOAD => result.two.B := std_logic_vector(resize(signed(ID_EX.B.imm12), 32));
                        when S_TYPE => result.two.B := std_logic_vector(resize(signed(ID_EX.B.imm12), 32));
                             result.S_data2 := reg.two.B;
                        when others => result.two.B := (others => '0');
                    end case; 
                when EX_MEM_A    => result.two.B := EX_MEM.A.alu.result;
                when EX_MEM_B    => result.two.B := EX_MEM.B.alu.result;
                when MEM_WB_A    => result.two.B := WB.A.data; 
                when MEM_WB_B    => result.two.B := WB.B.data; 
                when others      => result.two.B := ZERO_32bits;
                    
            end case;
         end if;  
    else
        result.one.A    := reg.one.A; 
        result.one.B    := reg.one.B; 
        result.two.A    := reg.two.A; 
        result.two.B    := reg.two.B; 
        result.S_data1  := ZERO_32bits;
        result.S_data2  := ZERO_32bits;
        
        if ID_EX.A.op = I_IMME or ID_EX.A.op = LOAD or ID_EX.A.op = S_TYPE then
            if ID_EX.A.op = S_TYPE then
                result.S_data1 := reg.one.B;
            end if;
            result.one.B   :=  std_logic_vector(resize(signed(ID_EX.A.imm12), 32));         
        end if;
        if ID_EX.B.op = I_IMME or ID_EX.B.op = LOAD or ID_EX.B.op = S_TYPE then
            if ID_EX.B.op = S_TYPE then
                result.S_data2 := reg.two.B;
            end if;
            result.two.B   :=  std_logic_vector(resize(signed(ID_EX.B.imm12), 32));   
        end if;
     
    end if;
        return result; 
    end function;
    
    function get_alu_res ( f3     : std_logic_vector(FUNCT3_WIDTH-1 downto 0); 
                           f7     : std_logic_vector(FUNCT7_WIDTH-1 downto 0); 
                           A      : std_logic_vector(DATA_WIDTH-1 downto 0);
                           B      : std_logic_vector(DATA_WIDTH-1 downto 0)
                         ) return  ALU_out is
    variable temp : ALU_out := EMPTY_ALU_out; 
    -- for C Flag
    variable sum_ext, sub_ext : unsigned(32 downto 0);
    begin
       
        case f3 is
            when "000" =>  -- ADD/SUB
                if f7 = ZERO_7bits then
                    sum_ext := resize(unsigned(A), DATA_WIDTH+1) + resize(unsigned(B), DATA_WIDTH+1);
                    temp.result     := std_logic_vector(sum_ext(DATA_WIDTH-1 downto 0));
                    temp.operation  := ALU_ADD;
                    if sum_ext(DATA_WIDTH) = '1' then 
                        temp.C := Cf; 
                    else 
                        temp.C := NONE; 
                    end if;                      
                    
                    if ((A(DATA_WIDTH - 1) = B(DATA_WIDTH - 1)) and 
                       (temp.result(DATA_WIDTH - 1) /= A(DATA_WIDTH - 1))) then
                        temp.V := V; 
                    else 
                        temp.V := NONE; 
                    end if;
                    
                else
                    sub_ext := resize(unsigned(A), DATA_WIDTH+1) - resize(unsigned(B), DATA_WIDTH+1);
                    temp.result     := std_logic_vector(sub_ext(31 downto 0));
                    temp.operation  := ALU_SUB;

                    if sub_ext(DATA_WIDTH) = '0' then 
                        temp.C := Cf;  -- No borrow → C = 1
                    else 
                        temp.C := NONE;  -- Borrow → C = 0
                    end if;
                
                    if ((A(DATA_WIDTH - 1) /= B(DATA_WIDTH - 1)) and 
                       (temp.result(DATA_WIDTH - 1) /= A(DATA_WIDTH - 1))) then
                        temp.V := V; 
                    else 
                        temp.V := NONE; 
                    end if;

                end if;   
                
            when "001" => -- SLL
                temp.result := std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B(SHIFT_WIDTH - 1 downto 0)))));
                temp.operation  := ALU_SLL;
                
            when "010" => -- SLT
                 if signed(A) < signed(B) then
                    temp.result := (DATA_WIDTH - 1 downto 1 => '0') & '1';
                    temp.operation := ALU_SLT;
                else
                    temp := EMPTY_ALU_out;
                end if;
                
            when "011" => -- SLTU
                 if unsigned(A) < unsigned(B) then
                    temp.result := (DATA_WIDTH - 1 downto 1 => '0') & '1';
                    temp.operation := ALU_SLTU;
                else
                    temp := EMPTY_ALU_out;
                end if;
   
            when "100" => -- XOR
                temp.result := A xor B;
                temp.operation  := ALU_XOR;
               
            when "101" => -- SRL/SRA
                if f7 = ZERO_7bits then 
                    temp.result := std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(B(SHIFT_WIDTH - 1 downto 0)))));
                    temp.operation  := ALU_SRL;
                else 
                    temp.result := std_logic_vector(shift_right(signed(A), to_integer(unsigned(B(SHIFT_WIDTH - 1 downto 0)))));
                    temp.operation  := ALU_SRA;                   
                end if;
               
            when "110" =>  -- OR 
                temp.result := A or B;
                temp.operation  := ALU_OR;

            when "111" => -- AND
                temp.result := A and B;
                temp.operation  := ALU_AND;
                
            when others => null;
        end case;
        -- Z flag
        if temp.result = ZERO_32bits then temp.Z := Z; else temp.Z := NONE; end if;
        
        -- N flag
        if temp.result(DATA_WIDTH - 1) = ONE then temp.N := N; else temp.N := NONE; end if;
        return temp; 
    end function; 
    
    function get_alu1_input ( ID_EX       : DECODER_N_INSTR;
                              operands    : EX_OPERAND_N    
                          ) return  ALU_in is    
    variable temp : ALU_in := EMPTY_ALU_in; 
    begin
        -- Forward A operand
        temp.A   := operands.one.A;
        temp.B   := operands.one.B;
        if ID_EX.A.op = LOAD or ID_EX.A.op = S_TYPE then
            -- since f3 of lw and sw is 2, i need to modify it here without changing the actual f3 or f7
            temp.f3  := ZERO_3bits;
            temp.f7  := ZERO_7bits;
            -- We will be using the flags for branching. 
            -- So, the flags will help us determine if rs1 =, /=, >, <, >=, <=
        elsif ID_EX.A.op = B_TYPE then
            temp.f3  := ZERO_3bits;
            temp.f7  := FUNC7_SUB;
        else
            temp.f3  := ID_EX.A.funct3;
            temp.f7  := ID_EX.A.funct7;
        end if;
        return temp; 
    end function; 
   
    function get_alu2_input ( reg   : EX_OPERAND_N;
                              Forw  : HDU_OUT_N;  
                              ID_EX : DECODER_N_INSTR;
                              alu1  : ALU_out
                            ) return  ALU_in is 
    variable temp : ALU_in := EMPTY_ALU_in; 
    begin
        -- Forward A operand
        if Forw.B.forwA = FORW_FROM_A then
            temp.A := alu1.result;
        else
            temp.A := reg.two.A;
        end if;

        -- Forward B operand
        if Forw.B.forwB = FORW_FROM_A then
            temp.B := alu1.result;
        else
            temp.B := reg.two.B;
        end if;

        -- Function codes for second ALU
        if ID_EX.B.op = LOAD or ID_EX.B.op = S_TYPE then
            temp.f3  := ZERO_3bits;
            temp.f7  := ZERO_7bits;  
        elsif ID_EX.B.op = B_TYPE then
            temp.f3  := ZERO_3bits;
            temp.f7  := FUNC7_SUB;
        else
            temp.f3  := ID_EX.B.funct3;
            temp.f7  := ID_EX.B.funct7;
        end if;

    return temp; 
    end function; 
    
    function encode_control_sig(sig : CONTROL_SIG) return std_logic_vector is
    variable temp : std_logic_vector(CNTRL_WIDTH-1 downto 0); 
    begin
        case sig is
        when MEM_READ  => return "0000";
        when MEM_WRITE => return "0001";
        when REG_WRITE => return "0010";
        when MEM_REG   => return "0011";
        when ALU_REG   => return "0100";
        when BRANCH    => return "0101";
        when JUMP      => return "0110";
        when RS2       => return "0111";
        when IMM       => return "1000";
        when VALID     => return "1001";
        when INVALID   => return "1010";
        when NONE_c    => return "1011";
    end case;
    return temp; 
    end function;
    
    function slv_to_control_sig(slv : std_logic_vector(3 downto 0)) return CONTROL_SIG is
    begin
      case slv is
        when "0000" => return MEM_READ;
        when "0001" => return MEM_WRITE;
        when "0010" => return REG_WRITE;
        when "0011" => return MEM_REG;
        when "0100" => return ALU_REG;
        when "0101" => return BRANCH;
        when "0110" => return JUMP;
        when "0111" => return RS2;
        when "1000" => return IMM;
        when "1001" => return VALID;
        when "1010" => return INVALID;
        when others => return NONE_c;
      end case;
    end function;
    
    function encode_HAZ_sig(sig : HAZ_SIG) return std_logic_vector is
    variable temp : std_logic_vector(CNTRL_WIDTH-1 downto 0); 
    begin
        case sig is
        when A_STALL        => return "0000";
        when B_STALL        => return "0001";
        when STALL_FROM_A   => return "0010";
        when STALL_FROM_B   => return "0011";
        when EX_MEM_A       => return "0100";
        when EX_MEM_B       => return "0101";
        when MEM_WB_A       => return "0110";
        when MEM_WB_B       => return "0111";
        when FORW_FROM_A    => return "1000";
        when HOLD_B         => return "1001";
        when B_INVALID      => return "1010";
        when NONE_H         => return "1011";
    end case;
    return temp; 
    end function;
    
    function slv_to_haz_sig(slv : std_logic_vector(3 downto 0)) return HAZ_SIG is
    begin
      case slv is
        when "0000" => return A_STALL;
        when "0001" => return B_STALL;
        when "0010" => return STALL_FROM_A;
        when "0011" => return STALL_FROM_B;
        when "0100" => return EX_MEM_A;
        when "0101" => return EX_MEM_B;
        when "0110" => return MEM_WB_A;
        when "0111" => return MEM_WB_B;
        when "1000" => return FORW_FROM_A;
        when "1001" => return HOLD_B;
        when "1010" => return B_INVALID;
        when others => return NONE_h;
      end case;
    end function;
    
    function get_operand_val(op : std_logic_vector(6 downto 0); regVal : std_logic_vector(31 downto 0); imm : std_logic_vector(11 downto 0)) return OPERAND2_MEMDATA is
    variable result : OPERAND2_MEMDATA := EMPTY_OPERAND2_MEMDATA; 
    begin
        result.S_data  := ZERO_32bits;
        case op is
            when R_TYPE | B_TYPE => 
                result.operand := regVal;
            when I_IMME | LOAD =>
                result.operand := std_logic_vector(resize(signed(imm), 32));
            when S_TYPE => 
                result.operand := std_logic_vector(resize(signed(imm), 32)); 
                result.S_data  := regVal;
            when others      => result.operand := (others => '0'); 
        end case;      
        return result;   
    end function;
end MyFunctions;