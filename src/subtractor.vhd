----------------------------------------------------------------------------------
-- Noridel Herron
-- Subtractor for ALU
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CUSTOMIZED PACKAGE
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all; 

entity subtractor is
    Port ( 
            A, B      : in  std_logic_vector (DATA_WIDTH - 1 downto 0);
            output    : out ALU_add_sub
        );
end subtractor;

architecture equation of subtractor is
    
    signal Bo : std_logic;
    signal Br  : std_logic_vector (DATA_WIDTH - 1 downto 1); 
    signal Do  : std_logic_vector (DATA_WIDTH - 1 downto 0); 

begin

    -- -- First Full Subtractor manually
    FS0: entity work.half_Subtractor port map (
        X       => A(0),
        Y       => B(0),
        Bout    => Br(DATA_WIDTH - 1),
        D       => Do(0)
    );

    -- Generate Full Adders for bits 1 to 30
    FS_Gen: for i in 1 to 30 generate
        FS: entity work.full_subtractor port map (
        X       => A(i),
        Y       => B(i),
        Bin     => Br(DATA_WIDTH - i),
        Bout    => Br(DATA_WIDTH - 1 - i),
        D       => Do(i)
        );
    end generate;

    -- Last Full Subtractor 
    FS31: entity work.full_subtractor port map (
        X       => A(DATA_WIDTH - 1),
        Y       => B(DATA_WIDTH - 1),
        Bin     => Br(1),
        Bout    => Bo,
        D       => Do(DATA_WIDTH - 1)
    );


    process(Do, A, B, Bo)
    variable temp : ALU_add_sub := EMPTY_ALU_add_sub;
    begin
        temp.result := Do;
        temp.CB     := Bo;
        
        output <= temp; 
    end process;

end equation;
