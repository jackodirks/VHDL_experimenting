library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Handles the incoming data.

-- A note about parity:
-- 0: odd parity
-- 1: even parity
-- 2: always 0 parity
-- 3: always 1 parity
-- if parity_bit is false, this parameter is ignored

entity uart_receiv is
    generic (
        baudrate                : Natural;
        clockspeed              : Natural;
        pary_bit_in             : boolean;
        parity_bit_in_type      : Natural range 0 to 3;
        bit_count_in            : Natural range 5 to 9;
        stop_bits_in            : Natural range 1 to 2
    );
    port (
        rst                     : in STD_LOGIC;
        clk                     : in STD_LOGIC;
        uart_rx                 : in STD_LOGIC;
        receved_data            : out STD_LOGIC_VECTOR(8 DOWNTO 0);
        data_ready              : out STD_LOGIC;                    -- Signals that data has been received.
        parity_error            : out STD_LOGIC;                    -- Signals that the parity check has failed, is zero if there was none
        data_error              : out STD_LOGIC                     -- Signals that data receiving has encoutered errors
    );
end uart_receiv;

architecture Behavioral of uart_receiv is
    component simple_multishot_timer is
        generic (
            match_val : integer
        );
        port (
            clk_50Mhz   : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;

    constant oversampling   : Natural := 4;
    constant receiveSpeed   : integer := integer(clockspeed/(baudrate*oversampling));

    signal recv_ticker_rst  : STD_LOGIC := 1;
    signal recv_ticker_done : STD_LOGIC;
begin

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

