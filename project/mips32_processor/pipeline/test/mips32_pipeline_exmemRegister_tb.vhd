library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_pipeline_exmemRegister_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_exmemRegister_tb is
    constant clk_period : time := 20 ns;
    signal clk : std_logic := '0';
    -- Control in
    signal stall : boolean := false;
    signal nop : boolean := false;
    -- Pipeline control in
    signal memoryControlWordIn : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
    signal writeBackControlWordIn : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    -- Pipeline data in
    signal execResultIn : mips32_data_type := (others => '0');
    signal regDataReadIn : mips32_data_type := (others => '0');
    signal destinationRegIn : mips32_registerFileAddress_type := 0;
    signal rdAddressIn : mips32_registerFileAddress_type := 0;
    signal has_branched_in : boolean := false;
    -- Pipeline control out
    signal memoryControlWordOut : mips32_MemoryControlWord_type;
    signal writeBackControlWordOut : mips32_WriteBackControlWord_type;
    -- Pipeline data out
    signal execResultOut : mips32_data_type;
    signal regDataReadOut : mips32_data_type;
    signal destinationRegOut : mips32_registerFileAddress_type;
    signal rdAddressOut : mips32_registerFileAddress_type;
    signal has_branched_out : boolean;
begin
    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Push nop on first rising edge") then
                wait until rising_edge(clk);
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
    exMemReg : entity src.mips32_pipeline_exmemRegister
    port map (
        clk => clk,
        -- Control in
        stall => stall,
        nop => nop,
        -- Pipeline control in
        memoryControlWordIn => memoryControlWordIn,
        writeBackControlWordIn => writeBackControlWordIn,
        -- Pipeline data in
        execResultIn => execResultIn,
        regDataReadIn => regDataReadIn,
        destinationRegIn => destinationRegIn,
        rdAddressIn => rdAddressIn,
        has_branched_in => has_branched_in,
        -- Pipeline control out
        memoryControlWordOut => memoryControlWordOut,
        writeBackControlWordOut => writeBackControlWordOut,
        -- Pipeline data out
        execResultOut => execResultOut,
        regDataReadOut => regDataReadOut,
        destinationRegOut => destinationRegOut,
        rdAddressOut => rdAddressOut,
        has_branched_out => has_branched_out
    );
end architecture;
