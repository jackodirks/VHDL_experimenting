library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

-- Handles the outgoing data.

-- A note about parity:
-- 0: odd parity
-- 1: even parity
-- 2: always 0 parity
-- 3: always 1 parity
-- if parity_bit is false, this parameter is ignored

-- On the next clockcycle from data_send_start the component will lock the data and send all the data, unless reset is asserted in the process.
-- If ready is low the uart transmitter is busy.

-- It is a violation of the UART standard to send 9 bits and a parity bit. This component will not care, however.

entity uart_transmit is
    generic (
        baudrate                : Natural;
        clk_freq                : Natural;
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
end uart_transmit;

architecture Behavioral of uart_transmit is
    function BOOL_TO_INT(X : boolean) return integer is
    begin
        if X then
            return 1;
        else
            return 0;
        end if;
    end BOOL_TO_INT;
    -- Type definition
    type state_type is (reset, wait_send, start_one, start_two, bit_one, bit_two, bit_end, parity_one, parity_two, stop_one, stop_two, restore_timing);
    type output_type is (start, bits, parity, stop);
    -- Constant definition
    constant totalBitsSend      : integer := 1 + bit_count + stop_bits + BOOL_TO_INT(parity_bit_en);
    constant ticksPerHalfSend   : integer := integer(clk_freq/(baudrate*2));
    constant restorationTicks   : natural := (clk_freq * totalBitsSend)/baudrate - (ticksPerHalfSend * totalBitsSend * 2);
    -- Signals
    -- Related to the timer
    signal ticker_rst           : STD_LOGIC := '1';
    signal ticker_done          : STD_LOGIC;
    signal restore_rst          : STD_LOGIC := '1';
    signal restore_done         : STD_LOGIC;
    -- Related to the mux
    signal cur_output           : output_type := stop;
    -- Related to the bit output selector and the parity generator.
    -- On the falling edge of next_bit the next bit is send to the output_bit line and the parity_output is updated
    signal lock_data            : boolean := false;
    signal next_bit             : boolean := false;
    signal output_bit           : STD_LOGIC;
    signal parity_output        : STD_LOGIC;
    -- The state variable of the FSM
    signal state                : state_type := reset;
    -- Helper function for state transitions
    function simple_state_transition(if0: state_type; if1 : state_type; var: STD_LOGIC) return state_type is
    begin
        if var = '1' then
            return if1;
        else
            return if0;
        end if;
    end simple_state_transition;
begin
    -- The ticker
    ticker : entity work.simple_multishot_timer
    generic map (
        match_val   => ticksPerHalfSend
    )
    port map (
        clk         => clk,
        rst         => ticker_rst,
        done        => ticker_done
    );
    -- Restoration ticker
    rest_ticker : entity work.simple_multishot_timer
    generic map (
        match_val   => restorationTicks
    )
    port map (
        clk         => clk,
        rst         => restore_rst,
        done        => restore_done
    );
    -- The mux
    output_mux : process (cur_output, output_bit, parity_output)
    begin
        case cur_output is
            when start  =>
                uart_tx     <= '0';
            when bits   =>
                uart_tx     <= output_bit;
            when parity =>
                uart_tx     <= parity_output;
            when stop   =>
                uart_tx     <= '1';
        end case;
    end process;
    -- The parity generator
    parity_gen : process(clk)
        variable even           : STD_LOGIC := '1';
        variable last_next_bit  : boolean := false;
    begin
        if rising_edge(clk) then
            if not lock_data then
                even := '1';
            elsif next_bit then
                last_next_bit := true;
            elsif last_next_bit then
                last_next_bit := false;
                if output_bit = '1' then
                    even := not even;
                end if;
            end if;
        end if;
        case parity_bit_type is
            when 0 =>
                parity_output <= not even;
            when 1 =>
                parity_output <= even;
            when 2 =>
                parity_output <= '0';
            when 3 =>
                parity_output <= '1';
        end case;
    end process;
    -- The data storage facility
    bit_selector : process(clk)
        variable cur_data       : STD_LOGIC_VECTOR(bit_count - 1 DOWNTO 0) := (others => '0');
        variable last_next_bit  : boolean := false;
    begin
        if rising_edge(clk) then
            if not lock_data then
                cur_data := data_in(bit_count-1 DOWNTO 0);
            elsif next_bit then
                last_next_bit := true;
            elsif last_next_bit then
                last_next_bit := false;
                cur_data := '0' & cur_data(bit_count - 1 DOWNTO 1);
            end if;
        end if;
        output_bit <= cur_data(0);
    end process;

    state_selector : process(clk, rst)
        variable bits_send          : natural := 0;
        variable stop_bits_send     : natural := 0;
    begin
        if rst = '1' then
            bits_send := 0;
            stop_bits_send := 0;
            state <= reset;
        elsif rising_edge(clk) then
            case state is
                when reset =>
                    state <= wait_send;
                when wait_send =>
                    bits_send := 0;
                    stop_bits_send := 0;
                    state <= simple_state_transition(wait_send, start_one, data_send_start);
                when start_one =>
                    state <= simple_state_transition(start_one, start_two, ticker_done);
                when start_two =>
                    state <= simple_state_transition(start_two, bit_one, ticker_done);
                when bit_one =>
                    if ticker_done = '1' then
                        if bits_send = bit_count - 1 then
                            state <= bit_end;
                        else
                            state <= bit_two;
                        end if;
                    else
                        state <= bit_one;
                    end if;
                when bit_two =>
                    if ticker_done = '1' then
                        bits_send := bits_send + 1;
                        state <= bit_one;
                    else
                        state <= bit_two;
                    end if;
                when bit_end =>
                    if ticker_done = '1' then
                        if parity_bit_en then
                            state <= parity_one;
                        else
                            state <= stop_one;
                        end if;
                    else
                        state <= bit_end;
                    end if;
                when parity_one =>
                    state <= simple_state_transition(parity_one, parity_two, ticker_done);
                when parity_two =>
                    state <= simple_state_transition(parity_two, stop_one, ticker_done);
                when stop_one =>
                    state <= simple_state_transition(stop_one, stop_two, ticker_done);
                when stop_two =>
                    if ticker_done = '1' then
                        if stop_bits = 2 then
                            stop_bits_send := stop_bits_send + 1;
                            if stop_bits_send = stop_bits then
                                state <= restore_timing;
                            else
                                state <= stop_one;
                            end if;
                        else
                            state <= restore_timing;
                        end if;
                    else
                        state <= stop_two;
                    end if;
                when restore_timing =>
                    if restore_done = '1' or restorationTicks = 0 then
                        state <= wait_send;
                    else
                        state <= restore_timing;
                    end if;
            end case;
        end if;
    end process;
    -- The state behaviour
    state_output : process (state)
    begin
        case state is
            when reset =>
                ready       <= '0';
                ticker_rst  <= '1';
                cur_output  <= stop;
                lock_data   <= false;
                next_bit    <= false;
                restore_rst <= '1';
            when wait_send =>
                ready       <= '1';
                ticker_rst  <= '1';
                cur_output  <= stop;
                lock_data   <= false;
                next_bit    <= false;
                restore_rst <= '1';
            when start_one =>
                ready       <= '0';
                ticker_rst  <= '0';
                cur_output  <= start;
                lock_data   <= true;
                next_bit    <= false;
                restore_rst <= '1';
            when start_two =>
                ready       <= '0';
                ticker_rst  <= '0';
                cur_output  <= start;
                lock_data   <= true;
                next_bit    <= false;
                restore_rst <= '1';
            when bit_one =>
                ready       <= '0';
                ticker_rst  <= '0';
                cur_output  <= bits;
                lock_data   <= true;
                next_bit    <= false;
                restore_rst <= '1';
            when bit_two|bit_end =>
                ready       <= '0';
                ticker_rst  <= '0';
                cur_output  <= bits;
                lock_data   <= true;
                next_bit    <= true;
                restore_rst <= '1';
            when parity_one|parity_two =>
                ready       <= '0';
                ticker_rst  <= '0';
                cur_output  <= parity;
                lock_data   <= true;
                next_bit    <= false;
                restore_rst <= '1';
            when stop_one|stop_two =>
                ready       <= '0';
                ticker_rst  <= '0';
                cur_output  <= stop;
                lock_data   <= true;
                next_bit    <= false;
                restore_rst <= '1';
            when restore_timing =>
                ready       <= '0';
                ticker_rst  <= '1';
                cur_output  <= stop;
                lock_data   <= false;
                next_bit    <= false;
                restore_rst <= '0';
        end case;
    end process;


end Behavioral;
