library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
library tb;
use tb.M23LC1024_pkg.all;
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
    signal burst : std_logic := '0';

    signal cs_set : std_logic;
    signal cs_state : std_logic;

    procedure write_bus_word(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant start_address : in std_logic_vector(16 downto 0);
              constant data : in bus_data_type) is
        variable cur_address : std_logic_vector(16 downto 0) := start_address;
        variable data_shifter : bus_data_type := data;
    begin
        for i in 0 to 2**(bus_data_width_log2b - 3) - 1 loop
            info("cur_address " & to_hstring(cur_address));
            write_to_address(net, actor, cur_address, data_shifter(7 downto 0));
            cur_address := std_logic_vector(to_unsigned(to_integer(unsigned(cur_address)) + 1, cur_address'length));
            data_shifter := std_logic_vector(shift_right(unsigned(data_shifter), 8));
        end loop;
    end;

    procedure read_bus_word(
            signal net : inout network_t;
            constant actor : in actor_t;
            constant start_address : in std_logic_vector(16 downto 0);
            variable data : out bus_data_type) is
        variable cur_address : std_logic_vector(16 downto 0) := start_address;
    begin
        for i in 0 to 2**(bus_data_width_log2b - 3) - 1 loop
            info("cur_address " & to_hstring(cur_address));
            read_from_address(net, actor, cur_address, data((i*8) + 7 downto (i*8)));
            cur_address := std_logic_vector(to_unsigned(to_integer(unsigned(cur_address)) + 1, cur_address'length));
        end loop;
    end;

    procedure set_all_mode(constant expOp : in OperationMode;
                           constant expIo : in InoutMode;
                           constant actor : in actor_t;
                           signal net : inout network_t) is
    begin
        write_operationMode(net, actor, expOp);
        write_inoutMode(net, actor, expIo);
    end procedure;

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
                address <= (others => 'Z');
                write_data <= (others => 'Z');
                check(active);
                wait until rising_edge(clk);
                check_equal('0', valid);
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
                address <= (others => 'Z');
                write_data <= (others => 'Z');
                check(active);
                wait until not active;
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
                check(active);
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'Z');
                write_data <= (others => 'Z');
                check(active);
                wait until rising_edge(clk);
                check_equal('0', valid);
                wait until not active;
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
                check(active);
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'Z');
                write_data <= (others => 'Z');
                check(active);
                wait until rising_edge(clk);
                check_equal('0', valid);
                wait until not active;
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
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
                address <= (others => 'Z');
                write_data <= (others => 'Z');
                -- Note that the following action is strictly speaking illegal,
                -- since a master is not allowed to wait for a valid
                wait until rising_edge(clk) and valid = '1';
                check(active);
                wait for 4*clk_period;
                burst <= '0';
                ready <= '1';
                check(active);
                address <= std_logic_vector(to_unsigned(4, address'length));
                write_data <= std_logic_vector(to_unsigned(255, address'length));
                wait until rising_edge(clk) and valid = '1';
                ready <= '0';
                address <= (others => 'Z');
                write_data <= (others => 'Z');
                check(active);
                wait until not active;
                read_bus_word(net, actor, std_logic_vector(to_unsigned(0, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
                read_bus_word(net, actor, std_logic_vector(to_unsigned(4, 17)), read_data);
                check_equal(read_data, std_logic_vector(to_unsigned(255, address'length)));
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
        address => address,
        write_data => write_data,
        burst => burst
    );
end tb;
