------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- ID_EX Register
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.MATH_REAL.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;
--use work.MyFunctions.all;

entity ID_EX is
    Port ( 
            clk             : in  std_logic; 
            reset           : in  std_logic; 
            id_stage        : in  Inst_PC_N;
            id              : in  DECODER_N_INSTR;   
            id_c            : in  control_Type_N;
            datas_in        : in  REG_DATAS;
            haz             : in  HDU_OUT_N;
            readyOrNot      : in HAZ_SIG; 
            is_busy         : out  HAZ_SIG;
            id_ex_stage     : out Inst_PC_N;  
            id_ex           : out DECODER_N_INSTR;
            id_ex_c         : out control_Type_N;
            datas_out       : out REG_DATAS 
         );
end ID_EX;

architecture Behavioral of ID_EX is

signal id_ex_stage_reg  : Inst_PC_N        := EMPTY_Inst_PC_N;
signal id_reg           : DECODER_N_INSTR  := EMPTY_DECODER_N_INSTR;
signal id_reg_c         : control_Type_N   := EMPTY_control_Type_N;
signal datas_reg        : REG_DATAS        := EMPTY_REG_DATAS;
signal is_memHAZ        : HAZ_SIG          := NONE_h;

begin
    
    process(clk, reset)
    begin
        if reset = '1' then
            id_ex_stage_reg <= EMPTY_Inst_PC_N;
            id_reg          <= EMPTY_DECODER_N_INSTR;
            id_reg_c        <= EMPTY_control_Type_N;
            datas_reg       <= EMPTY_REG_DATAS;
            
        elsif rising_edge(clk) then 
            if is_memHAZ = B_STILL_BUSY then
                is_memHAZ  <= SEND_BOTH;
                
            elsif readyOrNot = READY and haz.B.stall = REL_A_STALL_B then  
                if id_stage.A.is_valid = VALID then
                    id_ex_stage_reg.A <= id_stage.A;
                    id_reg.A          <= id.A;
                    id_reg_c.A        <= id_c.A;
                    datas_reg.one     <= datas_in.one;    
                end if;
                is_memHAZ <= B_BUSY;
    
            else
                if (haz.B.stall = NONE_h or is_memHAZ = SEND_BOTH) then
                    if id_stage.A.is_valid = VALID then
                        id_ex_stage_reg.A <= id_stage.A;
                        id_reg.A          <= id.A;
                        id_reg_c.A        <= id_c.A;
                        datas_reg.one     <= datas_in.one; 
                        
                        if id_stage.B.is_valid = VALID then  
                            id_ex_stage_reg.B <= id_stage.B;
                            id_reg.B          <= id.B;
                            id_reg_c.B        <= id_c.B;
                            datas_reg.two     <= datas_in.two;  
                        end if;  
                    end if;
                    
                elsif is_memHAZ = B_BUSY then
                    id_ex_stage_reg.B <= id_stage.B;
                    id_reg.B          <= id.B;
                    id_reg_c.B        <= id_c.B;
                    datas_reg.two     <= datas_in.two; 
                    
                    if (id_c.A.mem = MEM_READ or id_c.A.mem = MEM_WRITE) and 
                       (id_reg_c.B.mem = MEM_READ or id_reg_c.B.mem = MEM_WRITE) then  
                       is_memHAZ <= B_STILL_BUSY;
                    else
                        is_memHAZ  <= SEND_BOTH;
                    end if;
 
                 end if;
            end if;
        end if;
    end process;

    -- Assign outputs
    id_ex_stage.A.instr    <= id_ex_stage_reg.A.instr;
    id_ex_stage.A.pc       <= id_ex_stage_reg.A.pc;
    id_ex_stage.A.is_valid <= INVALID when is_memHAZ = B_BUSY or is_memHAZ = B_STILL_BUSY else VALID;
    
    id_ex_stage.B.instr    <= id_ex_stage_reg.B.instr;
    id_ex_stage.B.pc       <= id_ex_stage_reg.B.pc;
    id_ex_stage.B.is_valid <= VALID when haz.B.stall = NONE_h or is_memHAZ = SEND_BOTH or is_memHAZ = B_BUSY else INVALID;
    id_ex       <= id_reg;
    id_ex_c     <= id_reg_c;
    datas_out   <= datas_reg;
    is_busy     <= is_memHAZ;

end Behavioral;