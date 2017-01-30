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
        clk_freq                : Natural;
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
    stop_start, stop_bit_one, stop_bit_two, stop_bit_two_final, stop_end);

    constant oversampling   : Natural := 4;
    constant receiveSpeed   : integer := integer(clk_freq/(baudrate*oversampling));

    signal recv_ticker_rst  : STD_LOGIC := '1';
    signal recv_ticker_done : STD_LOGIC;
    signal state            : state_type := rst_state;

    signal sub_rst          : boolean := false;

    signal barrel_data_in   : STD_LOGIC := '0';
    signal barrel_enable    : boolean := false;

    signal data_error_b1_in : STD_LOGIC := '0';
    signal data_error_b1_en : boolean := false;
    signal data_error_b2_in : STD_LOGIC := '0';
    signal data_error_b2_en : boolean := false;
    signal data_error_ref   : STD_LOGIC := '0';

    signal parity_test      : boolean := false;
    signal parity_ref       : STD_LOGIC := '0';

    signal ready_enable     : boolean := false;

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

    data_shifter : process(clk, sub_rst)
        variable last_known_enable  : boolean := false;
        variable last_known_data    : STD_LOGIC := '0';
        variable barrel_data      : STD_LOGIC_VECTOR(bit_count_in-1 DOWNTO 0) := (others => '0');
    begin
        if sub_rst then
            last_known_enable   := false;
            last_known_data     := '0';
            barrel_data         := (others => '0');
        elsif rising_edge(clk) then
            if barrel_enable then
                last_known_enable   := true;
                last_known_data     :=  barrel_data_in;
            else
                if last_known_enable then
                    last_known_enable := false;
                    barrel_data := last_known_data & barrel_data(bit_count_in-1 DOWNTO 1);
                end if;
            end if;
        end if;
        received_data( 8 DOWNTO bit_count_in) <= (others => '0');
        received_data( bit_count_in-1 DOWNTO 0) <= barrel_data;
    end process;

    data_error_tester : process(clk, sub_rst)
        variable last_known_b1in    : STD_LOGIC := '0';
        variable data_error_out     : STD_LOGIC := '0';
    begin
        if sub_rst then
            last_known_b1in := '0';
            data_error_out  := '0';
        elsif rising_edge(clk) then
            if data_error_b1_en then
                last_known_b1in := data_error_b1_in;
            end if;
            if data_error_b2_en then
                if last_known_b1in /= data_error_b2_in or data_error_ref /= data_error_b2_in then
                    data_error_out := '1';
                end if;
            end if;
        end if;
        data_error <= data_error_out;
    end process;

    parity_tester : process(clk, sub_rst)
        variable last_known_enable      : boolean := false;
        variable last_known_data        : STD_LOGIC := '0';
        variable parity_error_out       : STD_LOGIC := '0';
        variable parity_ref_reg         : STD_LOGIC := '0';
        variable even                   : STD_LOGIC := '1';
    begin
        if sub_rst then
            last_known_enable   := false;
            last_known_data     := '0';
            parity_error_out    := '0';
            even                := '1';
        elsif rising_edge(clk) then
            if barrel_enable then
                last_known_enable   := true;
                last_known_data     :=  barrel_data_in;
            else
                if last_known_enable then
                    last_known_enable := false;
                    if last_known_data = '1' then
                        even := not even;
                    end if;
                end if;
            end if;

            if parity_test then
                case parity_bit_in_type is
                    when 0 =>
                        parity_error_out := even xnor parity_ref;
                    when 1 =>
                        parity_error_out := even xor parity_ref;
                    when 2 =>
                        parity_error_out := parity_ref;
                    when 3 =>
                        parity_error_out := not parity_ref;
                    when others =>
                        parity_error_out := '1';
                end case;
            end if;
        end if;
        parity_error <= parity_error_out;
    end process;

    ready_lock : process (clk, sub_rst)
        variable ready_out : STD_LOGIC := '0';
    begin
        if sub_rst then
            ready_out := '0';
        elsif rising_edge(clk) then
            if ready_enable then
                ready_out := '1';
            end if;
        end if;
        data_ready <= ready_out;
    end process;

    -- State transitions
    process(clk, rst)
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
                    if stop_bits_processed = stop_bits_in - 1 then
                        state <= simple_state_transition(stop_bit_one, stop_bit_two_final, recv_ticker_done);
                    else
                        state <= simple_state_transition(stop_bit_one, stop_bit_two, recv_ticker_done);
                    end if;
                when stop_bit_two =>
                    if recv_ticker_done = '1' then
                        stop_bits_processed := stop_bits_processed + 1;
                        state <= stop_end;
                    else
                        state <= stop_bit_two;
                    end if;
                when stop_bit_two_final =>
                    state <= simple_state_transition(stop_bit_two_final, wait_start, recv_ticker_done);
                when stop_end =>
                    state <= simple_state_transition(stop_end, stop_start, recv_ticker_done);
                when others =>
                    state <= rst_state;
            end case;
        end if;
    end process;

    process(state, uart_rx)
    begin
        case state is
            when rst_state =>
                -- Signal assignments
                recv_ticker_rst     <= '1';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= true;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= '0';
                data_error_b2_en    <= false;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when wait_start =>
                -- Signal assignments
                recv_ticker_rst     <= '1';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= '0';
                data_error_b2_en    <= false;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when start_start =>
                -- Signal assignments
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= true;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= '0';
                data_error_b2_en    <= false;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when start_end|bit_start|bit_end|parity_start|parity_end|stop_start|stop_end =>
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= '0';
                data_error_b2_en    <= false;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when start_bit_one|bit_read_one|parity_read_one|stop_bit_one =>
                -- Signal assignments
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= uart_rx;
                data_error_b1_en    <= true;
                data_error_b2_in    <= '0';
                data_error_b2_en    <= false;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when start_bit_two =>
                -- Signal assignments
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= uart_rx;
                data_error_b2_en    <= true;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when bit_read_two =>
                -- Signal assignments
                recv_ticker_rst     <= '0';
                barrel_enable       <= true;
                barrel_data_in      <= uart_rx;
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= uart_rx;
                data_error_b2_en    <= true;
                data_error_ref      <= uart_rx;
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when parity_read_two =>
                -- Signal assignments
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= uart_rx;
                data_error_b2_en    <= true;
                data_error_ref      <= uart_rx;
                if parity_bit_in then
                    parity_test     <= true;
                    parity_ref      <= uart_rx;
                else
                    parity_test     <= false;
                    parity_ref      <= '0';
                end if;
                ready_enable        <= false;
            when stop_bit_two =>
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <=  uart_rx;
                data_error_b2_en    <= true;
                data_error_ref      <= '1';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
            when stop_bit_two_final =>
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <=  uart_rx;
                data_error_b2_en    <= true;
                data_error_ref      <= '1';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= true;
            when others =>
                -- Signal assignments
                recv_ticker_rst     <= '0';
                barrel_enable       <= false;
                barrel_data_in      <= '0';
                sub_rst             <= false;
                data_error_b1_in    <= '0';
                data_error_b1_en    <= false;
                data_error_b2_in    <= '0';
                data_error_b2_en    <= true;
                data_error_ref      <= '0';
                parity_test         <= false;
                parity_ref          <= '0';
                ready_enable        <= false;
        end case;
    end process;
end Behavioral;

