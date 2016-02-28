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

    type state_type is (rst, wait_start, start_start, start_bit_one, start_bit_two, start_end,
    bit_start, bit_read_one, bit_read_two, bit_end, parity_start, parity_read_one, parity_read_two, parity_end, stop_start, stop_read_one, stop_read_two, stop_end);

    constant oversampling   : Natural := 4;
    constant receiveSpeed   : integer := integer(clockspeed/(baudrate*oversampling));

    signal recv_ticker_rst  : STD_LOGIC := 1;
    signal recv_ticker_done : STD_LOGIC;
    signal state            : state_type := rst;

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

    -- State transitions
    process(clk, rst, uart_rx)
        -- State transition control variables
        variable ticks_passed   : natural := 0;
        variable bits_processed : natural := 0;
    begin
        if rst = '1' then
            state <= rst;
        elsif rising_edge(clk) then
            case state is
                when rst =>
                    ticks_passed := 0;
                    state <= wait_start;
                when wait_start =>
                    ticks_passed := 0;
                    if uart_rx = '0' then
                        state <= process_start;
                    else
                        state <= wait_start;
                    end if;
                when process_start =>
                    bits_processed := 0;
                    if recv_ticker_done = '1' then
                        ticks_passed := ticks_passed + 1;
                        if ticks_passed = oversampling then
                            state <= bit_start;
                        else
                            state <= process_start;
                        end if;
                    else
                        state <= process_start;
                    end if;
                when bit_start =>
                    ticks_passed := 0;
                    if recv_ticker_done = '1' then
                        state <= bit_read_one;
                    else
                        state <= bit_start;
                    end if;
                when bit_read_one =>
                    if recv_ticker_done = '1' then
                        state <= bit_read_two;
                    else
                        state <= bit_read_one;
                    end if;
                when bit_read_two =>
                    if recv_ticker_done = '1' then
                        state <= bit_end;
                    else
                        state <= bit_read_two;
                    end if;
                when bit_end =>
                    if recv_ticker_done = '1' then
                        bits_processed := bits_processed + 1;
                        if bits_processed = bit_count_in then
                            if parity_bit_in then
                                state <= parity_start;
                            else
                                state <= stop_start;
                            end if;
                        else
                            state <= bit_start;
                        end if;
                    else
                        state <= bit_end;
                    end if;
            end case;
        end if;
    end process;

    process(state, uart_rx)
    begin
    end process;
end Behavioral;

