library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg;
use src.mips32_pkg;

entity mips32_debug_controller_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_debug_controller_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';

    signal mst2slv : bus_pkg.bus_mst2slv_type := bus_pkg.BUS_MST2SLV_IDLE;
    signal slv2mst : bus_pkg.bus_slv2mst_type := bus_pkg.BUS_SLV2MST_IDLE;

    signal programCounter : mips32_pkg.address_type := (others => '0');


begin

    clk <= not clk after (clk_period/2);

    main : process
        variable actualAddress : std_logic_vector(bus_pkg.bus_address_type'range);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Debug controller errors on unaligned address") then
                actualAddress := X"00000001";
                mst2slv <= bus_pkg.bus_mst2slv_read(address => actualAddress);
                wait until rising_edge(clk) and bus_pkg.any_transaction(mst2slv, slv2mst);
                check(bus_pkg.fault_transaction(mst2slv, slv2mst));
                check_equal(slv2mst.faultData, bus_pkg.bus_fault_unaligned_access);
            elsif run("Debug controller errors on address out of range") then
                actualAddress := X"00000004";
                mst2slv <= bus_pkg.bus_mst2slv_read(address => actualAddress);
                wait until rising_edge(clk) and bus_pkg.any_transaction(mst2slv, slv2mst);
                check(bus_pkg.fault_transaction(mst2slv, slv2mst));
                check_equal(slv2mst.faultData, bus_pkg.bus_fault_address_out_of_range);
            elsif run("Debug controller returns PC on address 0") then
                actualAddress := X"00000000";
                mst2slv <= bus_pkg.bus_mst2slv_read(address => actualAddress);
                programCounter <= X"00112233";
                wait until rising_edge(clk) and bus_pkg.any_transaction(mst2slv, slv2mst);
                check(bus_pkg.read_transaction(mst2slv, slv2mst));
                check_equal(programCounter, slv2mst.readData);
            elsif run("Debug controller silently ignores writes on address 0") then
                actualAddress := X"00000000";
                mst2slv <= bus_pkg.bus_mst2slv_write(address => actualAddress, write_data => actualAddress, write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.any_transaction(mst2slv, slv2mst);
                check(bus_pkg.write_transaction(mst2slv, slv2mst));
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    debug_controller : entity src.mips32_debug_controller
    port map (
        clk => clk,
        mst2debug => mst2slv,
        debug2mst => slv2mst,
        programCounter => programCounter
    );
end architecture;
