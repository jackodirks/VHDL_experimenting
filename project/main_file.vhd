library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- JA_gpio(0) general reset
-- JA_gpio(1) UART_rx
-- JA_gpio(2) UART_tx
-- JA_GPIO(3) Reset to uC
entity main_file is
    Port (
        JA_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JB_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JC_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JD_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        slide_switch : in  STD_LOGIC_VECTOR (7 downto 0);
        push_button : in  STD_LOGIC_VECTOR (3 downto 0);
        led : out  STD_LOGIC_VECTOR (7 downto 0);
        seven_seg_kath : out  STD_LOGIC_VECTOR (7 downto 0);
        seven_seg_an : out  STD_LOGIC_VECTOR (3 downto 0);
        clk : in  STD_LOGIC
    );
end main_file;

architecture Behavioral of main_file is

    component seven_segments_driver is
        generic (
            switch_freq         : natural;
            clockspeed          : natural
        );
        Port (
            clk                 : in    STD_LOGIC;
            ss_1                : in    STD_LOGIC_VECTOR (3 downto 0);
            ss_2                : in    STD_LOGIC_VECTOR (3 downto 0);
            ss_3                : in    STD_LOGIC_VECTOR (3 downto 0);
            ss_4                : in    STD_LOGIC_VECTOR (3 downto 0);
            seven_seg_kath      : out   STD_LOGIC_VECTOR (7 downto 0);
            seven_seg_an        : out   STD_LOGIC_VECTOR (3 downto 0)
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

        component button_to_single_pulse is
            generic (
                debounce_ticks      : natural range 2 to natural'high
            );
            port (
                clk                 : in STD_LOGIC;
                rst                 : in STD_LOGIC;
                pulse_in            : in STD_LOGIC;
                pulse_out           : out STD_LOGIC
            );
        end component;

        component data_safe_8_bit is
            port (
                clk         : in STD_LOGIC;
                rst         : in STD_LOGIC;
                read        : in STD_LOGIC;
                data_in     : in STD_LOGIC_VECTOR(7 DOWNTO 0);
                data_out    : out STD_LOGIC_VECTOR(7 DOWNTO 0)
            );
        end component;

        signal rst          : STD_LOGIC;
        signal safe_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

        signal uart_receive_done    : STD_LOGIC;
        signal uart_received_data   : STD_LOGIC_VECTOR(8 DOWNTO 0);
        signal uart_data_error      : STD_LOGIC;
        signal uart_parity_error    : STD_LOGIC;
        signal uart_rx              : STD_LOGIC;
        signal uart_data_ready      : STD_LOGIC;

        signal uart_tx              : STD_LOGIC;
        signal uart_send_data       : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
        signal uart_start_send      : STD_LOGIC := '0';
        signal uart_send_ready      : STD_LOGIC;

        signal debounce_pulse_in    : STD_LOGIC;
        signal debounce_pulse_out   : STD_LOGIC;

begin
    uart : uart_main
    generic map (
        clockspeed          => 50000000,
        baudrate            => 115107,
        parity_bit_en       => true,
        parity_bit_type     => 1,
        bit_count           => 8,
        stop_bits_count     => 1
    )
    port map (
        rst                 => rst,
        clk                 => clk,
        uart_rx             => uart_rx,
        uart_tx             => uart_tx,
        send_start          => uart_start_send,
        data_in             => uart_send_data,
        data_out            => uart_received_data,
        data_ready          => uart_receive_done,
        data_error          => uart_data_error,
        parity_error        => uart_parity_error,
        send_ready          => uart_send_ready
    );

    ss_driver : seven_segments_driver
    generic map (
        switch_freq => 400,
        clockspeed => 50000000
    )
    port map (
        clk => clk,
        ss_1 => safe_data(3 DOWNTO 0),
        ss_2 => safe_data(7 DOWNTO 4),
        ss_3 => slide_switch(3 DOWNTO 0),
        ss_4 => slide_switch(7 DOWNTO 4),
        seven_seg_kath => seven_seg_kath,
        seven_seg_an => seven_seg_an
    );

    data_safe : data_safe_8_bit
    port map (
        clk => clk,
        rst => rst,
        read => uart_data_ready,
        data_in => uart_received_data( 7 DOWNTO 0),
        data_out => safe_data
    );

    debouncer : button_to_single_pulse
    generic map (
        debounce_ticks => 50000
    )
    port map (
        clk => clk,
        rst => rst,
        pulse_in => debounce_pulse_in,
        pulse_out => debounce_pulse_out
    );

    rst <=  push_button(0) or JA_gpio(0);
    led(0) <= uart_data_error;
    led(1) <= uart_parity_error;
    led(2) <= uart_receive_done;
    led(3) <= uart_send_ready;
    led(4) <= '0';
    led(5) <= push_button(2);
    led(6) <= push_button(3);
    led(7) <= rst;
    JA_gpio(3) <= not push_button(0);
    uart_rx <= JA_gpio(1);
    JA_gpio(2) <= uart_tx;
    uart_send_data ( 7 DOWNTO 0) <= slide_switch;
    debounce_pulse_in <= push_button(1);
    uart_start_send <= debounce_pulse_out;
    uart_data_ready <= uart_receive_done and not uart_data_error;
end Behavioral;
