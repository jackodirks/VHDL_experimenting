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
    signal rst : std_logic := '0';

    signal mst2slv : bus_pkg.bus_mst2slv_type := bus_pkg.BUS_MST2SLV_IDLE;
    signal slv2mst : bus_pkg.bus_slv2mst_type := bus_pkg.BUS_SLV2MST_IDLE;

    signal controllerReset : boolean;
    signal controllerStall : boolean;

begin

    clk <= not clk after (clk_period/2);

    main : process
        variable actualAddress : std_logic_vector(bus_pkg.bus_address_type'range);
        variable expectedValue : bus_pkg.bus_data_type;
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
            elsif run("Before first rising edge, controllerReset is true") then
                wait until rising_edge(clk);
                check(controllerReset);
            elsif run("Writing 0 to address 0 clears controllerReset") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => (others => '0'),
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                check(not controllerReset);
            elsif run("Writing 1 to address 0 sets controllerReset") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => (others => '0'),
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => (others => '1'),
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                check(controllerReset);
            elsif run("Debug controller errors on invalid writeMask") then
               mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                    write_data => (others => '0'),
                                                    write_mask => (others => '0'));
               wait until rising_edge(clk) and bus_pkg.any_transaction(mst2slv, slv2mst);
                check(bus_pkg.fault_transaction(mst2slv, slv2mst));
                check_equal(slv2mst.faultData, bus_pkg.bus_fault_illegal_write_mask);
            elsif run("Reading back register works") then
                mst2slv <= bus_pkg.bus_mst2slv_read(address => (others => '0'));
                wait until rising_edge(clk) and bus_pkg.read_transaction(mst2slv, slv2mst);
                expectedValue := (0 => '1', others => '0');
                check_equal(slv2mst.readData, expectedValue);
            elsif run("Before first rising edge, controllerStall is false") then
                wait until rising_edge(clk);
                check(not controllerStall);
            elsif run("Writing 0x2 to address 0 sets controllerStall") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => X"00000002",
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                check(controllerStall);
            elsif run("Writing 0x0 to address 0 clears controllerStall") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => X"00000002",
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => X"00000000",
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                check(not controllerStall);
            elsif run("rst clears controllerStall") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => X"00000002",
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                mst2slv <= bus_pkg.BUS_MST2SLV_IDLE;
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not controllerStall);
            elsif run("rst sets controllerReset") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => X"00000000",
                                                     write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                mst2slv <= bus_pkg.BUS_MST2SLV_IDLE;
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(controllerReset);
            elsif run("rst sets bus slave to idle") then
                mst2slv <= bus_pkg.bus_mst2slv_write(address => (others => '0'),
                                                     write_data => X"00000000",
                                                     write_mask => (others => '1'));
                wait until falling_edge(clk) and bus_pkg.write_transaction(mst2slv, slv2mst);
                rst <= '1';
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check(not bus_pkg.write_transaction(mst2slv, slv2mst));
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
        rst => rst,
        mst2debug => mst2slv,
        debug2mst => slv2mst,
        controllerReset => controllerReset,
        controllerStall => controllerStall
    );
end architecture;
