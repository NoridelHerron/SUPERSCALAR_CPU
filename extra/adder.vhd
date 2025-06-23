----------------------------------------------------------------------------------
-- Noridel Herron
-- Adder for ALU (32-bit Version)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.ENUM_T.all; 
use work.initialize_records.all;

entity adder is
    Port (
            A, B      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
            output    : out ALU_add_sub
        ); 
end adder;

architecture equation of adder is

    signal C  : std_logic_vector (DATA_WIDTH downto 1);
    signal S  : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal Co : std_logic;

begin

    FA0: entity work.half_adder port map (
        A => A(0),
        B => B(0),
        Co => C(1),
        S => S(0)
    );

    -- Generate Full Adders for bits 1 to 30
    FA_Gen: for i in 1 to 30 generate
        FA: entity work.full_adder port map (
            A   => A(i),
            B   => B(i),
            Ci  => C(i),
            Co  => C(i+1),
            S   => S(i)
        );
    end generate;

    -- Last Full Adder (bit 31) outputs to Carry out = (C(32))
    FA31: entity work.full_adder port map (
        A   => A(DATA_WIDTH - 1),
        B   => B(DATA_WIDTH - 1),
        Ci  => C(DATA_WIDTH - 1),
        Co  => Co,
        S   => S(DATA_WIDTH - 1)
    );

    process(S, Co)
    variable temp : ALU_add_sub := EMPTY_ALU_add_sub;
    begin
        temp.result := S;
        temp.CB     := Co;
        output      <= temp;
    end process;

end equation;
