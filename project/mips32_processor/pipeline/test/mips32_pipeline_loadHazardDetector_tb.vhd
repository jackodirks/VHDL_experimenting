library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_pipeline_loadHazardDetector_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_loadHazardDetector_tb is
    constant clk_period : time := 20 ns;

    signal writeBackControlWordFromEx : mips32_WriteBackControlWord_type;
    signal targetRegFromEx : mips32_registerFileAddress_type;
    signal readPortOneAddressFromID : mips32_registerFileAddress_type;
    signal readPortTwoAddressFromID : mips32_registerFileAddress_type;

    signal loadHazardDetected : boolean;

begin
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Regaddress 5 MemToReg load hazard on port 1") then
                targetRegFromEx <= 5;
                readPortOneAddressFromID <= 5;
                readPortTwoAddressFromID <= 31;
                writeBackControlWordFromEx.MemToReg <= true;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(loadHazardDetected);
            elsif run("Regaddress 5 cop0ToReg load hazard on port 1") then
                targetRegFromEx <= 5;
                readPortOneAddressFromID <= 5;
                readPortTwoAddressFromID <= 31;
                writeBackControlWordFromEx.cop0ToReg <= true;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(loadHazardDetected);
            elsif run("No load hazard because of reg mismatch port 1") then
                targetRegFromEx <= 4;
                readPortOneAddressFromID <= 5;
                readPortTwoAddressFromID <= 31;
                writeBackControlWordFromEx.MemToReg <= true;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(not loadHazardDetected);
            elsif run("No load hazard because of not memToReg port 1") then
                targetRegFromEx <= 5;
                readPortOneAddressFromID <= 5;
                readPortTwoAddressFromID <= 31;
                writeBackControlWordFromEx.MemToReg <= false;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(not loadHazardDetected);
            elsif run("No load hazard because regAddress = 0 port 1") then
                targetRegFromEx <= 0;
                readPortOneAddressFromID <= 0;
                readPortTwoAddressFromID <= 31;
                writeBackControlWordFromEx.MemToReg <= true;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(not loadHazardDetected);
            elsif run("Regaddress 5 load hazard on port 2") then
                targetRegFromEx <= 5;
                readPortOneAddressFromID <= 31;
                readPortTwoAddressFromID <= 5;
                writeBackControlWordFromEx.MemToReg <= true;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(loadHazardDetected);
            elsif run("No load hazard because of not memToReg port 2") then
                targetRegFromEx <= 5;
                readPortOneAddressFromID <= 31;
                readPortTwoAddressFromID <= 5;
                writeBackControlWordFromEx.MemToReg <= false;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(not loadHazardDetected);
            elsif run("No load hazard because regAddress = 0 port 2") then
                targetRegFromEx <= 0;
                readPortOneAddressFromID <= 31;
                readPortTwoAddressFromID <= 0;
                writeBackControlWordFromEx.MemToReg <= true;
                writeBackControlWordFromEx.regWrite <= true;
                wait for clk_period/2;
                check(not loadHazardDetected);
            end if;
        end loop;
        wait for 2*clk_period;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 1 us);

    loadHazardDetector : entity src.mips32_pipeline_loadHazardDetector
    port map (
        writeBackControlWordFromEx => writeBackControlWordFromEx,
        targetRegFromEx => targetRegFromEx,
        readPortOneAddressFromID => readPortOneAddressFromID,
        readPortTwoAddressFromID => readPortTwoAddressFromID,
        loadHazardDetected => loadHazardDetected
    );
end architecture;
