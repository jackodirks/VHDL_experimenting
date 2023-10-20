library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_pipeline_writeBack_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_writeBack_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';

    signal writeBackControlWord : mips32_WriteBackControlWord_type;

    signal execResult : mips32_data_type := (others => '0');
    signal memDataRead : mips32_data_type := (others => '0');
    signal destinationReg : mips32_registerFileAddress_type := 0;
    signal has_branched : boolean := false;

    signal regWrite : boolean;
    signal regWriteAddress : mips32_registerFileAddress_type;
    signal regWriteData : mips32_data_type;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedRegWriteAddress : mips32_registerFileAddress_type;
        variable expectedRegWriteData : mips32_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("regWrite from ALU works") then
                writeBackControlWord.regWrite <= true;
                writeBackControlWord.MemtoReg <= false;
                expectedRegWriteAddress := 5;
                expectedRegWriteData := X"ABCDABCD";
                execResult <= expectedRegWriteData;
                memDataRead <= (others => '1');
                destinationReg <= expectedRegWriteAddress;
                wait until rising_edge(clk);
                check(regWrite);
                check_equal(regWriteAddress, expectedRegWriteAddress);
                check_equal(regWriteData, expectedRegWriteData);
            elsif run("regWrite from mem works") then
                writeBackControlWord.regWrite <= true;
                writeBackControlWord.MemtoReg <= true;
                expectedRegWriteAddress := 5;
                expectedRegWriteData := X"ABCDABCD";
                memDataRead <= expectedRegWriteData;
                execResult <= (others => '1');
                destinationReg <= expectedRegWriteAddress;
                wait until rising_edge(clk);
                check(regWrite);
                check_equal(regWriteAddress, expectedRegWriteAddress);
                check_equal(regWriteData, expectedRegWriteData);
            elsif run("Not writing is possible") then
                writeBackControlWord.regWrite <= false;
                writeBackControlWord.MemtoReg <= true;
                wait until rising_edge(clk);
                check(not regWrite);
            elsif run("Conditional write writes on branch") then
                writeBackControlWord.write_on_branch <= true;
                has_branched <= true;
                wait until rising_edge(clk);
                check(regWrite);
            elsif run("Conditional write does not write when no branch") then
                writeBackControlWord.write_on_branch <= true;
                has_branched <= false;
                wait until rising_edge(clk);
                check(not regWrite);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);
    writeBack_stage : entity src.mips32_pipeline_writeBack
    port map (
        writeBackControlWord => writeBackControlWord,
        execResult => execResult,
        memDataRead => memDataRead,
        destinationReg => destinationReg,
        has_branched => has_branched,
        regWrite => regWrite,
        regWriteAddress => regWriteAddress,
        regWriteData => regWriteData
    );
end architecture;
