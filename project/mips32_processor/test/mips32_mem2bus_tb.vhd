library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library tb;
use tb.simulated_bus_memory_pkg;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_mem2bus_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_mem2bus_tb is
    constant clk_period : time := 20 ns;
    constant slaveActor : actor_t := new_actor("slave");

    signal forbidBusInteraction : boolean := false;
    signal flushCache : boolean := false;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal mst2slv : bus_mst2slv_type;
    signal slv2mst : bus_slv2mst_type;

    signal hasFault : boolean;
    signal faultData : bus_fault_type;

    signal address : mips32_address_type := (others => '0');
    signal dataIn : mips32_data_type := (others => '0');
    signal dataOut : mips32_data_type;
    signal doWrite : boolean := false;
    signal doRead : boolean := false;

    signal stall : boolean;
begin

    clk <= not clk after (clk_period/2);

    main : process
        variable expectedWriteData : mips32_data_type;
        variable expectedWriteAddress : mips32_address_type;
        variable writeAddress : bus_address_type;
        variable byteMask : bus_byte_mask_type;
        variable writeData : bus_data_type;
        variable memReadData : bus_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Requesting read stalls before next rising_edge") then
                doRead <= true;
                wait until rising_edge(clk);
                check(stall);
            elsif run("Requesting read stalls until data is ready") then
                writeAddress := X"00000004";
                byteMask := (others => '1');
                writeData := X"01234567";
                simulated_bus_memory_pkg.write_to_address(
                    net => net,
                    actor => slaveActor,
                    addr => writeAddress,
                    mask => byteMask,
                    data => writeData);
                doRead <= true;
                address <= writeAddress;
                wait until rising_edge(clk) and not stall;
                check_equal(dataOut, writeData);
            elsif run("Single write does lead to stall") then
                doWrite <= true;
                wait until rising_edge(clk);
                check(stall);
            elsif run("Requesting write stalls until transaction is finished") then
                expectedWriteData := X"AABBCCDD";
                expectedWriteAddress := X"00000008";
                dataIn <= expectedWriteData;
                address <= expectedWriteAddress;
                doWrite <= true;
                wait until rising_edge(clk) and not stall;
                simulated_bus_memory_pkg.read_from_address(
                    net => net,
                    actor => slaveActor,
                    addr => expectedWriteAddress,
                    data => memReadData);
                check_equal(memReadData, expectedWriteData);
            elsif run("Requesting write then read works as expected") then
                expectedWriteData := X"AABBCCDD";
                expectedWriteAddress := X"00000008";
                dataIn <= expectedWriteData;
                address <= expectedWriteAddress;
                doWrite <= true;
                wait until rising_edge(clk) and not stall;
                doWrite <= false;
                doRead <= true;
                wait until rising_edge(clk) and not stall;
                check_equal(dataOut, expectedWriteData);
            elsif run("Bus fault blocks device") then
                expectedWriteData := X"AABBCCDD";
                expectedWriteAddress := X"10000000";
                dataIn <= expectedWriteData;
                address <= expectedWriteAddress;
                doWrite <= true;
                wait until rising_edge(clk) and hasFault;
                check_equal(faultData, bus_fault_address_out_of_range);
                check(stall);
            elsif run("Reset fixes bus fault block") then
                expectedWriteData := X"AABBCCDD";
                expectedWriteAddress := X"10000000";
                dataIn <= expectedWriteData;
                address <= expectedWriteAddress;
                doWrite <= true;
                wait until rising_edge(clk) and hasFault;
                doWrite <= false;
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not stall);
            elsif run("Reading same thing twice results in one stall") then
                writeAddress := X"00000004";
                byteMask := (others => '1');
                writeData := X"01234567";
                simulated_bus_memory_pkg.write_to_address(
                    net => net,
                    actor => slaveActor,
                    addr => writeAddress,
                    mask => byteMask,
                    data => writeData);
                doRead <= true;
                address <= writeAddress;
                wait until rising_edge(clk) and not stall;
                wait until rising_edge(clk);
                check(not stall);
            elsif run("Writing the same thing twice results in one stall") then
                expectedWriteData := X"AABBCCDD";
                expectedWriteAddress := X"00000008";
                dataIn <= expectedWriteData;
                address <= expectedWriteAddress;
                doWrite <= true;
                wait until rising_edge(clk) and not stall;
                wait until rising_edge(clk);
                check(not stall);
            elsif run("forbidBusInteraction prevents bus interaction") then
                expectedWriteData := X"AABBCCDD";
                expectedWriteAddress := X"00000008";
                dataIn <= expectedWriteData;
                address <= expectedWriteAddress;
                doWrite <= true;
                forbidBusInteraction <= true;
                wait until rising_edge(clk);
                check(stall);
                wait until falling_edge(clk);
                check(not bus_requesting(mst2slv));
            elsif run("Flushing the cache does lead to two reads") then
                writeAddress := X"00000004";
                byteMask := (others => '1');
                writeData := X"01234567";
                simulated_bus_memory_pkg.write_to_address(
                    net => net,
                    actor => slaveActor,
                    addr => writeAddress,
                    mask => byteMask,
                    data => writeData);
                doRead <= true;
                address <= writeAddress;
                wait until rising_edge(clk) and not stall;
                flushCache <= true;
                wait until rising_edge(clk);
                flushCache <= false;
                wait until rising_edge(clk);
                check(stall);
                wait until falling_edge(clk);
                check(bus_requesting(mst2slv));
            elsif run("Relevant write after read should reread") then
                writeAddress := X"00000004";
                byteMask := (others => '1');
                writeData := X"01234567";
                simulated_bus_memory_pkg.write_to_address(
                    net => net,
                    actor => slaveActor,
                    addr => writeAddress,
                    mask => byteMask,
                    data => writeData);
                doRead <= true;
                address <= writeAddress;
                wait until rising_edge(clk) and not stall;
                writeData := X"AAAABBBB";
                dataIn <= writeData;
                doRead <= false;
                doWrite <= true;
                wait until rising_edge(clk) and not stall;
                doWrite <= false;
                doRead <= true;
                wait until rising_edge(clk) and not stall;
                check_equal(dataOut, writeData);
            elsif run("no-op after read should reread") then
                writeAddress := X"00000004";
                doWrite <= true;
                address <= writeAddress;
                dataIn <= writeData;
                wait until rising_edge(clk) and not stall;
                doWrite <= false;
                wait until rising_edge(clk);
                doWrite <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(bus_requesting(mst2slv));
            elsif run("no-op after write should rewrite") then
                writeAddress := X"00000004";
                byteMask := (others => '1');
                writeData := X"01234567";
                doRead <= true;
                address <= writeAddress;
                wait until rising_edge(clk) and not stall;
                doRead <= false;
                wait until rising_edge(clk);
                doRead <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(bus_requesting(mst2slv));
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    mem2bus : entity src.mips32_mem2bus
    port map (
        clk => clk,
        rst => rst,
        forbidBusInteraction => forbidBusInteraction,
        flushCache => flushCache,
        mst2slv => mst2slv,
        slv2mst => slv2mst,
        hasFault => hasFault,
        faultData => faultData,
        address => address,
        dataIn => dataIn,
        dataOut => dataOut,
        doWrite => doWrite,
        doRead => doRead,
        stall => stall
    );

    bus_slave : entity tb.simulated_bus_memory
    generic map (
        depth_log2b => 11,
        allow_unaligned_access => true,
        actor => slaveActor,
        read_delay => 5,
        write_delay => 5
    ) port map (
        clk => clk,
        mst2mem => mst2slv,
        mem2mst => slv2mst
    );
end architecture;
