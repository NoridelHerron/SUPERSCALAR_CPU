----------------------------------------------------------------------------------
-- Noridel Herron
-- Create Date: 06/18/2025 10:49:46 AM
-- Module Name: ALU_wrapper - RTL
-- Project Name: Superscalar CPU
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

entity ALU_wrapper is
    Port (  -- inputs
            A           : in  std_logic_vector(DATA_WIDTH-1 downto 0);   
            B           : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            f3          : in  std_logic_vector(FUNCT3_WIDTH-1 downto 0);   
            f7          : in  std_logic_vector(FUNCT7_WIDTH-1 downto 0);
            -- outputs
            operation   : out std_logic_vector(FOUR-1 downto 0);
            result      : out std_logic_vector(DATA_WIDTH-1 downto 0);   
            Z_flag      : out std_logic;
            V_flag      : out std_logic;
            C_flag      : out std_logic;
            N_flag      : out std_logic
    );
end ALU_wrapper;

architecture RTL of ALU_wrapper is

    signal alu_in  : ALU_in;
    signal alu_out : ALU_out;
    
begin

-- Map inputs to record
  alu_in.A  <= A;
  alu_in.B  <= B;
  alu_in.f3 <= f3;
  alu_in.f7 <= f7;

-- Map ALU_OP enum to std_logic_vector for output port
operation <= std_logic_vector(to_unsigned(ALU_OP'pos(alu_out.operation), FOUR));

-- Map other outputs
  result <= alu_out.result;
  
  process (alu_out)
  begin
    if alu_out.Z = Z then
        Z_flag <= '1';
    else
        Z_flag <= '0';
    end if;
    
    if alu_out.V = V then
        V_flag <= '1';
    else
        V_flag <= '0';
    end if;
    
    if alu_out.N = N then
        N_flag <= '1';
    else
        N_flag <= '0';
    end if;
    
    if alu_out.C = Cf then
        C_flag <= '1';
    else
        C_flag <= '0';
    end if;
  end process;
  
  -- Instantiate original ALU
  u_alu: entity work.alu port map (
              alu_input  => alu_in,
              alu_output => alu_out
            );

end RTL;
