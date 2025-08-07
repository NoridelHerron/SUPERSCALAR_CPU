------------------------------------------------------------------------------
-- Noridel Herron
-- 7/7/2025
-- testbench for Ex/MEM register
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

-- CUSTOMIZED PACKAGE
library work;
use work.Pipeline_Types.all;
use work.const_Types.all;
use work.initialize_records.all;
use work.ENUM_T.all; 
use work.instruction_generator.all;
use work.MyFunctions.all;
use work.decoder_function.all;

entity tb_main is
--  Port ( );
end tb_main;

architecture sim of tb_main is

constant clk_period  : time              := 10 ns;
signal clk           : std_logic         := '0';
signal rst           : std_logic         := '1';
-- IF
signal if_ipcv       : Inst_PC_N          := EMPTY_Inst_PC_N;
--signal id_ipcv     : Inst_PC_N          := EMPTY_Inst_PC_N;
--signal ex_ipcv     : Inst_PC_N          := EMPTY_Inst_PC_N;
--signal mem_ipcv    : Inst_PC_N          := EMPTY_Inst_PC_N;
--signal wb_ipcv     : Inst_PC_N          := EMPTY_Inst_PC_N;

-- IF_ID/ID
signal id_ipcv       : Inst_PC_N          := EMPTY_Inst_PC_N;
signal id_value      : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal id_cntrl      : control_Type_N     := EMPTY_control_Type_N;
signal id_haz        : HDU_OUT_N          := EMPTY_HDU_OUT_N; 
signal id_datas      : REG_DATAS          := EMPTY_REG_DATAS;

-- ID_EX/EX
signal ex_ipcv       : Inst_PC_N          := EMPTY_Inst_PC_N;
signal idex_value    : DECODER_N_INSTR    := EMPTY_DECODER_N_INSTR;
signal idex_cntrl    : control_Type_N     := EMPTY_control_Type_N;
signal idex_datas    : REG_DATAS          := EMPTY_REG_DATAS;
signal ex_value      : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;

-- EX_MEM/MEM
--signal mem_is_busy   : HAZ_SIG            := NONE_h;
signal mem_ipcv      : Inst_PC_N          := EMPTY_Inst_PC_N;
signal exmem_value   : EX_CONTENT_N       := EMPTY_EX_CONTENT_N;

signal mem_value     : std_logic_vector(DATA_WIDTH-1 downto 0) := ZERO_32bits;

-- MEM_WB/WB
signal wb_ipcv       : Inst_PC_N          := EMPTY_Inst_PC_N;
signal memwb_value   : MEM_CONTENT_N      := EMPTY_MEM_CONTENT_N;
signal wb_value      : WB_CONTENT_N_INSTR := EMPTY_WB_CONTENT_N_INSTR;

begin
     UUT : entity work.main port map (
        clk         => clk,
        reset       => rst,
        if_ipcv     => if_ipcv,
        id_ipcv     => id_ipcv,
        id_value    => id_value,
        id_cntrl    => id_cntrl,
        id_haz      => id_haz,  
        id_datas    => id_datas,
        ex_ipcv     => ex_ipcv,
    --    mem_is_busy => mem_is_busy,
        idex_value  => idex_value,
        idex_cntrl  => idex_cntrl,
        idex_datas  => idex_datas,
        ex_value    => ex_value,
        mem_ipcv    => mem_ipcv,
        exmem_value => exmem_value,
        mem_value   => mem_value,
        wb_ipcv     => wb_ipcv,
        memwb_value => memwb_value,
        wb_value    => wb_value 
    );

    -- Clock generation only
    clk_process : process
    begin
        while now < 10000 ns loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    reset_process : process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait;
    end process;
    
    end_simulation : process
    begin
        wait for 10000 ns;
        report "Simulation finished" severity note;
        std.env.stop;
    end process;

end sim;
