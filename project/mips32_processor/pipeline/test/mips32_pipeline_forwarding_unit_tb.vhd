library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg;

entity mips32_pipeline_forwarding_unit_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_forwarding_unit_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rsDataFromID : mips32_pkg.data_type := (others => '0');
    signal rsAddressFromID : mips32_pkg.registerFileAddress_type := 0;
    signal regDataBFromID : mips32_pkg.data_type := (others => '0');
    signal regAddressBFromID : mips32_pkg.registerFileAddress_type := 0;

    signal regDataFromEx : mips32_pkg.data_type := (others => '0');
    signal regAddressFromEx : mips32_pkg.registerFileAddress_type := 0;
    signal regWriteFromEx : boolean := false;

    signal regDataFromMem : mips32_pkg.data_type := (others => '0');
    signal regAddressFromMem : mips32_pkg.registerFileAddress_type := 0;
    signal regWriteFromMem : boolean := false;

    signal rsData : mips32_pkg.data_type;
    signal regDataB : mips32_pkg.data_type;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedRsData : mips32_pkg.data_type;
        variable expectedRegDataB : mips32_pkg.data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Regdata is forwarded when no other stage regWrites") then
                expectedRsData := X"0000000A";
                expectedRegDataB := X"0000000B";
                rsDataFromID <= expectedRsData;
                regDataBFromID <= expectedRegDataB;
                wait until rising_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(regDataB, expectedRegDataB);
            elsif run("RegData is forwarded from mem stage") then
                expectedRsData := X"0000000A";
                expectedRegDataB := expectedRsData;
                rsAddressFromID <= 5;
                regAddressBFromID <= 5;
                regDataFromMem <= expectedRsData;
                regAddressFromMem <= 5;
                regWriteFromMem <= true;
                wait until rising_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(regDataB, expectedRegDataB);
            elsif run("RegData is not forwarded if addressFromMem is different") then
                expectedRsData := X"0000000A";
                expectedRegDataB := expectedRsData;
                rsAddressFromID <= 5;
                regAddressBFromID <= 5;
                rsDataFromID <= expectedRsData;
                regDataBFromID <= expectedRegDataB;
                regAddressFromMem <= 6;
                regWriteFromMem <= true;
                wait until rising_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(regDataB, expectedRegDataB);
            elsif run("RegData from ex is prefered over mem") then
                expectedRsData := X"0000000A";
                expectedRegDataB := expectedRsData;
                rsAddressFromID <= 5;
                regAddressBFromID <= 5;
                regAddressFromMem <= 5;
                regWriteFromMem <= true;
                regDataFromEx <= expectedRsData;
                regAddressFromEx <= 5;
                regWriteFromEx <= true;
                wait until rising_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(regDataB, expectedRegDataB);
            elsif run("RegData from ex is not prefered if address differs") then
                expectedRsData := X"0000000A";
                expectedRegDataB := expectedRsData;
                rsAddressFromID <= 5;
                regAddressBFromID <= 5;
                regDataFromMem <= expectedRsData;
                regAddressFromMem <= 5;
                regWriteFromMem <= true;
                regAddressFromEx <= 6;
                regWriteFromEx <= true;
                wait until rising_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(regDataB, expectedRegDataB);
            elsif run("RegData is not forwarded for address 0") then
                expectedRsData := X"0000000A";
                expectedRegDataB := expectedRsData;
                rsDataFromID <= expectedRsData;
                regDataBFromID <= expectedRegDataB;
                rsAddressFromID <= 0;
                regAddressBFromID <= 0;
                regAddressFromMem <= 0;
                regWriteFromMem <= true;
                regAddressFromEx <= 0;
                regWriteFromEx <= true;
                wait until rising_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(regDataB, expectedRegDataB);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    executeStage : entity src.mips32_pipeline_forwarding_unit
    port map (
        rsDataFromID => rsDataFromID,
        rsAddressFromID => rsAddressFromID,
        regDataBFromID => regDataBFromID,
        regAddressBFromID => regAddressBFromID,
        regDataFromEx => regDataFromEx,
        regAddressFromEx => regAddressFromEx,
        regWriteFromEx => regWriteFromEx,
        regDataFromMem => regDataFromMem,
        regAddressFromMem => regAddressFromMem,
        regWriteFromMem => regWriteFromMem,
        rsData => rsData,
        regDataB => regDataB
    );
end architecture;
