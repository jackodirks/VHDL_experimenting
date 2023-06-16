library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library tb;

library src;
use src.bus_pkg.all;
use src.uart_bus_master_pkg;

entity main_file_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of main_file_tb is
    constant clk_period : time := 20 ns;
    constant baud_rate : positive := 2000000;
    constant uart_slave_bfm : uart_slave_t := new_uart_slave(initial_baud_rate => baud_rate);
    constant uart_slave_stream : stream_slave_t := as_stream(uart_slave_bfm);

    constant uart_master_bfm : uart_master_t := new_uart_master(initial_baud_rate => baud_rate);
    constant uart_master_stream : stream_master_t := as_stream(uart_master_bfm);
    signal clk : std_logic := '0';
    signal rx : std_logic;
    signal tx : std_logic;
    -- SPI mem
    signal cs_n : std_logic_vector(2 downto 0);
    signal so_sio1 : std_logic;
    signal sio2 : std_logic;
    signal hold_n_sio3 : std_logic;
    signal sck : std_logic;
    signal si_sio0 : std_logic;

    signal rst : std_logic := '0';

    procedure write(
        signal net : inout network_t;
        constant addr : in bus_address_type;
        constant data : in bus_data_type) is
    begin
        push_stream(net, uart_master_stream, uart_bus_master_pkg.COMMAND_WRITE_WORD);
        check_stream(net, uart_slave_stream, uart_bus_master_pkg.ERROR_NO_ERROR);
        for i in 0 to bus_bytes_per_word - 1 loop
            push_stream(net, uart_master_stream, addr(i*8 + 7 downto i*8));
        end loop;
        for i in 0 to bus_bytes_per_word - 1 loop
            push_stream(net, uart_master_stream, data(i*8 + 7 downto i*8));
        end loop;
        check_stream(net, uart_slave_stream, uart_bus_master_pkg.ERROR_NO_ERROR);
    end procedure;

    procedure read(
        signal net : inout network_t;
        constant addr : in bus_address_type;
        constant data : in bus_data_type) is
    begin
        push_stream(net, uart_master_stream, uart_bus_master_pkg.COMMAND_READ_WORD);
        check_stream(net, uart_slave_stream, uart_bus_master_pkg.ERROR_NO_ERROR);
        for i in 0 to bus_bytes_per_word - 1 loop
            push_stream(net, uart_master_stream, addr(i*8 + 7 downto i*8));
        end loop;
        check_stream(net, uart_slave_stream, uart_bus_master_pkg.ERROR_NO_ERROR);
        for i in 0 to bus_bytes_per_word - 1 loop
            check_stream(net, uart_slave_stream, data(i*8 + 7 downto i*8));
        end loop;
    end procedure;

    procedure write_file(
            signal net : inout network_t;
            constant addr : in bus_address_type;
            constant fileName : in string) is
        file read_file : text;
        variable line_v : line;
        variable data : bus_data_type;
        variable address : natural;
        variable busAddress : bus_address_type;
    begin
        address := to_integer(unsigned(addr));
        file_open(read_file, fileName, read_mode);
        while not endfile(read_file) loop
            readline(read_file, line_v);
            hread(line_v, data);
            busAddress := std_logic_vector(to_unsigned(address, busAddress'length));
            write(net, busAddress, data);
            address := address + 4;
        end loop;
        file_close(read_file);
    end;
begin
    clk <= not clk after (clk_period/2);
    process
        constant processor_controller_start_address : bus_address_type := std_logic_vector(to_unsigned(16#2000#, bus_address_type'length));

        constant spimem0_start_address : bus_address_type := std_logic_vector(to_unsigned(16#100000#, bus_address_type'length));
        constant spimem1_start_address : bus_address_type := std_logic_vector(to_unsigned(16#120000#, bus_address_type'length));
        constant spimem2_start_address : bus_address_type := std_logic_vector(to_unsigned(16#140000#, bus_address_type'length));

        variable address : bus_address_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Spi mem is usable") then
                write(net, spimem0_start_address, X"01020304");
                read(net, spimem0_start_address, X"01020304");
            elsif run("processor: Looped add") then
                write_file(net, spimem0_start_address, "./mips32_processor/test/programs/loopedAdd.txt");
                write(net, processor_controller_start_address, X"00000000");
                wait for 1000*clk_period;
                address := std_logic_vector(to_unsigned(to_integer(unsigned(spimem0_start_address)) + 16#24#, address'length));
                read(net, address, X"00000003");
            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 20 ms);

    mem_pcb : entity tb.triple_M23LC1024
    port map (
        cs_n => cs_n,
        so_sio1 => so_sio1,
        sio2 => sio2,
        hold_n_sio3 => hold_n_sio3,
        sck => sck,
        si_sio0 => si_sio0
    );

    main_file : entity src.main_file
    generic map (
        clk_period => clk_period,
        baud_rate => baud_rate
    ) port map (
        JA_gpio(0) => si_sio0,
        JA_gpio(1) => so_sio1,
        JA_gpio(2) => sio2,
        JA_gpio(3) => hold_n_sio3,
        JB_gpio(3 downto 1) => cs_n,
        JB_gpio(0) => sck,
        clk => clk,
        global_reset => rst,
        master_rx => rx,
        master_tx => tx
    );

    uart_slave : entity vunit_lib.uart_slave
    generic map (
      uart => uart_slave_bfm)
    port map (
      rx => tx);

    uart_master : entity vunit_lib.uart_master
    generic map (
      uart => uart_master_bfm)
    port map (
      tx => rx);
end architecture;
