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
        variable writeMask : bus_write_mask;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Write without increment") then
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
