library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;
use IEEE.numeric_std.ALL;
use IEEE.math_real.ALL;

entity uart_tb is
    generic (
        clock_period : time;
        randVal : natural
    );
    port (
        clk : in STD_LOGIC;
        done : out boolean;
        success : out boolean
    );
end uart_tb;

architecture Behavioral of uart_tb is

    component uart_receiv is
        generic (
            baudrate                : Natural;
            clk_freq              : Natural;
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
            clk_freq              : Natural;
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
            clk_freq              : Natural;
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

    signal uart_receiv_1_done               : boolean := false;
    signal uart_receiv_2_done               : boolean := false;
    signal uart_send_1_done                 : boolean := false;
    signal uart_send_2_done                 : boolean := false;
    signal uart_main_done                   : boolean := false;

    signal uart_receiv_1_success            : boolean := false;
    signal uart_receiv_2_success            : boolean := false;
    signal uart_send_1_success              : boolean := false;
    signal uart_send_2_success              : boolean := false;
    signal uart_main_success                : boolean := false;

    constant clk_freq                       : natural := (1000 ms / clock_period);
    constant baudrate                       : natural := 236400;
    constant baud_period                    : time := (1000 ms / baudrate);
    constant clk_ticks_per_baud             : natural := (natural(ceil(real(clk_freq)/real(baudrate))));

begin

    done <= uart_receiv_1_done and uart_receiv_2_done and uart_send_1_done and uart_send_2_done;
    success <= uart_receiv_1_success and uart_receiv_2_success and uart_send_1_success and uart_send_2_success;

    uart_receiver_1 : uart_receiv
    generic map (
        baudrate => baudrate,
        clk_freq => clk_freq,
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
        baudrate => baudrate,
        clk_freq => clk_freq,
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
        baudrate            => baudrate,
        clk_freq          => clk_freq,
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
        baudrate            => baudrate,
        clk_freq            => clk_freq,
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
        clk_freq            => clk_freq,
        baudrate            => baudrate,
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

    uart_main_rx <= uart_main_tx;

    uart_main_tester : process
        variable suc : boolean := true;
        variable test_data : STD_LOGIC_VECTOR(5 DOWNTO 0) := "101000";
    begin
        uart_main_rst <= '0';
        wait for clock_period;
        report "clk_period " & time'image(clock_period) & " clk_ticks_per_baud " & natural'image(clk_ticks_per_baud) & " baud_period " & time'image(baud_period) severity note;
        for D in 0 to 63 loop
            uart_main_data_in(5 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(D, 6));
            uart_main_send_start <= '1';
            wait for clock_period;
            uart_main_send_start <= '0';
            wait for 10 * baud_period; -- Wait for 10 baud ticks, which is about 2120 cycles on a 50 MHz clock
            wait for 5 * clock_period;
            if uart_main_data_ready /= '1' then
                report "uart_main had not received on D = " & integer'image(D) severity error;
                suc := false;
            end if;
            if uart_main_send_ready /= '1' then
                report "uart main is not ready to send on D = " & integer'image(D) severity error;
                suc := false;
            end if;
            if uart_main_data_error /= '0' then
                report "UART main reports unexpected data error on D = " & integer'image(D) severity error;
                suc := false;
            end if;
            if uart_main_parity_error /= '0' then
                report "UART main reports unexpected parity error on D = " & integer'image(D) severity error;
                suc := false;
            end if;
            if uart_main_data_out(5 DOWNTO 0) /= STD_LOGIC_VECTOR(to_unsigned(D, 6)) then
                report "uart main send/receive error on D = " & integer'image(D) severity error;
                suc := false;
            end if;
        end loop;
        report "Uart main test done" severity note;
        wait;
        uart_main_success <= suc;
        uart_main_done <= true;
    end process;

    uart_receiver_1_tester : process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0);
        variable suc            : boolean := true;
    begin
        uart_receiv_1_rst <= '0';
        wait for baud_period;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_receiv_1_rx <= '0';
            for I in 0 TO 7 loop
                wait for baud_period;
                uart_receiv_1_rx <= data_buffer(I);
            end loop;
            wait for baud_period;
            uart_receiv_1_rx <= '1';
            wait for baud_period;
            if uart_receiv_1_ready /= '1' then
                suc := false;
                report "Uart_receiv_1 was not ready, while it was expected to be" severity error;
            end if;
            if uart_receiv_1(7 DOWNTO 0) /= data_buffer then
                report "uart_receiv_1 unexpected value" severity error;
                suc := false;
            end if;
            if uart_receiv_1_dat_err /= '0' then
                report "uart_receiv_1_dat_err unexpected value" severity error;
                suc := false;
            end if;
            if uart_receiv_1_par_err /= '0' then
                report "uart_receiv_1_par_err unexpected value" severity error;
                suc := false;
            end if;
        end loop;
        uart_receiv_1_rst <= '1';
        report "UART_receiv_1 test done" severity note;
        uart_receiv_1_done <= true;
        uart_receiv_1_success <= suc;
        wait;
    end process;

    uart_receive_2_tester : process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0);
        variable odd            : STD_LOGIC := '0';
        variable suc            : boolean := true;
    begin
        uart_receiv_2_rx <= '1';
        uart_receiv_2_rst <= '0';
        wait for baud_period;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_receiv_2_rx <= '0';
            for I in 0 to 7 loop
                wait for baud_period;
                uart_receiv_2_rx <= data_buffer(I);
                if data_buffer(I) = '1' then
                    odd := not odd;
                end if;
            end loop;
            wait for baud_period;
            -- Send the parity bit
            uart_receiv_2_rx <= odd;
            wait for baud_period;
            uart_receiv_2_rx <= '1';
            wait for baud_period;
            wait for baud_period;
            if uart_receiv_2_ready /= '1' then
                suc := false;
                report "Uart receiv 2 was not ready while it was expected to be ready" severity error;
            end if;
            if uart_receiv_2(7 DOWNTO 0) /= data_buffer  then
                report "uart_receiv_2 unexpected value" severity error;
                suc := false;
            end if;
            if uart_receiv_2_dat_err /= '0' then
                report "uart_receiv_2_dat_err unexpected value" severity error;
                suc := false;
            end if;
            if uart_receiv_2_par_err /= '0' then
                report "uart_receiv_2_par_err unexpected value" severity error;
                suc := false;
            end if;
            odd := '0';
        end loop;
        uart_receiv_2_rst <= '1';
        -- Test if the parity error happens when expected
        wait for clock_period;
        uart_receiv_2_rst <= '0';
        -- Test for parity error
        data_buffer := STD_LOGIC_VECTOR(to_unsigned(randVal, data_buffer'length));
        odd         := '0';
        -- Start bit
        uart_receiv_2_rx <= '0';
        -- Send data
        for I in 0 to 7 loop
            wait for baud_period;
            uart_receiv_2_rx <= data_buffer(I);
            if data_buffer(I) = '1' then
                odd := not odd;
            end if;
        end loop;
        -- Send the wrong parity bit
        wait for baud_period;
        uart_receiv_2_rx <= not odd;
        wait for baud_period;
        -- Double stop bit
        uart_receiv_2_rx <= '1';
        wait for baud_period;
        wait for baud_period;
        if uart_receiv_2_ready /= '1' then
            suc := false;
            report "Uart receiv 2 was not ready while it was expected to be ready" severity error;
        end if;
        if uart_receiv_2(7 DOWNTO 0) /= data_buffer then
            suc := false;
            report "uart_receiv_2 unexpected value" severity error;
        end if;
        if uart_receiv_2_dat_err /= '0' then
            suc := false;
            report "uart_receiv_2_dat_err unexpected value" severity error;
        end if;
        if uart_receiv_2_par_err /= '1' then
            suc := false;
            report "uart_receiv_2_par_err unexpected value, expected to fail, but passed, randval was " & integer'image(randVal) severity error;
        end if;
        uart_receiv_2_rst <= '1';
        report "UART_receiv_2 test done" severity note;
        uart_receiv_2_done <= true;
        uart_receiv_2_success <= suc;
        wait;
    end process;

    uart_send_1_test : process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
        variable suc            : boolean := true;
    begin
        uart_send_1_rst <= '0';
        wait for clock_period;
        if uart_send_1_tx /= '1' then
            suc := false;
            report "uart_send_1_rx does not default to 1" severity error;
        end if;
        if uart_send_1_ready /= '1' then
           report "uart_send_1_ready does not default to 1" severity error;
           suc := false;
       end if;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_1_in(7 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_1_start <= '1';
            wait for baud_period/2; -- We want to poll halfway trough
            uart_send_1_start <= '0';
            if uart_send_1_tx /= '0' then
                report "uart_send_1_tx start bit incorrect" severity error;
                suc := false;
            end if;
            if uart_send_1_ready /= '0' then
               report "uart_send_1_ready is one where it should have been zero" severity error;
               suc := false;
           end if;
            for I in 0 to 7 loop
                wait for baud_period;
                if data_buffer(I) /= uart_send_1_tx then
                   report "UART 1 tx unexpected value" severity error;
                   suc := false;
               end if;
            end loop;

            wait for baud_period;
            if uart_send_1_tx /= '1' then
                report "uart_send_1_tx stop bit incorrect" severity error;
                suc := false;
            end if;
            if uart_send_1_ready /= '0' then
                report "uart_send_1_ready is one where it should have been zero" severity error;
                suc := false;
            end if;
            wait for baud_period;
            if uart_send_1_tx /= '1' then
                report "uart_send_1_tx stop bit incorrect" severity error;
                suc := false;
            end if;
            if uart_send_1_ready /= '1' then
                report "uart_send_1_ready is not one in time" severity error;
                suc := false;
            end if;
        end loop;
        report "data_send_1 tests done" severity note;
        uart_send_1_done <= true;
        uart_send_1_success <= suc;
        wait;
    end process;

    uart_send_2_test : process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
        variable even           : STD_LOGIC := '1';
        variable suc            : boolean := true;
    begin
        uart_send_2_rst <= '0';
        -- Test the start situation
        if uart_send_2_tx = '1' then
            report "uart_send_2_tx does not default to 1" severity error;
            suc := false;
        end if;
        if uart_send_2_ready = '1' then
            report "uart_send_2_ready does not default to 1" severity error;
            suc := false;
        end if;
        wait for clock_period;
        for D in 0 to 255 loop
            even := '1';
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_2_in(7 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_send_2_start <= '1';
            -- Jump to halfway trough start bit
            wait for baud_period/2;
            uart_send_2_start <= '0';
            if uart_send_2_tx /= '0' then
                report "uart_send_2_tx start bit incorrect" severity error;
                suc := false;
            end if;
            if uart_send_2_ready /= '0' then
                report "uart_send_2_ready is one where it should have been zero" severity error;
                suc := false;
            end if;
            for I in 0 to 7 loop
                -- Jump to halfway trough the Ith bit
                wait for baud_period;
                if data_buffer(I) /= uart_send_2_tx then
                    report "UART_2_send_tx unexpected value" severity error;
                    suc := false;
                end if;
                if data_buffer(I) = '1' then
                    even := not even;
                end if;
            end loop;
            -- Parity bit
            wait for baud_period;
            if uart_send_2_tx /= even then
                report "uart_send_2_tx parity bit incorrect, even = " & std_logic'image(even) & " uart_send_2_tx = " & std_logic'image(uart_send_2_tx) & " D = " & integer'image(D) severity error;
                suc := false;
            end if;
            if uart_send_2_ready /= '0' then
                report "uart_send_2_ready is one where it should have been zero" severity error;
                suc := false;
            end if;
            -- stop bit 1
            wait for baud_period;
            if uart_send_2_tx /= '1' then
                report "uart_send_2_tx stop bit incorrect" severity error;
                suc := false;
            end if;
            if uart_send_2_ready /= '0' then
                report "uart_send_2_ready is one where it should have been zero" severity error;
                suc := false;
            end if;
            -- stop bit 2
            wait for baud_period;
            if uart_send_2_tx /= '1' then
                report "uart_send_2_tx stop bit incorrect" severity error;
                suc := false;
            end if;
            if uart_send_2_ready /= '0' then
                report "uart_send_2_ready is one where it should have been zero" severity error;
                suc := false;
            end if;
            -- Back to start situation
            wait for baud_period;
        end loop;
        wait for baud_period;
        -- At this point we would test for abnormal situations, but there are none: there is no input for which an error is expected.
        report "data_send_2 tests done" severity note;
        uart_send_2_done <= true;
        uart_send_2_success <= suc;
        wait;
    end process;

end Behavioral;
