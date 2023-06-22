library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg;
use src.depp_pkg;

library tb;
use tb.simulated_bus_memory_pkg;
use tb.simulated_depp_master_pkg;

entity depp_slave_controller_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of depp_slave_controller_tb is
    constant clk_period : time := 20 ns;
    constant slaveActor : actor_t := new_actor("slave");
    constant deppMasterActor : actor_t := new_actor("Depp Master");

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal usb_db : std_logic_vector(7 downto 0) := (others => '0');
    signal usb_write : std_logic := '1';
    signal usb_astb : std_logic := '1';
    signal usb_dstb : std_logic := '1';
    signal usb_wait : std_logic;

    signal mst2slv : bus_pkg.bus_mst2slv_type;
    signal slv2mst : bus_pkg.bus_slv2mst_type;

begin
    clk <= not clk after (clk_period/2);
    main : process
        variable address : bus_pkg.bus_address_type;
        variable byteMask : bus_pkg.bus_byte_mask_type;
        variable writeData : bus_pkg.bus_data_type;
        variable readData : bus_pkg.bus_data_type;
        variable faultData : bus_pkg.bus_fault_type;
        variable faultAddress : bus_pkg.bus_address_type;
        variable writeDataArray : bus_pkg.bus_data_array(300 downto 0);
        variable readDataArray : bus_pkg.bus_data_array(300 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Single write") then
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := (others => '1');
                writeData := std_logic_vector(to_unsigned(512, writeData'length));
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeData);
                simulated_bus_memory_pkg.read_from_address(
                    net => net,
                    actor => slaveActor,
                    addr => address,
                    data => readData);
                check_equal(readData, writeData);
            elsif run("Partial write") then
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := (others => '1');
                writeData := (others => '0');
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeData);
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := "1010";
                writeData := (others => '1');
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeData);
                simulated_bus_memory_pkg.read_from_address(
                    net => net,
                    actor => slaveActor,
                    addr => address,
                    data => readData);
                writeData := X"FF00FF00";
                check_equal(readData, writeData);
            elsif run("Single read") then
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := (others => '1');
                writeData := std_logic_vector(to_unsigned(512, writeData'length));
                simulated_bus_memory_pkg.write_to_address(
                    net => net,
                    actor => slaveActor,
                    addr => address,
                    mask => byteMask,
                    data => writeData);
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    data => readData);
                check_equal(readData, writeData);
            elsif run("Single faulty write") then
                address := std_logic_vector(to_unsigned(16#800#, address'length));
                byteMask := (others => '1');
                writeData := std_logic_vector(to_unsigned(512, writeData'length));
                simulated_depp_master_pkg.write_to_address_expecting_fault(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeData,
                    faultData => faultData,
                    faultAddress => faultAddress);
                check_equal(faultData, bus_pkg.bus_fault_address_out_of_range);
                check_equal(faultAddress, address);
            elsif run("Single faulty read") then
                address := std_logic_vector(to_unsigned(16#800#, address'length));
                simulated_depp_master_pkg.read_from_address_expecting_fault(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    data => readData,
                    faultData => faultData,
                    faultAddress => faultAddress);
                check_equal(faultData, bus_pkg.bus_fault_address_out_of_range);
                check_equal(faultAddress, address);
            elsif run("Large write transaction") then
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := (others => '1');
                for i in 0 to writeDataArray'length - 1 loop
                    writeDataArray(i) := std_logic_vector(to_unsigned(i, writeDataArray(i)'length));
                end loop;
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeDataArray);
                simulated_bus_memory_pkg.read_from_address(
                    net => net,
                    actor => slaveActor,
                    addr => address,
                    data => readDataArray);
                for i in 0 to writeDataArray'length - 1 loop
                    check_equal(readDataArray(i), writeDataArray(i), "At index " & natural'image(i));
                end loop;
            elsif run("Large faulty write transaction") then
                address := std_logic_vector(to_unsigned(1448, address'length));
                byteMask := (others => '1');
                for i in 0 to writeDataArray'length - 1 loop
                    writeDataArray(i) := std_logic_vector(to_unsigned(i, writeDataArray(i)'length));
                end loop;
                simulated_depp_master_pkg.write_to_address_expecting_fault(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeDataArray,
                    faultData => faultData,
                    faultAddress => faultAddress);
                check_equal(faultData, bus_pkg.bus_fault_address_out_of_range);
                address := std_logic_vector(to_unsigned(2648, address'length));
                check_equal(faultAddress, address);
                address := std_logic_vector(to_unsigned(844, address'length));
                simulated_bus_memory_pkg.read_from_address(
                    net => net,
                    actor => slaveActor,
                    addr => address,
                    data => readDataArray);
                for i in 151 to writeDataArray'length - 1 loop
                    check_equal(readDataArray(i), writeDataArray(i - 151), "At index " & natural'image(i));
                end loop;
            elsif run("Large read transaction") then
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := (others => '1');
                for i in 0 to writeDataArray'length - 1 loop
                    writeDataArray(i) := std_logic_vector(to_unsigned(i, writeDataArray(i)'length));
                end loop;
                simulated_bus_memory_pkg.write_to_address(
                    net => net,
                    actor => slaveActor,
                    addr => address,
                    mask => byteMask,
                    data => writeDataArray);
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    data => readDataArray);
                for i in 0 to writeDataArray'length - 1 loop
                    check_equal(readDataArray(i), writeDataArray(i), "At index " & natural'image(i));
                end loop;
            elsif run("Large write transaction then large read transaction") then
                address := std_logic_vector(to_unsigned(0, address'length));
                byteMask := (others => '1');
                for i in 0 to writeDataArray'length - 1 loop
                    writeDataArray(i) := std_logic_vector(to_unsigned(i, writeDataArray(i)'length));
                end loop;
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    mask => byteMask,
                    data => writeDataArray);
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    data => readDataArray);
                for i in 0 to writeDataArray'length - 1 loop
                    check_equal(readDataArray(i), writeDataArray(i), "At index " & natural'image(i));
                end loop;
            end if;
        end loop;
        wait for 2*clk_period;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 10 ms);

    depp_slave : entity src.depp_slave_controller
    port map (
        rst => rst,
        clk => clk,
        mst2slv => mst2slv,
        slv2mst => slv2mst,
        USB_DB => usb_db,
        USB_WRITE => usb_write,
        USB_ASTB => usb_astb,
        USB_DSTB => usb_dstb,
        USB_WAIT => usb_wait
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

    depp_master : entity tb.simulated_depp_master
    generic map (
        actor => deppMasterActor
    ) port map (
        usb_db => usb_db,
        usb_write => usb_write,
        usb_astb => usb_astb,
        usb_dstb => usb_dstb,
        usb_wait => usb_wait
    );
end architecture;
