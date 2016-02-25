library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Baudrate for incoming and outgoing is the same. 

-- A note about parity:
-- 0: odd parity
-- 1: even parity
-- 2: always 0 parity
-- 3: always 1 parity
-- if parity_bit is false, this parameter is ignored

entity uart_main is
    generic ( baudrate      : integer;
    pary_bit_in             : boolean;
    parity_bit_in_type      : integer range 0 to 3;
    bit_count_in            : integer range 5 to 9;
    stop_bits_in            : integer range 1 to 2;
    pary_bit_out            : boolean;
    parity_bit_out_type     : integer range 0 to 3;
    bit_count_out           : integer range 5 to 9;
    stop_bits_out           : integer range 1 to 2 );
    Port (
        rst             : in STD_LOGIC;
        clk             : in STD_LOGIC;
        uart_rx         : in STD_LOGIC;
        uart_tx         : out STD_LOGIC;
        send_start      : in STD_LOGIC;
        send_done       : out STD_LOGIC;
        send_data       : in STD_LOGIC_VECTOR(8 DOWNTO 0);
        receved_data    : out STD_LOGIC_VECTOR(8 DOWNTO 0);
        data_ready      : out STD_LOGIC;
        data_error      : out STD_LOGIC
    );
end uart_main;

architecture Behavioral of uart_main is
    component simple_multishot_timer is
        generic ( match_val : integer );
        port (
            clk_50Mhz   : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;

    constant clockspeed     : integer := 5E7;
    constant oversampling   : integer := 8;
    constant sendSpeed      : integer := integer(clockspeed/baudrate);
    constant receiveSpeed   : integer := integer(clockspeed/(baudrate*8));

    signal send_ticker_rst  : STD_LOGIC := 1;
    signal send_ticker_done : STD_LOGIC;
    signal recv_ticker_rst  : STD_LOGIC := 1;
    signal recv_ticker_done : STD_LOGIC;

begin
    -- Create two clocks. The first one is for receiving and is oversampling * baudrate.
    -- The second is for sending and is baudrate.
    send_ticker : simple_multishot_timer
    generic map (
        match_val   => sendSpeed
    )
   port map (
        clk_50Mhz   => clk,
        rst         => send_ticker_rst,
        done        => send_ticker_done
    );

    receive_ticker : simple_multishot_timer
    generic map (
        match_val   => receiveSpeed
    )
   port map (
        clk_50Mhz   => clk,
        rst         => recv_ticker_rst,
        done        => recv_ticker_done
    );
end Behavioral;
