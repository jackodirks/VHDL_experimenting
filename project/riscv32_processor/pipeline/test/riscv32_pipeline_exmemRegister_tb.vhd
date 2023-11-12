library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.riscv32_pkg.all;

entity riscv32_pipeline_exmemRegister_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of riscv32_pipeline_exmemRegister_tb is
    constant clk_period : time := 20 ns;
    signal clk : std_logic := '0';
    -- Control in
    signal stall : boolean := false;
    signal nop : boolean := false;
    -- Pipeline control in
    signal memoryControlWordIn : riscv32_MemoryControlWord_type := riscv32_memoryControlWordAllFalse;
    signal writeBackControlWordIn : riscv32_WriteBackControlWord_type := riscv32_writeBackControlWordAllFalse;
    -- Pipeline data in
    signal execResultIn : riscv32_data_type := (others => '0');
    signal rs2DataIn : riscv32_data_type := (others => '0');
    signal rdAddressIn : riscv32_registerFileAddress_type := 0;
    -- Pipeline control out
    signal memoryControlWordOut : riscv32_MemoryControlWord_type;
    signal writeBackControlWordOut : riscv32_WriteBackControlWord_type;
    -- Pipeline data out
    signal execResultOut : riscv32_data_type;
    signal rs2DataOut : riscv32_data_type;
    signal rdAddressOut : riscv32_registerFileAddress_type;
begin
    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Push nop on first rising edge") then
                wait until rising_edge(clk);
                check(memoryControlWordOut = riscv32_memoryControlWordAllFalse);
                check(writeBackControlWordOut = riscv32_writeBackControlWordAllFalse);
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
    exMemReg : entity src.riscv32_pipeline_exmemRegister
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
        rs2DataIn => rs2DataIn,
        rdAddressIn => rdAddressIn,
        -- Pipeline control out
        memoryControlWordOut => memoryControlWordOut,
        writeBackControlWordOut => writeBackControlWordOut,
        -- Pipeline data out
        execResultOut => execResultOut,
        rs2DataOut => rs2DataOut,
        rdAddressOut => rdAddressOut
    );
end architecture;
