----------------------------------------------------------------------------------
-- Noridel Herron
-- ALU 32-bit with Flags (for EX_STAGE)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 
use work.initialize_records.all;

entity ALU is
    Port ( 
            alu_input    : in ALU_in;
            alu_output   : out ALU_out
        );
end ALU;

architecture Behavioral of ALU is

begin
    
    process (alu_input)
    variable res_temp : ALU_out := EMPTY_ALU_out;
    variable temp     : unsigned(DATA_WIDTH downto 0);
    begin
        -- C and V flags
        res_temp.C := NONE;
        res_temp.V := NONE;
        case alu_input.f3 is
            when FUNC3_ADD_SUB =>  -- ADD/SUB
                case alu_input.f7 is
                    when FUNC7_ADD =>    -- ADD
                        temp := resize(unsigned(alu_input.A), DATA_WIDTH+1) + 
                                resize(unsigned(alu_input.B), DATA_WIDTH+1);
                        res_temp.result     := std_logic_vector(temp(DATA_WIDTH-1 downto 0));
                        res_temp.operation  := ALU_ADD;
                        if temp(DATA_WIDTH) = '1' then 
                            res_temp.C := Cf; 
                        else 
                            res_temp.C := NONE; 
                        end if;                      
                        
                        if ((alu_input.A(DATA_WIDTH - 1) = alu_input.B(DATA_WIDTH - 1)) and 
                           (res_temp.result(DATA_WIDTH - 1) /= alu_input.A(DATA_WIDTH - 1))) then
                            res_temp.V := V; 
                        else 
                            res_temp.V := NONE; 
                        end if;
  
                    when FUNC7_SUB =>   -- SUB (RISC-V uses 0b0100000 = 32 decimal)
                        temp := resize(unsigned(alu_input.A), DATA_WIDTH+1) - 
                                resize(unsigned(alu_input.B), DATA_WIDTH+1);
                        res_temp.result     := std_logic_vector(temp(DATA_WIDTH-1 downto 0));
                        res_temp.operation  := ALU_SUB;
 
                        if temp(DATA_WIDTH) = '0' then 
                            res_temp.C := Cf;  -- No borrow → C = 1
                        else 
                            res_temp.C := NONE;  -- Borrow → C = 0
                        end if;
                    
                        if ((alu_input.A(DATA_WIDTH - 1) /= alu_input.B(DATA_WIDTH - 1)) and 
                           (res_temp.result(DATA_WIDTH - 1) /= alu_input.A(DATA_WIDTH - 1))) then
                            res_temp.V := V; 
                        else 
                            res_temp.V := NONE; 
                        end if;
  
                    when others =>
                        res_temp := EMPTY_ALU_out;  
                end case;

            when FUNC3_SLL =>  -- SLL
                res_temp.result := std_logic_vector(shift_left(unsigned(alu_input.A), to_integer(unsigned(alu_input.B(SHIFT_WIDTH - 1 downto 0)))));
                res_temp.operation := ALU_SLL;

            when FUNC3_SLT =>  -- SLT
                if signed(alu_input.A) < signed(alu_input.B) then
                    res_temp.result := (DATA_WIDTH - 1 downto 1 => '0') & '1';
                else
                    res_temp.result := ZERO_32bits;
                end if;
                res_temp.operation := ALU_SLT;

            when FUNC3_SLTU =>  -- SLTU
                if unsigned(alu_input.A) < unsigned(alu_input.B) then
                    res_temp.result := (DATA_WIDTH - 1 downto 1 => '0') & '1';     
                else
                    res_temp.result := ZERO_32bits;
                end if;
                res_temp.operation := ALU_SLTU;

            when FUNC3_XOR =>  -- XOR
                res_temp.result := alu_input.A xor alu_input.B;
                res_temp.operation := ALU_XOR;

            when FUNC3_SRL_SRA =>  -- SRL/SRA
                case alu_input.f7 is
                    when FUNC7_SRL =>    -- SRL
                        res_temp.result := std_logic_vector(shift_right(unsigned(alu_input.A), to_integer(unsigned(alu_input.B(SHIFT_WIDTH - 1 downto 0)))));
                        res_temp.operation := ALU_SRL;
                    when FUNC7_SRA =>   -- SRA
                        res_temp.result := std_logic_vector(shift_right(signed(alu_input.A), to_integer(unsigned(alu_input.B(SHIFT_WIDTH - 1 downto 0)))));
                        res_temp.operation := ALU_SRA;
                    when others =>
                        res_temp := EMPTY_ALU_out;
                end case;

            when FUNC3_OR =>  -- OR
                res_temp.result := alu_input.A or alu_input.B;
                res_temp.operation := ALU_OR;

            when FUNC3_AND =>  -- AND
                res_temp.result := alu_input.A and alu_input.B;
                res_temp.operation := ALU_AND;

            when others =>
                res_temp := EMPTY_ALU_out;
        end case;
        
        -- Z flag
        if res_temp.result = ZERO_32bits then res_temp.Z := Z; else res_temp.Z := NONE; end if;
        
        -- N flag
        if res_temp.result(DATA_WIDTH - 1) = ONE then res_temp.N := N; else res_temp.N := NONE; end if;
        
        alu_output <= res_temp;

    end process;

end Behavioral;
