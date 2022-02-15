library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.depp_pkg.all;

library tb;
use tb.depp_tb_pkg.all;

entity depp_slave_controller_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of depp_slave_controller_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal depp_db : std_logic_vector(7 downto 0) := (others => '0');
    signal depp_write : std_logic := '1';
    signal depp_astb : std_logic := '1';
    signal depp_dstb : std_logic := '1';
    signal depp_wait : std_logic;

    signal mst2slv : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal slv2mst : bus_slv2mst_type := BUS_SLV2MST_IDLE;

begin

    clk <= not clk after (clk_period/2);

    main : process
        variable address : bus_address_type;
        variable writeData : bus_data_type;
        variable readData : bus_data_type;
        variable writeMask : bus_write_mask;
        variable deppMode : depp_data_type;
        variable deppAddr : depp_address_type;
        variable expectedState : depp_slave_state_type := DEPP_SLAVE_STATE_TYPE_IDLE;
        variable actualState : depp_slave_state_type := DEPP_SLAVE_STATE_TYPE_IDLE;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Simple write") then
                slv2mst <= BUS_SLV2MST_IDLE;
                depp_db <= (others => 'Z');
                -- Initial situation:
                wait for clk_period;
                check_equal('0', depp_wait);
                wait until falling_edge(clk);
                -- Start setting the output
                address := std_logic_vector(to_unsigned(125, address'length));
                writeData := std_logic_vector(to_unsigned(14, writeData'length));
                writeMask := (others => '1');
                depp_tb_bus_prepare_write(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    address => address,
                    writeData => writeData,
                    writeMask => writeMask
                );
                -- Start the write
                depp_tb_bus_start_transaction(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    doRead => false
                );
                wait for 2*clk_period;
                check_equal(mst2slv.address, address);
                check_equal(mst2slv.writeData, writeData);
                check_equal(mst2slv.writeMask, writeMask);
                check_equal(mst2slv.writeEnable, '1');
                check_equal(mst2slv.readEnable, '0');
                check_equal(depp_wait, '0');
                -- Wait a while, then finish normally
                wait for 26*clk_period;
                wait until falling_edge(clk);
                slv2mst.ack <= '1';
                wait for clk_period;
                check_equal(mst2slv.writeEnable, '0');
                check_equal(mst2slv.readEnable, '0');
                check_equal(depp_wait, '1');
                depp_tb_bus_finish_transaction(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait
                );
                expectedState.address := address;
                expectedState.writeData := writeData;
                expectedState.writeMask := writeMask;
                depp_tb_slave_check_state (
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    actualState => actualState
                );
                check(actualState = expectedState);
            end if;
            if run("Simple read") then
                slv2mst <= BUS_SLV2MST_IDLE;
                depp_db <= (others => 'Z');
                -- Initial situation:
                wait for clk_period;
                check_equal('0', depp_wait);
                wait until falling_edge(clk);
                -- Start setting the output
                address := std_logic_vector(to_unsigned(35, address'length));
                writeData := (others => '0');
                writeMask := (others => '0');
                readData := std_logic_vector(to_unsigned(149, writeData'length));
                depp_tb_bus_prepare_read(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    address => address
                );
                -- Start the read
                depp_tb_bus_start_transaction(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    doRead => true
                );
                wait for 2*clk_period;
                check_equal(mst2slv.address, address);
                check_equal(mst2slv.writeData, writeData);
                check_equal(mst2slv.writeMask, writeMask);
                check_equal(mst2slv.writeEnable, '0');
                check_equal(mst2slv.readEnable, '1');
                check_equal(depp_wait, '0');
                wait for 26*clk_period;
                wait until falling_edge(clk);
                slv2mst.ack <= '1';
                slv2mst.readData <= readData;
                wait for clk_period;
                check_equal(mst2slv.writeEnable, '0');
                check_equal(mst2slv.readEnable, '0');
                check_equal(depp_wait, '1');
                depp_tb_bus_finish_transaction(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait
                );
                expectedState.address := address;
                expectedState.writeData := writeData;
                expectedState.readData := readData;
                expectedState.writeMask := writeMask;
                depp_tb_slave_check_state (
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    actualState => actualState
                );
                check(actualState = expectedState);
            end if;
            if run("Write returns error") then
                slv2mst <= BUS_SLV2MST_IDLE;
                depp_db <= (others => 'Z');
                -- Initial situation:
                wait for clk_period;
                check_equal('0', depp_wait);
                wait until falling_edge(clk);
                -- Start setting the output
                address := std_logic_vector(to_unsigned(114, address'length));
                writeData := std_logic_vector(to_unsigned(25, writeData'length));
                readData := (others => '1');
                writeMask := (others => '1');
                depp_tb_bus_prepare_write(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    address => address,
                    writeData => writeData,
                    writeMask => writeMask
                );
                -- Start the write
                depp_tb_bus_start_transaction(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    doRead => false
                );
                wait for 2*clk_period;
                check_equal(mst2slv.address, address);
                check_equal(mst2slv.writeData, writeData);
                check_equal(mst2slv.writeMask, writeMask);
                check_equal(mst2slv.writeEnable, '1');
                check_equal(mst2slv.readEnable, '0');
                check_equal(depp_wait, '0');
                -- Wait a while, then finish normally
                wait for 26*clk_period;
                wait until falling_edge(clk);
                slv2mst.fault <= '1';
                slv2mst.readData <= readData;
                wait for clk_period;
                check_equal(mst2slv.writeEnable, '0');
                check_equal(mst2slv.readEnable, '0');
                check_equal(depp_wait, '1');
                depp_tb_bus_finish_transaction(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait
                );
                expectedState.address := address;
                expectedState.writeData := writeData;
                expectedState.writeMask := writeMask;
                expectedState.readData := readData;
                expectedState.fault := true;
                depp_tb_slave_check_state (
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    actualState => actualState
                );
                check(actualState = expectedState);
            end if;
            if run("Sequential write mode") then
                slv2mst <= BUS_SLV2MST_IDLE;
                address := (others => '0');
                writeData := (others => '0');
                readData := (others => '0');
                writeMask := (others => '0');
                deppMode := (others => '0');
                deppMode(depp_mode_fast_write_bit) := '1';
                deppAddr := std_logic_vector(to_unsigned(depp2bus_mode_register_start, deppAddr'length));
                -- Initial situation:
                wait for clk_period;
                check_equal('0', depp_wait);
                -- Enable sequential write mode
                depp_tb_depp_write_to_address(
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    addr => deppAddr,
                    data => deppMode
                );
                -- Set the start address
                depp_tb_bus_set_address (
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    address => address
                );
                deppAddr := std_logic_vector(to_unsigned(depp2bus_writeData_reg_start, deppAddr'length));
                depp_tb_depp_set_address (
                    clk => clk,
                    usb_db => depp_db,
                    usb_write => depp_write,
                    usb_astb => depp_astb,
                    usb_dstb => depp_dstb,
                    usb_wait => depp_wait,
                    addr => deppAddr
                );
                for i in 0 to 20 loop
                    writeData := std_logic_vector(to_unsigned(i, writeData'length));
                    address := std_logic_vector(to_unsigned(i*depp2bus_writeData_reg_len, address'length));
                    for j in 0 to depp2bus_writeData_reg_len - 1 loop
                        depp_tb_depp_set_data(
                            clk => clk,
                            usb_db => depp_db,
                            usb_write => depp_write,
                            usb_astb => depp_astb,
                            usb_dstb => depp_dstb,
                            usb_wait => depp_wait,
                            data => writeData((j+1)*8 - 1 downto j*8),
                            expect_completion => (j /= depp2bus_writeData_reg_len - 1)
                        );
                    end loop;
                    wait until mst2slv.writeEnable = '1';
                    check_equal(mst2slv.address, address);
                    check_equal(mst2slv.writeData, writeData);
                    check_equal(mst2slv.writeMask, writeMask);
                    check_equal(mst2slv.writeEnable, '1');
                    check_equal(mst2slv.readEnable, '0');
                    check_equal(depp_wait, '0');
                    slv2mst.ack <= '1';
                    depp_tb_bus_finish_transaction(
                        clk => clk,
                        usb_db => depp_db,
                        usb_write => depp_write,
                        usb_astb => depp_astb,
                        usb_dstb => depp_dstb,
                        usb_wait => depp_wait
                    );
                    slv2mst.ack <= '0';
                end loop;

            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 10 ms);

    controller : entity src.depp_slave_controller
    port map (
        rst => rst,
        clk => clk,
        mst2slv => mst2slv,
        slv2mst => slv2mst,
        USB_DB => depp_db,
        USB_WRITE => depp_write,
        USB_ASTB => depp_astb,
        USB_DSTB => depp_dstb,
        USB_WAIT => depp_wait
    );

end tb;
