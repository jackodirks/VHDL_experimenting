library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use std.textio.ALL;
use IEEE.MATH_REAL.ALL;


entity tb_main is
    generic ( SEED : natural);
end tb_main;

architecture tb of tb_main is

    -- Component declaration --
    component seven_segments_tb is
        generic (
            clock_period : time
        );
        port (
            clk         : in STD_LOGIC;
            done        : out boolean;
            success     : out boolean
        );
    end component;

    component common_tb is
        generic (
            clock_period : time
        );
        port (
            clk : in STD_LOGIC;
            done : out boolean;
            success : out boolean
        );
    end component;

    component uart_receiv is
        generic (
            baudrate                : Natural;
            clockspeed              : Natural;
            parity_bit_in           : boolean;
            parity_bit_in_type      : Natural range 0 to 3;
            bit_count_in            : Natural range 5 to 9;
            stop_bits_in            : Natural range 1 to 2
        );
        port (
            rst                     : in    STD_LOGIC;
            clk                     : in    STD_LOGIC;
            uart_rx                 : in    STD_LOGIC;
            received_data           : out   STD_LOGIC_VECTOR(8 DOWNTO 0);
            data_ready              : out   STD_LOGIC;                    -- Signals that data has been received.
            parity_error            : out   STD_LOGIC;                    -- Signals that the parity check has failed, is zero if there was none
            data_error              : out   STD_LOGIC                     -- Signals that data receiving has encoutered errors
        );
    end component;

    component uart_transmit is
        generic (
            baudrate                : Natural;
            clockspeed              : Natural;
            parity_bit_en           : boolean;
            parity_bit_type         : Natural range 0 to 3;
            bit_count               : Natural range 5 to 9;
            stop_bits               : Natural range 1 to 2
        );
        port (
            rst                     : in    STD_LOGIC;
            clk                     : in    STD_LOGIC;
            uart_tx                 : out   STD_LOGIC;
            data_in                 : in    STD_LOGIC_VECTOR(8 DOWNTO 0);
            data_send_start         : in    STD_LOGIC;                    -- Signals that the data can now be send
            ready                   : out   STD_LOGIC
        );
    end component;

    component uart_main is
        generic (
            clockspeed              : Natural;
            baudrate                : Natural;
            parity_bit_en           : boolean;
            parity_bit_type         : integer range 0 to 3;
            bit_count               : integer range 5 to 9;
            stop_bits_count         : integer range 1 to 2
        );
        Port (
            rst                     : in STD_LOGIC;
            clk                     : in STD_LOGIC;
            uart_rx                 : in STD_LOGIC;
            uart_tx                 : out STD_LOGIC;
            send_start              : in STD_LOGIC;
            data_in                 : in STD_LOGIC_VECTOR(8 DOWNTO 0);
            data_out                : out STD_LOGIC_VECTOR(8 DOWNTO 0);
            data_ready              : out STD_LOGIC;
            data_error              : out STD_LOGIC;
            parity_error            : out STD_LOGIC;
            send_ready              : out STD_LOGIC
        );
    end component;

    -- Constant declaration --
    constant clock_period                   : time := 20 ns;    -- Please make sure this number is divisible by 2.
    constant test_count                     : natural := 5;

    -- Signal declaration --
    signal clk                              : STD_LOGIC := '0';

    signal uart_receiv_1_rst                : STD_LOGIC := '1';
    signal uart_receiv_1_rx                 : STD_LOGIC := '1';
    signal uart_receiv_1                    : STD_LOGIC_VECTOR(8 DOWNTO 0);
    signal uart_receiv_1_ready              : STD_LOGIC;
    signal uart_receiv_1_par_err            : STD_LOGIC;
    signal uart_receiv_1_dat_err            : STD_LOGIC;

    signal uart_receiv_2_rst                : STD_LOGIC := '1';
    signal uart_receiv_2_rx                 : STD_LOGIC := '1';
    signal uart_receiv_2                    : STD_LOGIC_VECTOR(8 DOWNTO 0);
    signal uart_receiv_2_ready              : STD_LOGIC;
    signal uart_receiv_2_par_err            : STD_LOGIC;
    signal uart_receiv_2_dat_err            : STD_LOGIC;

    signal uart_send_1_rst                  : STD_LOGIC := '1';
    signal uart_send_1_in                   : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
    signal uart_send_1_start                : STD_LOGIC := '0';
    signal uart_send_1_tx                   : STD_LOGIC;
    signal uart_send_1_ready                : STD_LOGIC;

    signal uart_send_2_rst                  : STD_LOGIC := '1';
    signal uart_send_2_in                   : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
    signal uart_send_2_start                : STD_LOGIC := '0';
    signal uart_send_2_tx                   : STD_LOGIC;
    signal uart_send_2_ready                : STD_LOGIC;

    signal uart_main_rst                    : STD_LOGIC := '1';
    signal uart_main_rx                     : STD_LOGIC := '1';
    signal uart_main_tx                     : STD_LOGIC;
    signal uart_main_send_start             : STD_LOGIC := '0';
    signal uart_main_data_in                : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
    signal uart_main_data_out               : STD_LOGIC_VECTOR(8 DOWNTO 0);
    signal uart_main_data_ready             : STD_LOGIC;
    signal uart_main_data_error             : STD_LOGIC;
    signal uart_main_parity_error           : STD_LOGIC;
    signal uart_main_send_ready             : STD_LOGIC;

    signal seven_segments_done              : boolean;
    signal common_done                      : boolean;

    signal seven_segments_success           : boolean;
    signal common_success                   : boolean;

    signal tests                            : STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '0');
    signal randVal                          : natural := 0;
begin

    uart_receiver_1 : uart_receiv
    generic map (
        baudrate => 236400,
        clockspeed => 50000000,
        parity_bit_in => false,
        parity_bit_in_type => 0,
        bit_count_in => 8,
        stop_bits_in => 1
    )
    port map (
        rst => uart_receiv_1_rst,
        clk => clk,
        uart_rx => uart_receiv_1_rx,
        received_data => uart_receiv_1,
        data_ready => uart_receiv_1_ready,
        parity_error => uart_receiv_1_par_err,
        data_error => uart_receiv_1_dat_err
    );

    uart_receiver_2 : uart_receiv
    generic map (
        baudrate => 236400,
        clockspeed => 50000000,
        parity_bit_in => true,
        parity_bit_in_type => 0,
        bit_count_in => 8,
        stop_bits_in => 2
    )
    port map (
        rst => uart_receiv_2_rst,
        clk => clk,
        uart_rx => uart_receiv_2_rx,
        received_data => uart_receiv_2,
        data_ready => uart_receiv_2_ready,
        parity_error => uart_receiv_2_par_err,
        data_error => uart_receiv_2_dat_err
    );

    uart_send_1 : uart_transmit
    generic map (
        baudrate            => 236400,
        clockspeed          => 50000000,
        parity_bit_en       => false,
        parity_bit_type     => 0,
        bit_count           => 8,
        stop_bits           => 1
    )
    port map (
        rst                 => uart_send_1_rst,
        clk                 => clk,
        uart_tx             => uart_send_1_tx,
        data_in             => uart_send_1_in,
        data_send_start     => uart_send_1_start,
        ready               => uart_send_1_ready
    );

    uart_send_2 : uart_transmit
    generic map (
        baudrate            => 236400,
        clockspeed          => 50000000,
        parity_bit_en       => true,
        parity_bit_type     => 1,
        bit_count           => 8,
        stop_bits           => 2
    )
    port map (
        rst                 => uart_send_2_rst,
        clk                 => clk,
        uart_tx             => uart_send_2_tx,
        data_in             => uart_send_2_in,
        data_send_start     => uart_send_2_start,
        ready               => uart_send_2_ready
    );

    uart_total : uart_main
    generic map (
        clockspeed          => 50000000,
        baudrate            => 236400,
        parity_bit_en       => true,
        parity_bit_type     => 3,
        bit_count           => 6,
        stop_bits_count     => 2
    )
    port map (
        rst                 => uart_main_rst,
        clk                 => clk,
        uart_rx             => uart_main_rx,
        uart_tx             => uart_main_tx,
        send_start          => uart_main_send_start,
        data_in             => uart_main_data_in,
        data_out            => uart_main_data_out,
        data_ready          => uart_main_data_ready,
        data_error          => uart_main_data_error,
        parity_error        => uart_main_parity_error,
        send_ready          => uart_main_send_ready
    );

    seven_segments_test: seven_segments_tb
    generic map (
        clock_period => clock_period
    )
    port map (
        clk => clk,
        done => seven_segments_done,
        success => seven_segments_success
    );

    common_test : common_tb
    generic map (
        clock_period => clock_period
    )
    port map (
        clk => clk,
        done => common_done,
        success => common_success
    );

    rand_gen : process
    begin
        wait for 20 ns;
        randVal <= SEED rem 256;
        wait for 20 ns;
        report "Seed is " & integer'image(SEED) severity note;
        report "randVal is " & integer'image(randVal) severity note;
        wait;
    end process;

    clock_gen : process
    begin
        if not (common_done and seven_segments_done and tests(1) = '1' and tests(2) = '1' and tests(3) = '1') then
            -- 1/2 duty cycle
            clk <= not clk;
            wait for clock_period/2;
        else
            wait;
        end if;
    end process;

    uart_main_rx <= uart_main_tx;

    uart_main_tester : process
        variable test_data : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101000";
    begin
        uart_main_rst <= '0';
        wait for 20 ns;
        for D in 0 to 63 loop
            uart_main_data_in(5 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(D, 6));
            uart_main_send_start <= '1';
            wait for 20 ns;
            uart_main_send_start <= '0';
            wait for 42400 ns;
            assert uart_main_data_ready = '1' report "uart_main had not received on D = " & integer'image(D) severity error;
            assert uart_main_send_ready = '1' report "uart main is not ready to send on D = " & integer'image(D) severity error;
            assert uart_main_data_error = '0' report "UART main reports unexpected data error on D = " & integer'image(D) severity error;
            assert uart_main_parity_error = '0' report "UART main reports unexpected parity error on D = " & integer'image(D) severity error;
            assert uart_main_data_out(5 DOWNTO 0) = STD_LOGIC_VECTOR(to_unsigned(D, 6)) report "uart main send/receive error on D = " & integer'image(D) severity error;
        end loop;
        assert false report "Uart main test done" severity note;
        wait;
    end process;

    uart_receiver_one_tester : process
        variable data_buffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
    begin
        uart_receiv_1_rst <= '0';
        wait for 4230 ns;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_receiv_1_rx <= '0';
            for I in 0 TO 7 loop
                wait for 4230 ns;
                uart_receiv_1_rx <= data_buffer(I);
            end loop;
            wait for 4230 ns;
            uart_receiv_1_rx <= '1';
            wait until uart_receiv_1_ready = '1';
            assert uart_receiv_1(7 DOWNTO 0) = data_buffer report "uart_receiv_1 unexpected value" severity error;
            assert uart_receiv_1_dat_err = '0' report "uart_receiv_1_dat_err unexpected value" severity error;
            assert uart_receiv_1_par_err = '0' report "uart_receiv_1_par_err unexpected value" severity error;
            wait for 2115 ns;
        end loop;
        uart_receiv_1_rst <= '1';
        assert false report "UART_receiv_1 test done" severity note;
        tests(1) <= '1';
        wait;
    end process;

    uart_receive_2_tester : process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0);
        variable odd            : STD_LOGIC := '0';
    begin
        uart_receiv_2_rx <= '1';
        uart_receiv_2_rst <= '0';
        wait for 4230 ns;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_receiv_2_rx <= '0';
            for I in 0 to 7 loop
                wait for 4230 ns;
                uart_receiv_2_rx <= data_buffer(I);
                if data_buffer(I) = '1' then
                    odd := not odd;
                end if;
            end loop;
            wait for 4230 ns;
            -- Send the parity bit
            uart_receiv_2_rx <= odd;
            wait for 4230 ns;
            uart_receiv_2_rx <= '1';
            wait for 8460 ns;
            assert uart_receiv_2_ready = '1' report "Uart receiv 2 was not ready while it was expected to be ready" severity error;
            assert uart_receiv_2(7 DOWNTO 0) = data_buffer report "uart_receiv_2 unexpected value" severity error;
            assert uart_receiv_2_dat_err = '0' report "uart_receiv_2_dat_err unexpected value" severity error;
            assert uart_receiv_2_par_err = '0' report "uart_receiv_2_par_err unexpected value" severity error;
            odd := '0';
        end loop;
        uart_receiv_2_rst <= '1';
        -- Test if the parity error happens when expected
        wait for 20 ns;
        uart_receiv_2_rst <= '0';
        -- Test for parity error
        data_buffer := STD_LOGIC_VECTOR(to_unsigned(randVal, data_buffer'length));
        odd         := '0';
        -- Start bit
        uart_receiv_2_rx <= '0';
        -- Send data
        for I in 0 to 7 loop
            wait for 4230 ns;
            uart_receiv_2_rx <= data_buffer(I);
            if data_buffer(I) = '1' then
                odd := not odd;
            end if;
        end loop;
        -- Send the wrong parity bit
        wait for 4230 ns;
        uart_receiv_2_rx <= not odd;
        wait for 4230 ns;
        -- Double stop bit
        uart_receiv_2_rx <= '1';
        wait for 8460 ns;
        assert uart_receiv_2_ready = '1' report "Uart receiv 2 was not ready while it was expected to be ready" severity error;
        assert uart_receiv_2(7 DOWNTO 0) = data_buffer report "uart_receiv_2 unexpected value" severity error;
        assert uart_receiv_2_dat_err = '0' report "uart_receiv_2_dat_err unexpected value" severity error;
        assert uart_receiv_2_par_err = '1' report "uart_receiv_2_par_err unexpected value, expected to fail, but passed, randval was " & integer'image(randVal) severity error;
        uart_receiv_2_rst <= '1';
        assert false report "UART_receiv_2 test done" severity note;
        tests(2) <= '1';
        wait;
    end process;

    uart_send_1_test : process
        variable data_buffer   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    begin
        uart_send_1_rst <= '0';
        wait for 100 ns;
        assert uart_send_1_tx = '1' report "uart_send_1_rx does not default to 1" severity error;
        assert uart_send_1_ready = '1' report "uart_send_1_ready does not default to 1" severity error;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_1_in(7 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_1_start <= '1';
            wait for 2115 ns;
            uart_send_1_start <= '0';
            assert uart_send_1_tx = '0' report "uart_send_1_tx start bit incorrect" severity error;
            assert uart_send_1_ready = '0' report "uart_send_1_ready is one where it should have been zero" severity error;
            for I in 0 to 7 loop
                wait for 4230 ns;
                assert data_buffer(I) = uart_send_1_tx report "UART 1 tx unexpected value" severity error;
            end loop;
            wait for 4230 ns;
            assert uart_send_1_tx = '1' report "uart_send_1_tx stop bit incorrect" severity error;
            assert uart_send_1_ready = '0' report "uart_send_1_ready is one where it should have been zero" severity error;
            wait for 4230 ns;
            assert uart_send_1_tx = '1' report "uart_send_1_tx stop bit incorrect" severity error;
            assert uart_send_1_ready = '1' report "uart_send_1_ready is not one in time" severity error;
        end loop;
        wait for 4230 ns;
        assert false report "data_send_1 tests done" severity note;
        tests(3) <= '1';
        wait;
    end process;

    uart_send_2_test : process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
        variable even           : STD_LOGIC := '1';
    begin
        uart_send_2_rst <= '0';
        wait for 100 ns;
        for D in 0 to 255 loop
            even := '1';
            -- Test the start situation
            assert uart_send_2_tx = '1' report "uart_send_2_rx does not default to 1" severity error;
            assert uart_send_2_ready = '1' report "uart_send_2_ready does not default to 1" severity error;
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_2_in(7 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_2_start <= '1';
            -- Jump to halfway trough start bit
            wait for 2115 ns;
            uart_send_2_start <= '0';
            assert uart_send_2_tx = '0' report "uart_send_2_tx start bit incorrect" severity error;
            assert uart_send_2_ready = '0' report "uart_send_2_ready is one where it should have been zero" severity error;
            for I in 0 to 7 loop
                -- Jump to halfway trough the Ith bit
                wait for 4230 ns;
                assert data_buffer(I) = uart_send_2_tx report "UART 1 tx unexpected value" severity error;
                if data_buffer(I) = '1' then
                    even := not even;
                end if;
            end loop;
            -- Parity bit
            wait for 4230 ns;
            assert uart_send_2_tx = even report "uart_send_2_tx parity bit incorrect, even = " & std_logic'image(even) & " uart_send_2_tx = " & std_logic'image(uart_send_2_tx) & " D = " & integer'image(D) severity error;
            assert uart_send_2_ready = '0' report "uart_send_2_ready is one where it should have been zero" severity error;
            -- stop bit 1
            wait for 4230 ns;
            assert uart_send_2_tx = '1' report "uart_send_2_tx stop bit incorrect" severity error;
            assert uart_send_2_ready = '0' report "uart_send_2_ready is one where it should have been zero" severity error;
            -- stop bit 2
            wait for 4230 ns;
            assert uart_send_2_tx = '1' report "uart_send_2_tx stop bit incorrect" severity error;
            assert uart_send_2_ready = '0' report "uart_send_2_ready is one where it should have been zero" severity error;
            -- Back to start situation
            wait for 4230 ns;
        end loop;
        wait for 4230 ns;
        -- At this point we would test for abnormal situations, but there are none: there is no input for which an error is expected.
        assert false report "data_send_2 tests done" severity note;
        tests(3) <= '1';
        wait;
    end process;

end tb;
