library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;

library tb;
use tb.bus_tb_pkg.all;

entity bus_demux_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of bus_demux_tb is

    constant clk_period : time := 20 ns;

    constant firstRange     :   addr_range_and_mapping_type := address_range_and_map(
        low => std_logic_vector(to_unsigned(0, bus_address_type'length)),
        high => std_logic_vector(to_unsigned(15, bus_address_type'length))
    );

    constant secondRangeMap : addrMapping_type := bus_map_constant(bus_address_type'high - 4, '0') & bus_map_range(4, 0);

    constant secondRange    :   addr_range_and_mapping_type := address_range_and_map(
        low => std_logic_vector(to_unsigned(32, bus_address_type'length)),
        high => std_logic_vector(to_unsigned(63, bus_address_type'length)),
        mapping => secondRangeMap
    );

    signal demux2firstSlave : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal demux2secondSlave : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal firstSlave2demux : bus_slv2mst_type := BUS_SLV2MST_IDLE;
    signal secondSlave2demux : bus_slv2mst_type := BUS_SLV2MST_IDLE;

    signal demux2master : bus_slv2mst_type := BUS_SLV2MST_IDLE;
    signal master2demux : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal helper_master : bus_mst2slv_type := BUS_MST2SLV_IDLE;

begin

    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Complete run") then
                master2demux <= bus_tb_mst2slv(address => 10, readEnable => '1');
                wait for clk_period/4;
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2firstSlave = master2demux);
                firstSlave2demux.ack <= '1';
                firstSlave2demux.readData <= std_logic_vector(to_unsigned(34, bus_data_type'length));
                wait for clk_period/4;
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2firstSlave = master2demux);
                check(demux2master = firstSlave2demux);

                master2demux <= BUS_MST2SLV_IDLE;
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2master = BUS_SLV2MST_IDLE);

                firstSlave2demux <= BUS_SLV2MST_IDLE;
                master2demux <= bus_tb_mst2slv(address => 40, writeEnable => '1');
                helper_master <= bus_tb_mst2slv(address => 8, writeEnable => '1');
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = helper_master);
                check(demux2master = BUS_SLV2MST_IDLE);

                secondSlave2demux.fault <= '1';
                secondSlave2demux.readData <= std_logic_vector(to_unsigned(14, bus_data_type'length));
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = helper_master);
                check(demux2master = secondSlave2demux);

                master2demux <= BUS_MST2SLV_IDLE;
                helper_master <= BUS_MST2SLV_IDLE;
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2master = BUS_SLV2MST_IDLE);

                secondSlave2demux <= BUS_SLV2MST_IDLE;
                master2demux <= bus_tb_mst2slv(address => 50, readEnable => '1');
                helper_master <= bus_tb_mst2slv(address => 18, readEnable => '1');
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = helper_master);
                check(demux2master = BUS_SLV2MST_IDLE);

                secondSlave2demux.ack <= '1';
                secondSlave2demux.readData <= std_logic_vector(to_unsigned(45, bus_data_type'length));
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = helper_master);
                check(demux2master = secondSlave2demux);

                master2demux <= BUS_MST2SLV_IDLE;
                helper_master <= BUS_MST2SLV_IDLE;
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2master = BUS_SLV2MST_IDLE);

                master2demux <= bus_tb_mst2slv(address => 20, readEnable => '1');
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2master.fault = '1');
                check(demux2master.readData = std_logic_vector(to_unsigned(255, bus_address_type'length)));

                rst <= '1';
                wait for clk_period/4;
                check(demux2firstSlave = BUS_MST2SLV_IDLE);
                check(demux2secondSlave = BUS_MST2SLV_IDLE);
                check(demux2master = BUS_SLV2MST_IDLE);

            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    demux : entity src.bus_demux
    generic map (
        ADDRESS_MAP(0) => firstRange,
        ADDRESS_MAP(1) => secondRange
    )
    port map (
        rst => rst,
        mst2demux => master2demux,
        demux2mst => demux2master,
        demux2slv(0) => demux2firstSlave,
        demux2slv(1) => demux2secondSlave,
        slv2demux(0) => firstSlave2demux,
        slv2demux(1) => secondSlave2demux
    );
end architecture;
