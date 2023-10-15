library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_pipeline_idexRegister_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_idexRegister_tb is
    constant clk_period : time := 20 ns;
    signal clk : std_logic := '0';
    -- Control in
    signal stall : boolean := false;
    signal nop : boolean := false;
    -- Pipeline control in
    signal executeControlWordIn : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;
    signal memoryControlWordIn : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
    signal writeBackControlWordIn : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    -- Pipeline data
    signal programCounterPlusFourIn : mips32_address_type := (others => '0');
    signal rsDataIn : mips32_data_type := (others => '0');
    signal rsAddressIn : mips32_registerFileAddress_type := 0;
    signal rtDataIn : mips32_data_type := (others => '0');
    signal rtAddressIn : mips32_registerFileAddress_type := 0;
    signal immidiateIn : mips32_data_type := (others => '0');
    signal destinationRegIn : mips32_registerFileAddress_type := 0;
    signal rdAddressIn : mips32_registerFileAddress_type := 0;
    signal shamtIn : mips32_shamt_type := 0;
    -- Pipeline control out
    signal executeControlWordOut : mips32_ExecuteControlWord_type;
    signal memoryControlWordOut : mips32_MemoryControlWord_type;
    signal writeBackControlWordOut : mips32_WriteBackControlWord_type;
    -- Pipeline data
    signal programCounterPlusFourOut : mips32_address_type;
    signal rsDataOut : mips32_data_type;
    signal rsAddressOut : mips32_registerFileAddress_type;
    signal rtDataOut : mips32_data_type;
    signal rtAddressOut : mips32_registerFileAddress_type;
    signal immidiateOut : mips32_data_type;
    signal destinationRegOut : mips32_registerFileAddress_type;
    signal rdAddressOut : mips32_registerFileAddress_type;
    signal shamtOut : mips32_shamt_type;
begin
    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Push nop on first rising edge") then
                wait until rising_edge(clk);
                check(executeControlWordOut = mips32_executeControlWordAllFalse);
                check(memoryControlWordOut = mips32_memoryControlWordAllFalse);
                check(writeBackControlWordOut = mips32_writeBackControlWordAllFalse);
            elsif run("Forwards input on rising edge if stall = nop = false") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                memoryControlWordIn.memOp <= true;
                wait until falling_edge(clk);
                check(memoryControlWordOut.memOp);
            elsif run("Holds input if stall = true") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                memoryControlWordIn.memOp <= true;
                wait until falling_edge(clk);
                stall <= true;
                memoryControlWordIn.memOp <= false;
                wait until falling_edge(clk);
                check(memoryControlWordOut.memOp);
            elsif run("Clears control words if nop = true") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                memoryControlWordIn.memOp <= true;
                wait until falling_edge(clk);
                nop <= true;
                wait until falling_edge(clk);
                check(not memoryControlWordOut.memOp);
            elsif run("Nop during stall must be ignored") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                memoryControlWordIn.memOp <= true;
                wait until falling_edge(clk);
                nop <= true;
                stall <= true;
                wait until falling_edge(clk);
                check(memoryControlWordOut.memOp);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);
    idexReg : entity src.mips32_pipeline_idexRegister
    port map (
        clk => clk,
        -- Control in
        stall => stall,
        nop => nop,
        -- Pipeline control in
        executeControlWordIn => executeControlWordIn,
        memoryControlWordIn => memoryControlWordIn,
        writeBackControlWordIn => writeBackControlWordIn,
        -- Pipeline data in
        programCounterPlusFourIn => programCounterPlusFourIn,
        rsDataIn => rsDataIn,
        rsAddressIn => rsAddressIn,
        rtDataIn => rtDataIn,
        rtAddressIn => rtAddressIn,
        immidiateIn => immidiateIn,
        destinationRegIn => destinationRegIn,
        rdAddressIn => rdAddressIn,
        shamtIn => shamtIn,
        -- Pipeline control out
        executeControlWordOut => executeControlWordOut,
        memoryControlWordOut => memoryControlWordOut,
        writeBackControlWordOut => writeBackControlWordOut,
        -- Pipeline data out
        programCounterPlusFourOut => programCounterPlusFourOut,
        rsDataOut => rsDataOut,
        rsAddressOut => rsAddressOut,
        rtDataOut => rtDataOut,
        rtAddressOut => rtAddressOut,
        immidiateOut => immidiateOut,
        destinationRegOut => destinationRegOut,
        rdAddressOut => rdAddressOut,
        shamtOut => shamtOut
    );
end architecture;
