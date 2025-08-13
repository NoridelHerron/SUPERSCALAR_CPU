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
            EX             : in  Inst_PC_N;
            EX_val         : in  EX_CONTENT_N; 
            MEM_WB         : in  Inst_PC_N; 
            EX_MEM         : out Inst_PC_N;
            EX_MEM_content : out EX_CONTENT_N;
            mem_addr       : out std_logic_vector(DATA_WIDTH-1 downto 0);
            isLwOrSw       : out CONTROL_SIG;
            mem_data       : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
end EX_TO_MEM;

architecture Behavioral of EX_TO_MEM is

signal reg            : Inst_PC_N    := EMPTY_Inst_PC_N;
signal reg_content    : EX_CONTENT_N := EMPTY_EX_CONTENT_N;
signal is_memHaz      : HAZ_SIG      := NONE_h;

begin
    
    process(clk, reset)
    variable reg_v         : Inst_PC_N    := EMPTY_Inst_PC_N;
    variable reg_content_v : EX_CONTENT_N := EMPTY_EX_CONTENT_N;
    begin
        if reset = '1' then
            -- reset everything
            reg         <= EMPTY_Inst_PC_N;
            reg_content <= EMPTY_EX_CONTENT_N;

        elsif rising_edge(clk) then
            reg_v         := EX;
            reg_content_v := EX_val;
            
            if EX.isMemBusy = GET_READY then
                mem_addr <= ZERO_32bits;
                mem_data <= ZERO_32bits;
                isLwOrSw <= NONE_c;
                
            elsif (EX.isMemBusy = MEM_A or EX.isMemBusy = STALL_AGAIN) and (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) then
                mem_addr <= EX_val.A.alu.result;
                mem_data <= EX_val.A.S_data;
                isLwOrSw <= EX_val.A.cntrl.mem;
                
            elsif EX.isMemBusy = MEM_B and (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
                mem_addr <= EX_val.B.alu.result;
                mem_data <= EX_val.B.S_data;
                isLwOrSw <= EX_val.B.cntrl.mem;
                if MEM_WB.A.is_valid = ISPREV_VALID and MEM_WB.B.is_valid = ISPREV_VALID then
                    reg_content_v.is_ready := READY;
                end if;
            
            elsif (EX_val.A.cntrl.mem = MEM_READ or EX_val.A.cntrl.mem = MEM_WRITE) then
                mem_addr <= EX_val.A.alu.result;
                mem_data <= EX_val.A.S_data;
                isLwOrSw <= EX_val.A.cntrl.mem;
            
            elsif (EX_val.B.cntrl.mem = MEM_READ or EX_val.B.cntrl.mem = MEM_WRITE) then
                mem_addr <= EX_val.B.alu.result;
                mem_data <= EX_val.B.S_data;
                isLwOrSw <= EX_val.B.cntrl.mem;
            
            else
                mem_addr <= ZERO_32bits;
                mem_data <= ZERO_32bits;
                isLwOrSw <= NONE_c;
            
            end if;
            reg         <= reg_v;
            reg_content <= reg_content_v;
        end if;
    end process;

    -- Output assignments
    EX_MEM         <= reg;
    EX_MEM_content <= reg_content;

end Behavioral;