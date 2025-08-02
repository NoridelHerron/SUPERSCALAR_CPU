------------------------------------------------------------------------------
-- Noridel Herron
-- 7/2/2025
-- EX_TO_MEM Register (with Stall Tracking)
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOM PACKAGES
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all;

entity EX_TO_MEM is
    Port ( 
            clk            : in  std_logic; 
            reset          : in  std_logic;  
            haz            : in  HDU_OUT_N;
            EX             : in  Inst_PC_N;
            EX_val         : in  EX_CONTENT_N; 
            num_stall      : out std_logic_vector(1 downto 0);
            is_busy        : out HAZ_SIG;
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

    signal reg         : Inst_PC_N    := EMPTY_Inst_PC_N;
    signal reg_content : EX_CONTENT_N := EMPTY_EX_CONTENT_N;
    signal is_memHaz   : HAZ_SIG      := NONE_h;
    signal is_check    : std_logic    := '0';
    signal counter     : std_logic_vector(1 downto 0) := (others => '0');

begin

    process(clk, reset)
    begin
        if reset = '1' then
            -- reset everything
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;
            is_memHaz   <= NONE_h;
            is_check    <= '0';
            counter     <= "00";

        elsif rising_edge(clk) then

            -- Stall tracking logic
            case counter is
                when "11" => 
                    counter         <= "10";  -- 3 → 2 stalls left
                    reg.B           <= EX.B;
                    reg.A.is_valid  <= INVALID;
                    reg_content.B   <= EX_val.B;
                    is_memHaz       <= B_BUSY;

                when "10" => 
                    counter <= "00"; 
                    
                    if is_check = '1' then
                        is_check        <= '0';
                        reg.A.is_valid  <= INVALID;
                        reg.B.is_valid  <= INVALID;
                        is_memHaz       <= B_STILL_BUSY;
                        
                    else
                        reg.B           <= EX.B;
                        reg.A.is_valid  <= INVALID;
                        reg_content.B   <= EX_val.B;
                        is_memHaz       <= B_BUSY;
                    end if;

                when "01" => 
                    counter  <= "00"; -- 1 → 0 stall left
                    is_check <= '0';
                    reg.A.is_valid  <= INVALID;
                    reg.B.is_valid  <= INVALID;
                    is_memHaz       <= B_STILL_BUSY;

                when others =>  -- "00"
                    -- Stall condition detection
                    if haz.A.stall = B_STILL_BUSY and haz.B.stall = AB_BUSY then
                        counter         <= "11";
                        is_check        <= '1';
                        reg.A           <= EX.A;
                        reg.B.is_valid  <= INVALID;
                        reg_content.A   <= EX_val.A;
                        is_memHaz       <= A_BUSY;
                        
                    elsif haz.B.stall = AB_BUSY then
                        counter         <= "10";
                        is_check        <= '0';
                        reg.A           <= EX.A;
                        reg.B.is_valid  <= INVALID;
                        reg_content.A   <= EX_val.A;
                        is_memHaz       <= A_BUSY;
                
                    elsif haz.A.stall = B_STILL_BUSY then
                        counter         <= "01";
                        is_check        <= '1';
                        reg             <= EX;
                        reg_content     <= EX_val;
                        is_memHaz       <= SEND_BOTH;
                        
                    else
                        counter         <= "00";
                        is_check        <= '0';
                        reg             <= EX;
                        reg_content     <= EX_val;
                        is_memHaz       <= SEND_BOTH;
                        is_check        <= '0';
                        
                    end if;
            end case;

        end if;
    end process;

    -- Output assignments
    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;
    is_busy        <= is_memHaz;
    num_stall      <= counter;

end Behavioral;
