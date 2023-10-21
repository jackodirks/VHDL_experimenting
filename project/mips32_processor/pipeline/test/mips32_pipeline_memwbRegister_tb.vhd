library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_pipeline_memwbRegister_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_memwbRegister_tb is
    constant clk_period : time := 20 ns;
    signal clk : std_logic := '0';
    -- Control in
    signal stall : boolean := false;
    signal nop : boolean := false;
    -- Pipeline control in
    signal writeBackControlWordIn : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    -- Pipeline data in
    signal execResultIn : mips32_data_type := (others => '0');
    signal memDataReadIn : mips32_data_type := (others => '0');
    signal destinationRegIn : mips32_registerFileAddress_type := 0;
    signal regWrite_override_in : boolean := false;
    -- Pipeline control out
    signal writeBackControlWordOut : mips32_WriteBackControlWord_type;
    -- Pipeline data out
    signal execResultOut : mips32_data_type;
    signal memDataReadOut : mips32_data_type;
    signal destinationRegOut : mips32_registerFileAddress_type;
    signal regWrite_override_out : boolean;
begin
    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Push nop on first rising edge") then
                wait until rising_edge(clk);
                check(writeBackControlWordOut = mips32_writeBackControlWordAllFalse);
            elsif run("Forwards input on rising edge if stall = nop = false") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                writeBackControlWordIn.regWrite <= true;
                wait until falling_edge(clk);
                check(writeBackControlWordOut.regWrite);
            elsif run("Holds input if stall = true") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                writeBackControlWordIn.regWrite <= true;
                wait until falling_edge(clk);
                stall <= true;
                writeBackControlWordIn.regWrite <= false;
                wait until falling_edge(clk);
                check(writeBackControlWordOut.regWrite);
            elsif run("Clears control words if nop = true") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                writeBackControlWordIn.regWrite <= true;
                regWrite_override_in <= true;
                wait until falling_edge(clk);
                nop <= true;
                wait until falling_edge(clk);
                check(not writeBackControlWordOut.regWrite);
                check(not regWrite_override_out);
            elsif run("Nop during stall must be ignored") then
                wait until falling_edge(clk);
                stall <= false;
                nop <= false;
                writeBackControlWordIn.regWrite <= true;
                wait until falling_edge(clk);
                nop <= true;
                stall <= true;
                wait until falling_edge(clk);
                check(writeBackControlWordOut.regWrite);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);
    memwbReg : entity src.mips32_pipeline_memwbRegister
    port map (
        clk => clk,
        -- Control in
        stall => stall,
        nop => nop,
        -- Pipeline control in
        writeBackControlWordIn => writeBackControlWordIn,
        -- Pipeline data in
        execResultIn => execResultIn,
        memDataReadIn => memDataReadIn,
        destinationRegIn => destinationRegIn,
        regWrite_override_in => regWrite_override_in,
        -- Pipeline control out
        writeBackControlWordOut => writeBackControlWordOut,
        -- Pipeline data out
        execResultOut => execResultOut,
        memDataReadOut => memDataReadOut,
        destinationRegOut => destinationRegOut,
        regWrite_override_out => regWrite_override_out
    );
end architecture;
