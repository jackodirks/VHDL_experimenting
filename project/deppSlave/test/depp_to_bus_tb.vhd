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
use tb.bus_tb_pkg.all;
use tb.depp_tb_pkg.all;

entity depp_to_bus_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of depp_to_bus_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal slv2mst : bus_slv2mst_type := BUS_SLV2MST_IDLE;
    signal mst2slv : bus_mst2slv_type;

    signal depp2bus : depp2bus_type := DEPP2BUS_IDLE;
    signal bus2depp : bus2depp_type;
begin


    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Sanity test") then
                rst <= '1';
                wait for clk_period;
                check(mst2slv = BUS_MST2SLV_IDLE);
                check(bus2depp = BUS2DEPP_IDLE);
                rst <= '0';
                wait for clk_period;
                check(mst2slv = BUS_MST2SLV_IDLE);
                check(bus2depp = BUS2DEPP_IDLE);
            end if;
            if run("Simple write to depp_to_bus") then
                wait for clk_period;
                depp2bus <= depp_tb_depp2bus(writeEnable => true);
                wait for clk_period;
                check(bus2depp.done = true);
                depp2bus <= DEPP2BUS_IDLE;
                wait for clk_period;
                check(bus2depp.done = false);
            end if;
            if run("Write from depp_to_bus") then
                wait for clk_period;
                depp2bus <= depp_tb_depp2bus(address => 3, writeEnable => true);
                wait for clk_period;
                check(bus2depp.done = false);
                check(bus_tb_mst2slv(writeEnable => '1') = mst2slv);
                wait for clk_period;
                check(bus2depp.done = false);
                check(bus_tb_mst2slv(writeEnable => '1') = mst2slv);
                slv2mst.ack <= '1';
                wait for clk_period;
                check(bus2depp.done = true);
                check(BUS_MST2SLV_IDLE = mst2slv);
                slv2mst <= BUS_SLV2MST_IDLE;
                depp2bus <= DEPP2BUS_IDLE;
                wait for clk_period;
                check(bus2depp.done = false);
            end if;
            if run("Extended write from depp_to_bus") then
                wait for clk_period;
                depp2bus <= depp_tb_depp2bus(address => 0, writeData => 1, writeEnable => true);
                wait for clk_period;
                check(bus2depp.done = true);
                depp2bus.writeEnable <= false;
                wait for clk_period;
                check(bus2depp.done = false);
                depp2bus <= depp_tb_depp2bus(address => 1, writeData => 2, writeEnable => true);
                wait for clk_period;
                check(bus2depp.done = true);
                depp2bus.writeEnable <= false;
                wait for clk_period;
                check(bus2depp.done = false);
                depp2bus <= depp_tb_depp2bus(address => 2, writeData => 1, writeEnable => true);
                wait for clk_period;
                check(bus2depp.done = true);
                depp2bus.writeEnable <= false;
                wait for clk_period;
                check(bus2depp.done = false);
                depp2bus <= depp_tb_depp2bus(address => 3, writeEnable => true);
                wait for clk_period;
                check(bus2depp.done = false);
                check(bus_tb_mst2slv(address => 1, writeData => 2, writeMask => 1, writeEnable => '1') = mst2slv);
                slv2mst.fault <= '1';
                slv2mst.readData <= (others => '1');
                wait for clk_period;
                check(bus2depp.done = true);
                check(bus_requesting(mst2slv) = '0');
                depp2bus.writeEnable <= false;
                wait for clk_period;
                check(bus2depp.done = false);
                depp2bus <= depp_tb_depp2bus(address => 0, readEnable => true);
                slv2mst <= BUS_SLV2MST_IDLE;
                wait for clk_period;
                check(bus2depp.done = true);
                check(bus2depp.readData(0) = '1');
                depp2bus.readEnable <= false;
                wait for clk_period;
                check(bus2depp.done = false);
                depp2bus <= depp_tb_depp2bus(address => 1, readEnable => true);
                wait for clk_period;
                check(bus2depp.done = true);
                check(to_integer(unsigned(bus2depp.readData)) = 255);
                depp2bus <= depp_tb_depp2bus(address => 2, readEnable => true);
                wait for clk_period;
                check(bus2depp.done = true);
                check(bus2depp.readData(0) = '1');
                depp2bus <= DEPP2BUS_IDLE;
                wait for clk_period;
                check(bus2depp.done = false);
            end if;


        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    depp_to_bus : entity src.depp_to_bus
    port map (
        rst => rst,
        clk => clk,
        depp2bus => depp2bus,
        bus2depp => bus2depp,
        mst2slv => mst2slv,
        slv2mst => slv2mst
    );

end tb;
