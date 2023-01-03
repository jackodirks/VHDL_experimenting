library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
library tb;
use tb.M23LC1024_pkg.all;
use tb.triple_23lc1024_tb_pkg.all;
use src.bus_pkg.all;

entity triple_23LC1024_reader_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of triple_23LC1024_reader_tb is
    constant spi_clk_half_period_ticks : natural := 2;
    constant clk_period : time := 20 ns;
    constant cs_wait_time : time := 50 ns;
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal cs_n : std_logic_vector(2 downto 0) := (others => '1');
    signal so_sio1 : std_logic;
    signal sio2 : std_logic;
    signal hold_n_sio3 : std_logic;
    signal sck : std_logic;
    signal si_sio0 : std_logic;

    signal active : boolean;
    signal ready :  std_logic := '0';
    signal valid : std_logic;
    signal address : bus_address_type := (others => '0');
    signal read_data : bus_data_type := (others => '0');
    signal burst : std_logic := '0';
    signal fault : std_logic;
    signal faultData : std_logic_vector(bus_fault_type'range);

    signal cs_set : std_logic;
    signal cs_state : std_logic;

    signal spi_sio_in : std_logic_vector(3 downto 0);
    signal spi_sio_out : std_logic_vector(3 downto 0);

    signal reading : boolean;

begin
    clk <= not clk after (clk_period/2);

    spi_sio_in <= hold_n_sio3 & sio2 & so_sio1 & si_sio0;
    process(reading, spi_sio_out)
    begin
        if not reading then
            si_sio0 <= spi_sio_out(0);
            so_sio1 <= spi_sio_out(1);
            sio2 <= spi_sio_out(2);
            hold_n_sio3 <= spi_sio_out(3);
        else
            si_sio0 <= 'Z';
            so_sio1 <= 'Z';
            sio2 <= 'Z';
            hold_n_sio3 <= 'Z';
        end if;
    end process;

    process
        constant actor : actor_t := find("M23LC1024.mem0");
        variable exp_data : bus_data_type := (others => '0');
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Bus data width should be a multiple of 8") then
                -- We send our data packages in multiples of 8 bit, therefore the bus width
                -- has to be at least 8 bit.
                check(bus_data_width_log2b >= 3);
            elsif run("Read from address zero which contains 255 results in 255") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(255, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '0';
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                check_equal(read_data, std_logic_vector(to_unsigned(255, bus_data_type'length)));
                check(active);
                wait until rising_edge(clk);
                check_equal('0', valid);
                wait until not active;
            elsif run("Read from address zero which contains 0xFFFEFDFC results in 0xFFFEFDFC") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                exp_data := X"FFFEFDFC";
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), exp_data);
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '0';
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                check_equal(read_data, exp_data);
                check(active);
                wait until rising_edge(clk);
                check_equal('0', valid);
                wait until not active;
            elsif run("Read from address zero which contains 254 and address 4 which contains 14 results in 254, 14") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(254, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(14, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '0';
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(254, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(4, address'length));
                ready <= '1';
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(14, bus_data_type'length)));
                ready <= '0';
                address <= (others => 'X');
                check(active);
                wait until not active;
            elsif run("Burst read from address zero which contains 254 and address 4 which contains 14 results in 254, 14") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(254, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(14, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(254, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(4, address'length));
                burst <= '0';
                ready <= '1';
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(14, bus_data_type'length)));
                ready <= '0';
                address <= (others => 'X');
                check(active);
                wait until not active;
            elsif run("Paused burst read from address zero which contains 254 and address 4 which contains 14 results in 254, 14") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(254, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(14, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(254, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(4, address'length));
                burst <= '0';
                ready <= '0';
                wait for 2 us;
                wait until falling_edge(clk);
                ready <= '1';
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(14, bus_data_type'length)));
                ready <= '0';
                address <= (others => 'X');
                check(active);
                wait until not active;
            elsif run("Unaligned address error is detected") then
                address <= std_logic_vector(to_unsigned(1, address'length));
                rst <= '0';
                ready <= '1';
                wait until rising_edge(clk) and fault = '1';
                check_equal(faultData, bus_fault_unaligned_access);
            elsif run("Illegal burst error is detected") then
                address <= (others => '0');
                address(16 downto 0) <= std_logic_vector(to_unsigned(16#1fffc#, 17));
                burst <= '1';
                ready <= '1';
                rst <= '0';
                wait until rising_edge(clk) and fault = '1';
                check_equal(faultData, bus_fault_illegal_address_for_burst);
            elsif run("Reader moves on after error") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(254, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(14, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(1, address'length));
                rst <= '0';
                ready <= '1';
                wait until rising_edge(clk) and fault = '1';
                address <= std_logic_vector(to_unsigned(4, address'length));
                wait until rising_edge(clk) and valid = '1';
                check_equal(read_data, std_logic_vector(to_unsigned(14, bus_data_type'length)));
            elsif run("Errors end burst") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(254, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(14, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                wait until rising_edge(clk) and valid = '1';
                address <= std_logic_vector(to_unsigned(1, address'length));
                wait until rising_edge(clk) and fault = '1';
                check_equal(faultData, bus_fault_unaligned_access);
                wait until rising_edge(cs_n(0));
            elsif run("Active remains asserted until CS = 1") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                address <= std_logic_vector(to_unsigned(0, address'length));
                rst <= '0';
                ready <= '1';
                wait until rising_edge(clk) and valid = '1';
                wait until rising_edge(clk);
                check_equal(active, true);
                ready <= '0';
                wait until not active or rising_edge(cs_n(0));
                if cs_n(0) = '0' then
                    check_equal(active, true);
                end if;
                wait until not active;
            end if;
        end loop;
        wait for 2*clk_period;
        test_runner_cleanup(runner);
        wait;
    end process;

    process (cs_set)
    begin
        if cs_set = '0' then
            cs_n(0) <= cs_set;
            cs_state <= cs_set after cs_wait_time;
        else
            cs_n(0) <= cs_set after cs_wait_time;
            cs_state <= cs_set after cs_wait_time;
        end if;
    end process;

    test_runner_watchdog(runner,  100 us);

    mem_pcb : entity tb.triple_M23LC1024
    port map (
        cs_n => cs_n,
        so_sio1 => so_sio1,
        sio2 => sio2,
        hold_n_sio3 => hold_n_sio3,
        sck => sck,
        si_sio0 => si_sio0
    );

    reader : entity src.triple_23lc1024_reader
    generic map (
        spi_clk_half_period_ticks => spi_clk_half_period_ticks
    )
    port map (
        clk => clk,
        rst => rst,
        spi_clk => sck,
        spi_sio_in => spi_sio_in,
        spi_sio_out => spi_sio_out,
        cs_set => cs_set,
        cs_state => cs_state,
        ready => ready,
        valid => valid,
        active => active,
        fault => fault,
        reading => reading,
        address => address,
        read_data => read_data,
        burst => burst,
        faultData => faultData
    );
end tb;
