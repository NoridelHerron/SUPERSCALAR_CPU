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
use work.ALU_Pkg.all; 
use work.initialize_records.all;

entity ALU is
    Port ( 
            input    : in ALU_in;
            output   : out ALU_out
        );
end ALU;

architecture Behavioral of ALU is

    signal add_temp : ALU_out := EMPTY_ALU_out;
    signal sub_temp : ALU_out := EMPTY_ALU_out;
    
begin

    Add: entity work.adder port map (
            A           => input.A, 
            B           => input.B,         
            output      => add_temp
        );
    Sub: entity work.subtractor port map (
            A           => input.A, 
            B           => input.B,         
            output      => sub_temp
    );

    process (input, add_temp, sub_temp)
    variable res_temp : ALU_out := EMPTY_ALU_out;
    begin
        case input.f3 is
            when FUNC3_ADD_SUB =>  -- ADD/SUB
                case input.f7 is
                    when FUNC7_ADD =>    -- ADD
                        res_temp := add_temp;
                        res_temp.operation := ALU_ADD;
                    when FUNC7_SUB =>   -- SUB (RISC-V uses 0b0100000 = 32 decimal)
                        res_temp := sub_temp;
                        res_temp.operation := ALU_SUB;
                    when others =>
                        res_temp := EMPTY_ALU_out;  
                end case;

            when FUNC3_SLL =>  -- SLL
                res_temp.result := std_logic_vector(shift_left(unsigned(input.A), to_integer(unsigned(input.B(SHIFT_WIDTH - 1 downto 0)))));
                res_temp.operation := ALU_SLL;

            when FUNC3_SLT =>  -- SLT
                if signed(input.A) < signed(input.B) then
                    res_temp.result := (DATA_WIDTH - 1 downto 1 => '0') & '1';
                    res_temp.operation := ALU_SLT;
               -- else
             --       res_temp := EMPTY_ALU_out;
                end if;

            when FUNC3_SLTU =>  -- SLTU
                if unsigned(input.A) < unsigned(input.B) then
                    res_temp.result := (DATA_WIDTH - 1 downto 1 => '0') & '1';
                    res_temp.operation := ALU_SLTU;
              --  else
                  --  res_temp := EMPTY_ALU_out;
                end if;

            when FUNC3_XOR =>  -- XOR
                res_temp.result := input.A xor input.B;
                res_temp.operation := ALU_XOR;

            when FUNC3_SRL_SRA =>  -- SRL/SRA
                case input.f7 is
                    when FUNC7_SRL =>    -- SRL
                        res_temp.result := std_logic_vector(shift_right(unsigned(input.A), to_integer(unsigned(input.B(SHIFT_WIDTH - 1 downto 0)))));
                        res_temp.operation := ALU_SRL;
                    when FUNC7_SRA =>   -- SRA
                        res_temp.result := std_logic_vector(shift_right(signed(input.A), to_integer(unsigned(input.B(SHIFT_WIDTH - 1 downto 0)))));
                        res_temp.operation := ALU_SRA;
                    when others =>
                        res_temp := EMPTY_ALU_out;
                end case;

            when FUNC3_OR =>  -- OR
                res_temp.result := input.A or input.B;
                res_temp.operation := ALU_OR;

            when FUNC3_AND =>  -- AND
                res_temp.result := input.A and input.B;
                res_temp.operation := ALU_AND;

            when others =>
                res_temp := EMPTY_ALU_out;
        end case;
        
        if input.f3 /= ZERO_3bits then         
            if res_temp.result = ZERO_32bits then
                res_temp.Z := Z;
            else
                res_temp.Z := NONE;
            end if;
            
            if res_temp.result(DATA_WIDTH - 1) = ONE then
                res_temp.N := N;
            else
                res_temp.N := NONE;
            end if;
            
            res_temp.C := NONE;
            res_temp.V := NONE;
        end if;
        
        output <= res_temp;

    end process;

end Behavioral;
