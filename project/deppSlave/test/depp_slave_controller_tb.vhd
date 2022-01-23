library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;

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
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Simple transaction") then
                -- Initial situation
                wait for clk_period;
                check_equal('0', depp_wait);
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
