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

entity triple_23LC1024_writer_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of triple_23LC1024_writer_tb is
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
    signal write_data : bus_data_type := (others => '0');
    signal writeMask : bus_write_mask := (others => '1');
    signal burst : std_logic := '0';
    signal fault : std_logic;
    signal faultData : std_logic_vector(bus_fault_type'range);

    signal cs_set : std_logic;
    signal cs_state : std_logic;

    signal cs_allowed_all_high : boolean := true;

begin
    clk <= not clk after (clk_period/2);

    process
        constant actor : actor_t := find("M23LC1024.mem0");
        variable read_data : bus_data_type;
        variable exp_data : bus_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Bus data width should be a multiple of 8") then
                -- We send our data packages in multiples of 8 bit, therefore the bus width
                -- has to be at least 8 bit.
                check(bus_data_width_log2b >= 3);
            elsif run("Write 255 to address zero results in 255 at address zero") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '0';
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                write_data <= (others => 'X');
                check_equal(fault, '0');
                wait until rising_edge(clk);
                check_equal('0', valid);
                check(active);
                wait until not active;
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
            elsif run("Write 0xFFFEFDFC to address zero results in 0xFFFEFDFC at address zero") then
                exp_data := X"FFFEFDFC";
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), (others => '0'));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= exp_data;
                rst <= '0';
                ready <= '1';
                burst <= '0';
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                write_data <= (others => 'X');
                wait until rising_edge(cs_n(0));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, exp_data);
            elsif run("Write 255 to address zero and address 4 results in 255 at address zero and address 4") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '0';
                check(not active);
                wait until rising_edge(clk) and valid = '1';
                ready <= '1';
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                write_data <= (others => 'X');
                wait until rising_edge(cs_n(0));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
            elsif run("Burst write 255 to address zero and address 4 results in 255 at address zero and address 4") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                check(not active);
                wait until rising_edge(clk) and valid = '1';
                burst <= '0';
                ready <= '1';
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                write_data <= (others => 'X');
                wait until rising_edge(cs_n(0));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
            elsif run("Burst of size 50 works as intended") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                rst <= '0';
                for i in 0 to 49 loop
                    write_bus_word(net, actor, std_logic_vector(to_unsigned(i*4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                end loop;
                for i in 0 to 49 loop
                    address <= std_logic_vector(to_unsigned(i*4, address'length));
                    write_data <= std_logic_vector(to_unsigned(i*17, write_data'length));
                    ready <= '1';
                    if i = 49 then
                        burst <= '0';
                    else
                        burst <= '1';
                    end if;
                    if i = 0 then
                        wait until falling_edge(cs_n(0));
                        cs_allowed_all_high <= false;
                    end if;
                    wait until rising_edge(clk) and valid = '1';
                    check_equal(fault, '0');
                end loop;
                ready <= '0';
                cs_allowed_all_high <= true;
                wait until rising_edge(cs_n(0));
                for i in 0 to 49 loop
                    read_bus_word(net, actor, std_logic_vector(to_unsigned(i*4, 17)), read_data);
                    check_equal(read_data, std_logic_vector(to_unsigned(i*17, address'length)));
                end loop;
            elsif run("Paused burst write 255 to address zero and address 4 results in 255 at address zero and address 4") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                check(not active);
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                write_data <= (others => 'X');
                burst <= '0';
                wait for 2 us;
                wait until falling_edge(clk);
                ready <= '1';
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'X');
                write_data <= (others => 'X');
                check(active);
                wait until not active;
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
            elsif run("Illegal write mask error is detected") then
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                writeMask <= X"7";
                wait until rising_edge(clk) and fault = '1';
                check_equal(faultData, bus_fault_illegal_write_mask);
            elsif run("Unaligned address error is detected") then
                address <= std_logic_vector(to_unsigned(1, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
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
            elsif run("Faulty request is fully ignored") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                writeMask <= X"7";
                wait until rising_edge(clk) and fault = '1';
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                writeMask <= X"F";
                wait until rising_edge(clk) and (valid = '1' or fault = '1');
                check_equal('0', fault);
                wait until rising_edge(cs_n(0));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(0, read_data'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, read_data'length)));
            elsif run("Faulty request during burst is fully ignored, while valid writes are fully respected") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(8, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                wait until rising_edge(clk) and (valid = '1' or fault = '1');
                check_equal('0', fault);
                address <= std_logic_vector(to_unsigned(4, address'length));
                writeMask <= X"7";
                wait until rising_edge(clk) and (valid = '1' or fault = '1');
                check_equal('1', fault);
                address <= std_logic_vector(to_unsigned(8, address'length));
                writeMask <= X"F";
                burst <= '0';
                wait until rising_edge(clk) and (valid = '1' or fault = '1');
                check_equal('0', fault);
                wait until rising_edge(cs_n(0));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, read_data'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(0, read_data'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(8, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, read_data'length)));
            elsif run("A fault ends a burst") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                write_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                write_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), std_logic_vector(to_unsigned(0, bus_data_type'length)));
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '1';
                wait until rising_edge(clk) and (valid = '1' or fault = '1');
                check_equal('0', fault);
                address <= std_logic_vector(to_unsigned(4, address'length));
                writeMask <= X"7";
                wait until rising_edge(clk) and (valid = '1' or fault = '1');
                check_equal('1', fault);
                ready <= '0';
                burst <= '0';
                wait until rising_edge(cs_n(0));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, read_data'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(0, read_data'length)));
            elsif run("Active remains asserted until CS = 1") then
                set_all_mode(SeqMode, SqiMode, actor, net);
                address <= std_logic_vector(to_unsigned(0, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                rst <= '0';
                ready <= '1';
                burst <= '0';
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

    process(cs_n, cs_allowed_all_high)
    begin
        if not cs_allowed_all_high then
            check(cs_n /= "111");
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

    writer : entity src.triple_23lc1024_writer
    generic map (
        spi_clk_half_period_ticks => spi_clk_half_period_ticks
    )
    port map (
        clk => clk,
        rst => rst,
        spi_clk => sck,
        spi_sio(0) => si_sio0,
        spi_sio(1) => so_sio1,
        spi_sio(2) => sio2,
        spi_sio(3) => hold_n_sio3,
        cs_set => cs_set,
        cs_state => cs_state,
        ready => ready,
        valid => valid,
        active => active,
        fault => fault,
        address => address,
        write_data => write_data,
        writeMask => writeMask,
        burst => burst,
        faultData => faultData
    );
end tb;
