
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_control_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_control_tb is
    constant clk_period : time := 20 ns;
    constant illegalOpcode : mips32_opcode_type := 16#a#;

    signal clk : std_logic := '0';

    signal opcode : mips32_opcode_type := illegalOpcode;
    signal func : mips32_function_type := mips32_function_Sll;
    signal mf : mips32_mf_type := 0;
    signal regimm : mips32_regimm_type := 0;

    signal instructionDecodeControlWord : mips32_InstructionDecodeControlWord_type;
    signal executeControlWord : mips32_ExecuteControlWord_type;
    signal memoryControlWord : mips32_MemoryControlWord_type;
    signal writeBackControlWord : mips32_WriteBackControlWord_type;
    signal invalidOpcode : boolean;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedData : mips32_data_type := (others => '0');
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Control detects invalid instruction") then
                opcode <= illegalOpcode;
                wait for clk_period/2;
                check(invalidOpcode);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    control : entity src.mips32_control
    port map (
        opcode => opcode,
        mf => mf,
        func => func,
        regimm => regimm,
        instructionDecodeControlWord => instructionDecodeControlWord,
        executeControlWord => executeControlWord,
        memoryControlWord => memoryControlWord,
        writeBackControlWord => writeBackControlWord,
        invalidOpcode => invalidOpcode
    );
end architecture;
