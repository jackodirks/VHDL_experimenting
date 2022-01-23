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

entity depp_slave_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of depp_slave_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal depp_db : std_logic_vector(7 downto 0) := (others => '0');
    signal depp_write : std_logic := '1';
    signal depp_astb : std_logic := '1';
    signal depp_dstb : std_logic := '1';
    signal depp_wait : std_logic;

    signal depp2bus : depp2bus_type := DEPP2BUS_IDLE;
    signal bus2depp : bus2depp_type := BUS2DEPP_IDLE;

begin

    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Set and get address") then
                -- Initial situation
                wait for clk_period;
                -- Write address
                check_equal('0', depp_wait);
                depp_db <= std_logic_vector(to_unsigned(14, depp_db'length));
                depp_write <= '0';
                depp_astb <= '0';
                wait until depp_wait = '1';
                wait for 4*clk_period;
                check_equal(depp_wait, '1');
                depp_write <= '1';
                depp_astb <= '1';
                depp_db <= (others => 'Z');
                wait until depp_wait = '0';
                -- Read address back
                depp_write <= '1';
                depp_astb <= '0';
                wait until depp_wait = '1';
                check_equal(to_integer(unsigned(depp_db)), 14);
                wait for 4*clk_period;
                check_equal(depp_wait, '1');
                check_equal(to_integer(unsigned(depp_db)), 14);
                depp_write <= '1';
                depp_astb <= '1';
                wait until depp_wait = '0';
            end if;
            if run("Read from address") then
                -- Initial situation
                wait for clk_period;
                -- Write address
                check_equal('0', depp_wait);
                depp_db <= std_logic_vector(to_unsigned(14, depp_db'length));
                depp_write <= '0';
                depp_astb <= '0';
                wait until depp_wait = '1';
                depp_write <= '1';
                depp_astb <= '1';
                depp_db <= (others => 'Z');
                wait until depp_wait = '0';
                -- Start a read operation
                depp_write <= '1';
                depp_dstb <= '0';
                wait until depp2bus.readEnable = true;
                check_equal(to_integer(unsigned(depp2bus.address)), 14);
                check_equal(depp2bus.writeEnable, false);
                wait for 5*clk_period;
                check_equal(depp_wait, '0');
                check_equal(to_integer(unsigned(depp2bus.address)), 14);
                check_equal(depp2bus.readEnable, true);
                check_equal(depp2bus.writeEnable, false);

                bus2depp.readData <= std_logic_vector(to_unsigned(255, bus2depp.readData'length));
                bus2depp.done <= true;
                wait until depp2bus.readEnable = false;
                check_equal(depp2bus.writeEnable, false);
                wait for clk_period;
                bus2depp.readData <= std_logic_vector(to_unsigned(0, bus2depp.readData'length));
                bus2depp.done <= false;
                wait for clk_period;
                check_equal(depp_wait, '1');
                check_equal(to_integer(unsigned(depp_db)), 255);
                wait for 3*clk_period;
                check_equal(depp_wait, '1');
                check_equal(to_integer(unsigned(depp_db)), 255);
                depp_dstb <= '1';
                depp_write <= '1';
                wait until depp_wait = '0';
            end if;
            if run("Write from address") then
                -- Initial situation
                wait for clk_period;
                -- Write address
                check_equal('0', depp_wait);
                depp_db <= std_logic_vector(to_unsigned(14, depp_db'length));
                depp_write <= '0';
                depp_astb <= '0';
                wait until depp_wait = '1';
                depp_write <= '1';
                depp_astb <= '1';
                depp_db <= (others => 'Z');
                wait until depp_wait = '0';
                -- Start a write operation
                depp_write <= '0';
                depp_dstb <= '0';
                depp_db <= std_logic_vector(to_unsigned(28, depp_db'length));
                wait until depp2bus.writeEnable = true;
                check_equal(to_integer(unsigned(depp2bus.address)), 14);
                check_equal(to_integer(unsigned(depp2bus.writeData)), 28);
                check_equal(depp2bus.readEnable, false);
                wait for 5*clk_period;
                check_equal(depp_wait, '0');
                check_equal(to_integer(unsigned(depp2bus.address)), 14);
                check_equal(to_integer(unsigned(depp2bus.writeData)), 28);
                check_equal(depp2bus.writeEnable, true);
                check_equal(depp2bus.readEnable, false);
                bus2depp.done <= true;
                wait until depp2bus.writeEnable = false;
                check_equal(depp2bus.readEnable, false);
                wait for clk_period;
                bus2depp.done <= false;
                wait for clk_period;
                check_equal(depp_wait, '1');
                wait for 3*clk_period;
                check_equal(depp_wait, '1');
                depp_dstb <= '1';
                depp_write <= '1';
                wait until depp_wait = '0';
            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 10 ms);

    controller : entity src.depp_slave
    port map (
        rst => rst,
        clk => clk,
        depp2bus => depp2bus,
        bus2depp => bus2depp,
        USB_DB => depp_db,
        USB_WRITE => depp_write,
        USB_ASTB => depp_astb,
        USB_DSTB => depp_dstb,
        USB_WAIT => depp_wait
    );

end tb;
