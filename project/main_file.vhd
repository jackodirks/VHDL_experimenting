library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- JA_gpio(0) general reset
-- JA_gpio(1) UART_rx
-- JA_gpio(2) UART_tx
-- JA_GPIO(3) unassigned
entity main_file is
    Port (
        --rst : in STD_LOGIC;
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

    component data_safe_8_bit is
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            read        : in STD_LOGIC;
            data_in     : in STD_LOGIC_VECTOR(7 DOWNTO 0);
            data_out    : out STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    end component;

    signal rst			: STD_LOGIC;
    signal safe_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

    signal uart_receive_done    : STD_LOGIC;
    signal uart_received_data   : STD_LOGIC_VECTOR(8 DOWNTO 0);

begin
    uart_receiver : uart_receiv
    generic map (
        baudrate => 9600,
        clockspeed => 50000000,
        parity_bit_in => false,
        parity_bit_in_type => 0,
        bit_count_in => 8,
        stop_bits_in => 1
    )
    port map (
        rst => rst,
        clk => clk,
        uart_rx => JA_gpio(1),
        received_data=> uart_received_data,
        data_ready => uart_receive_done,
        parity_error => led(0),
        data_error => led(1)
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
        ss_3 => uart_received_data(7 DOWNTO 4),
        ss_4 => uart_received_data(3 DOWNTO 0),
        seven_seg_kath => seven_seg_kath,
        seven_seg_an => seven_seg_an
    );

    data_safe : data_safe_8_bit
    port map (
        clk => clk,
        rst => rst,
        read => uart_receive_done,
        data_in => uart_received_data( 7 DOWNTO 0),
        data_out => safe_data
    );
    rst <=  push_button(0) or JA_gpio(0);
	 led(2) <= rst;
	 led(3) <= push_button(0);
	 led(4) <= uart_receive_done;
	 led(5) <= JA_gpio(1);
	 led(6) <= '0';
	 led(7) <= '0';
	 JA_gpio(3) <= '0';
	 JA_gpio(2) <= '1';
end Behavioral;

