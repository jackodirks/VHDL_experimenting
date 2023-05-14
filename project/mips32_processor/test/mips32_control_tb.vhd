
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg;

entity mips32_control_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_control_tb is
    constant clk_period : time := 20 ns;
    constant illegalOpcode : mips32_pkg.opcode_type := 16#1#;

    signal clk : std_logic := '0';

    signal opcode : mips32_pkg.opcode_type := illegalOpcode;

    signal instructionDecodeControlWord : mips32_pkg.InstructionDecodeControlWord_type;
    signal executeControlWord : mips32_pkg.ExecuteControlWord_type;
    signal memoryControlWord : mips32_pkg.MemoryControlWord_type;
    signal writeBackControlWord : mips32_pkg.WriteBackControlWord_type;
    signal invalidOpcode : boolean;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedData : mips32_pkg.data_type := (others => '0');
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
        instructionDecodeControlWord => instructionDecodeControlWord,
        executeControlWord => executeControlWord,
        memoryControlWord => memoryControlWord,
        writeBackControlWord => writeBackControlWord,
        invalidOpcode => invalidOpcode
    );
end architecture;
