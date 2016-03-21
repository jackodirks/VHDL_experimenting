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
end uart_receiv;

architecture Behavioral of uart_receiv is
    component simple_multishot_timer is
        generic (
            match_val : integer
        );
        port (
            clk   : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;

    type state_type is (rst_state, wait_start,
    start_start, start_bit_one, start_bit_two, start_end,
    bit_start, bit_read_one, bit_read_two, bit_end,
    parity_start, parity_read_one, parity_read_two, parity_end,
    stop_start, stop_bit_one, stop_bit_two, stop_end);

    constant oversampling   : Natural := 4;
    constant receiveSpeed   : integer := integer(clockspeed/(baudrate*oversampling));

    signal recv_ticker_rst  : STD_LOGIC := '1';
    signal recv_ticker_done : STD_LOGIC;
    signal state            : state_type := rst_state;

    signal sub_rst          : STD_LOGIC := '0';

    signal barrel_data_in   : STD_LOGIC := '0';
    signal barrel_enable    : STD_LOGIC := '0';

    function simple_state_transition(if0: state_type; if1 : state_type; var: STD_LOGIC) return state_type is
    begin
        if var = '1' then
            return if1;
        else
            return if0;
        end if;
    end simple_state_transition;

begin
    receive_ticker : simple_multishot_timer
    generic map (
        match_val   => receiveSpeed
    )
    port map (
        clk         => clk,
        rst         => recv_ticker_rst,
        done        => recv_ticker_done
    );

    data_shifter : process(clk, sub_rst, barrel_data_in, barrel_enable)
        variable last_known_enable  : STD_LOGIC := '0';
        variable last_known_data    : STD_LOGIC := '0';
        variable barrel_data      : STD_LOGIC_VECTOR(8 DOWNTO 0) := (others => '0');
    begin
        if (sub_rst = '1') then
            received_data       <= (others => '0');
            last_known_enable   := '0';
            last_known_data     := '0';
            barrel_data         := (others => '0');
        elsif rising_edge(clk) then
            if barrel_enable = '1' then
                last_known_enable   := '1';
                last_known_data     :=  barrel_data_in;
            else
                if last_known_enable = '1' then
                    last_known_enable := '0';
                    barrel_data := barrel_data(7 DOWNTO 0) & last_known_data;
                end if;
            end if;
            received_data <= barrel_data;
        end if;
    end process;

    -- State transitions
    process(clk, rst, uart_rx)
        -- State transition control variables
        variable bits_processed         : natural := 0;
        variable stop_bits_processed    : natural := 0;
    begin
        if rst = '1' then
            state <= rst_state;
        elsif rising_edge(clk) then
            case state is
                -- rst_state, wait_start,
                when rst_state =>
                    bits_processed := 0;
                    stop_bits_processed := 0;
                    state <= wait_start;
                when wait_start =>
                    bits_processed := 0;
                    stop_bits_processed := 0;
                    state <= simple_state_transition(start_start, wait_start, uart_rx);
                -- start_start, start_bit_one, start_bit_two, start_end,
                when start_start =>
                    state <= simple_state_transition(start_start, start_bit_one, recv_ticker_done);
                when start_bit_one =>
                    state <= simple_state_transition(start_bit_one, start_bit_two, recv_ticker_done);
                when start_bit_two =>
                    state <= simple_state_transition(start_bit_two, start_end, recv_ticker_done);
                when start_end =>
                    state <= simple_state_transition(start_end, bit_start, recv_ticker_done);
                --bit_start, bit_read_one, bit_read_two, bit_end,
                when bit_start =>
                    state <= simple_state_transition(bit_start, bit_read_one, recv_ticker_done);
                when bit_read_one =>
                    state <= simple_state_transition(bit_read_one, bit_read_two, recv_ticker_done);
                when bit_read_two =>
                    state <= simple_state_transition(bit_read_two, bit_end, recv_ticker_done);
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
                -- parity_start, parity_read_one, parity_read_two, parity_end,
                when parity_start =>
                    state <= simple_state_transition(parity_start, parity_read_one, recv_ticker_done);
                when parity_read_one =>
                    state <= simple_state_transition(parity_read_one, parity_read_two, recv_ticker_done);
                when parity_read_two =>
                    state <= simple_state_transition(parity_read_two, parity_end, recv_ticker_done);
                when parity_end =>
                    state <= simple_state_transition(parity_end, stop_start, recv_ticker_done);
                -- stop_start, stop_read_one, stop_read_two, stop_end);
                when stop_start =>
                    state <= simple_state_transition(stop_start, stop_bit_one, recv_ticker_done);
                when stop_bit_one =>
                    state <= simple_state_transition(stop_bit_one, stop_bit_two, recv_ticker_done);
                when stop_bit_two =>
                    if recv_ticker_done = '1' then
                        stop_bits_processed := stop_bits_processed + 1;
                        if stop_bits_processed = stop_bits_in then
                            state <= wait_start;
                        else
                            state <= stop_end;
                        end if;
                    else
                        state <= stop_bit_two;
                    end if;
                when stop_end =>
                    state <= simple_state_transition(stop_end, stop_start, recv_ticker_done);
                when others =>
                    state <= rst_state;
            end case;
        end if;
    end process;

    process(state, uart_rx)
        variable bit_one        : STD_LOGIC := '0';
        variable even           : STD_LOGIC := '1';
        variable data_err_v     : STD_LOGIC := '0';
        variable parity_err_v   : STD_LOGIC := '0';
        variable data_ready_v   : STD_LOGIC := '0';
    begin
            case state is
                when rst_state =>
                -- Variable assignments
                    bit_one         := '0';
                    even            := '1';
                    data_err_v      := '0';
                    parity_err_v    := '0';
                    data_ready_v    := '0';
                -- Signal assignments
                    data_ready      <= '1';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '1';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '1';
                when wait_start =>
                -- Signal assignments
                    data_ready      <= data_ready_v;
                    parity_error    <= parity_err_v;
                    data_error      <= data_err_v;
                    recv_ticker_rst <= '1';
                    sub_rst         <= '0';
                when start_start =>
                -- Variable assignments
                    data_ready_v    := '0';
                    parity_err_v    := '0';
                    data_err_v      := '0';
                    bit_one         := '0';
                    even            := '1';
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '1';
                when start_end|bit_start|bit_end|parity_start|parity_end|stop_start|stop_end =>
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '0';
                when start_bit_one|bit_read_one|parity_read_one|stop_bit_one =>
                -- Variable assignments
                    bit_one         := uart_rx;
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '0';
                when start_bit_two =>
                -- Variable assignments
                    if (uart_rx /= bit_one or uart_rx /= '0') then
                        data_err_v := '1';
                    end if;
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '0';
                when bit_read_two =>
                --Variable assignments
                    if (uart_rx /= bit_one) then
                        data_err_v  := '1';
                    end if;
                    if parity_bit_in and (parity_bit_in_type = 0 or parity_bit_in_type = 1) and bit_one = '1' then
                        even        := not even;
                    end if;
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '1';
                    barrel_data_in  <= bit_one;
                    sub_rst         <= '0';
                when parity_read_two =>
                -- Variable assignments
                    if (uart_rx /= bit_one) then
                        data_err_v  := '1';
                    end if;
                    case parity_bit_in_type is
                        when 0 =>
                            parity_err_v := even xnor uart_rx;
                        when 1 =>
                            parity_err_v := even xor uart_rx;
                        when 2 =>
                            parity_err_v := uart_rx;
                        when 3 =>
                            parity_err_v := not uart_rx;
                    end case;
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '0';
                when stop_bit_two =>
                -- Variable assignments
                    if (uart_rx /= bit_one or uart_rx /= '1') then
                        data_err_v  := '1';
                    end if;
                    data_ready_v    := '1';
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '0';
                    data_error      <= '0';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '0';
                when others =>
                -- Signal assignments
                    data_ready      <= '0';
                    parity_error    <= '1';
                    data_error      <= '1';
                    recv_ticker_rst <= '0';
                    barrel_enable   <= '0';
                    barrel_data_in  <= '0';
                    sub_rst         <= '0';
            end case;
    end process;
end Behavioral;

