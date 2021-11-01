library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library bus_lib;
use bus_lib.bus_pkg.all;

entity bus_singleport_ram_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of bus_singleport_ram_tb is

    type mem_type is record
        rst : std_logic;
        mst2slv : bus_mst2slv_type;
        slv2mst : bus_slv2mst_type;
        done : boolean;
        success : boolean;
    end record;

    constant MEM_TYPE_DEFAULT : mem_type := (
        rst => '0',
        mst2slv => BUS_MST2SLV_IDLE,
        slv2mst => BUS_SLV2MST_IDLE,
        done => false,
        success => false
    );
    constant clk_period : time := 20 ns;

    signal mem_256_byte_control : mem_type := MEM_TYPE_DEFAULT;
    signal mem_2_byte_control : mem_type := MEM_TYPE_DEFAULT;

    signal clk : std_logic := '0';
begin

    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_ack_low_at_start") then
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '0');
            elsif run ("test_write_then_read") then
                wait for clk_period;
                mem_256_byte_control.mst2slv.address <= std_logic_vector(to_unsigned(25, 8));
                mem_256_byte_control.mst2slv.writeData <= std_logic_vector(to_unsigned(14, 8));
                mem_256_byte_control.mst2slv.writeEnable <= '1';
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '1');
                mem_256_byte_control.mst2slv.writeEnable <= '0';
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '0');
                mem_256_byte_control.mst2slv.address <= std_logic_vector(to_unsigned(35, 8));
                mem_256_byte_control.mst2slv.writeData <= std_logic_vector(to_unsigned(15, 8));
                mem_256_byte_control.mst2slv.writeEnable <= '1';
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '1');
                mem_256_byte_control.mst2slv.writeEnable <= '0';
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '0');
                mem_256_byte_control.mst2slv.address <= std_logic_vector(to_unsigned(25, 8));
                mem_256_byte_control.mst2slv.readEnable <= '1';
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '1');
                check_equal(14, to_integer(unsigned(mem_256_byte_control.slv2mst.readData)));
                mem_256_byte_control.mst2slv.readEnable <= '0';
                wait for clk_period;
                check_equal(mem_256_byte_control.slv2mst.ack, '0');
            elsif run("Test 2 byte memory") then
                mem_2_byte_control.mst2slv.address <= std_logic_vector(to_unsigned(1, 8));
                mem_2_byte_control.mst2slv.writeData <= std_logic_vector(to_unsigned(14, 8));
                mem_2_byte_control.mst2slv.writeEnable <= '1';
                wait for clk_period;
                check_equal(mem_2_byte_control.slv2mst.ack, '1');
                mem_2_byte_control.mst2slv.writeEnable <= '0';
                wait for clk_period;
                check_equal(mem_2_byte_control.slv2mst.ack, '0');
                mem_2_byte_control.mst2slv.address <= std_logic_vector(to_unsigned(3, 8));
                mem_2_byte_control.mst2slv.readEnable <= '1';
                wait for clk_period;
                check_equal(mem_2_byte_control.slv2mst.ack, '1');
                check_equal(14, to_integer(unsigned(mem_2_byte_control.slv2mst.readData)));
                mem_2_byte_control.mst2slv.readEnable <= '0';
                wait for clk_period;
                check_equal(mem_2_byte_control.slv2mst.ack, '0');
            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 10 ms);

    mem_256_byte : entity bus_lib.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 8
    )
    port map (
        rst => mem_256_byte_control.rst,
        clk => clk,
        mst2mem => mem_256_byte_control.mst2slv,
        mem2mst => mem_256_byte_control.slv2mst
    );

    mem_2_byte : entity bus_lib.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 1
    )
    port map (
        rst => mem_2_byte_control.rst,
        clk => clk,
        mst2mem => mem_2_byte_control.mst2slv,
        mem2mst => mem_2_byte_control.slv2mst
    );
end architecture;
