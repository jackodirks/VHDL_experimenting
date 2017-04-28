library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- A change of polarity, phase and block size will only be accepted in the reset state: changing them during run will not affect anything
-- We do not need to debounce MOSI, but we do need to debounce sclk. MOSI is expected to be set half a period ago when it is read, but sclk might still be bouncing when it is read.

entity spi_slave is
    generic (
        debounce_ticks          : natural range 2 to natural'high
    );
    port (
        rst                     : in    STD_LOGIC;
        clk                     : in    STD_LOGIC;
        polarity                : in    STD_LOGIC;                          -- Polarity, CPOL
        phase                   : in    STD_LOGIC;                          -- Phase, CPHA
        sclk                    : in    STD_LOGIC;                          -- Serial clock
        mosi                    : in    STD_LOGIC;                          -- Master output slave input
        miso                    : out   STD_LOGIC;                          -- Master input slave output
        ss                      : in    STD_LOGIC;                          -- Slave Select, if zero, this slave is selected.
        data_in                 : in    STD_LOGIC_VECTOR(31 DOWNTO 0);      -- Data to be transmitted
        data_out                : out   STD_LOGIC_VECTOR(31 DOWNTO 0);      -- Data that has been received
        block_size              : in    Natural range 1 to 32;              -- Data block size
        block_done              : out   boolean                             -- Signals that a data block was processed. This means that in this cycle data_in will be read, and data_out will be updated.
    );
end spi_slave;


architecture Behavioral of spi_slave is
    type state_type is (reset, wait_for_slave_select, wait_for_idle, data_get_wait, data_get, data_set_wait, data_set, block_finished);

    signal sclk_debounced       : STD_LOGIC;
    signal cur_polarity         : STD_LOGIC;
    signal cur_phase            : STD_LOGIC;
    signal cur_block_size       : Natural range 1 to 32;

    signal state                : state_type := reset;

    -- The safe
    signal lock_safe            : boolean;
    -- Input and output buffer control
    signal switch_buffer        : boolean;
    signal read_data_in         : boolean;
    signal next_output          : boolean;
    signal next_input           : boolean;

    component static_debouncer is
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

begin
    block_done <= switch_buffer;
    -- The debouncer for sclk
    sclk_debouncer : static_debouncer
    generic map (
        debounce_ticks => debounce_ticks
    )
    port map (
        clk => clk,
        rst => rst,
        pulse_in => sclk,
        pulse_out => sclk_debounced
    );

    -- The input controller, basically handles the MOSI and data_out signals. One buffer is being written, the other one is being forwarded to the rest of the system.
    input_controller : process(clk, switch_buffer, next_input)
        variable selected_buffer    : natural range 0 to 1 := 0;
        variable buffer_0           : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
        variable buffer_1           : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
        variable cursor             : natural range 0 to 31;
    begin
        if rising_edge(clk) then
            if switch_buffer then
                cursor := 0;
                if selected_buffer = 1 then
                    selected_buffer := 0;
                else
                    selected_buffer := 1;
                end if;
            elsif next_input then
                if selected_buffer = 0 then
                    buffer_0(cursor) := mosi;
                else
                    buffer_1(cursor) := mosi;
                end if;
                cursor := cursor + 1;
            end if;
        end if;
        if selected_buffer = 0 then
            data_out <= buffer_1;
        else
            data_out <= buffer_0;
        end if;
    end process;

    -- The output controller, handles the miso and data_in signals
    output_controller : process(clk, read_data_in, next_output)
        variable data_in_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0);
    begin
        if rising_edge(clk) then
            if read_data_in then
                data_in_buffer := data_in;
            elsif next_output then
                data_in_buffer := '0' & data_in_buffer(31 DOWNTO 1);
            end if;
        end if;
            miso <= data_in_buffer(0);
    end process;

    -- The safe that locks the settings
    settings_safe : process(clk, lock_safe)
        variable lock_polarity      : STD_LOGIC;
        variable lock_phase         : STD_LOGIC;
        variable lock_block_size    : natural range 1 to 32;
    begin
        if rising_edge(clk) and not lock_safe then
            lock_polarity := polarity;
            lock_phase := phase;
            lock_block_size := block_size;
        end if;
        cur_polarity <= lock_polarity;
        cur_phase <= lock_phase;
        cur_block_size <= lock_block_size;
    end process;

    -- State behaviour
    state_behaviour: process(state)
    begin
        case state is
            when reset =>
                lock_safe       <= false;
                switch_buffer   <= false;
                next_output     <= false;
                next_input      <= false;
                read_data_in    <= true;
            when wait_for_slave_select|wait_for_idle =>
                lock_safe       <= true;
                switch_buffer   <= false;
                next_output     <= false;
                next_input      <= false;
                read_data_in    <= true;
            when data_get_wait|data_set_wait =>
                lock_safe       <= true;
                switch_buffer   <= false;
                next_output     <= false;
                next_input      <= false;
                read_data_in    <= false;
            when data_get =>
                lock_safe       <= true;
                switch_buffer   <= false;
                next_output     <= false;
                next_input      <= true;
                read_data_in    <= false;
            when data_set =>
                lock_safe       <= true;
                switch_buffer   <= false;
                next_output     <= true;
                next_input      <= false;
                read_data_in    <= false;
            when block_finished =>
                lock_safe       <= true;
                switch_buffer   <= true;
                next_output     <= false;
                next_input      <= false;
                read_data_in    <= true;
        end case;
    end process;

    -- State transition
    state_transition: process(clk, rst, mosi, sclk, ss)
        variable prev_sclk  : STD_LOGIC;
        variable cur_sclk   : STD_LOGIC;
        variable cur_bit    : natural range 0 to 32;
    begin
        if rst = '1' then
            state <= reset;
            cur_bit := 0;
        elsif ss = '1' then
            state <= wait_for_slave_select;
        elsif rising_edge(clk) then
            prev_sclk := cur_sclk;
            cur_sclk := sclk_debounced;
            case state is
                when reset|wait_for_slave_select =>
                    state <= wait_for_idle;
                when wait_for_idle =>
                    -- possible situations:
                    -- Polarity = 0, sclk = 0, phase = 0: go to data_get
                    -- Polarity = 0, sclk = 0, phase = 1: go to data_set
                    -- Polarity = 1, sclk = 1, phase = 0: go to data_set
                    -- Polarity = 1, sclk = 1, phase = 1: go to data_get
                    -- Polarity != sclk: stay in wait_for_idle
                    if cur_polarity /= cur_sclk then
                        state <= wait_for_idle;
                    elsif cur_polarity = '0' then
                        if cur_phase = '0' then
                            state <= data_get_wait;
                        else
                            state <= data_set_wait;
                        end if;
                    else
                        if cur_phase = '1' then
                            state <= data_get_wait;
                        else
                            state <= data_set_wait;
                        end if;
                    end if;
                when data_get_wait =>
                    -- Wait for the next edge
                    if prev_sclk /= cur_sclk then
                        state <= data_get;
                    else
                        state <= data_get_wait;
                    end if;
                when data_get =>
                    if cur_phase /= cur_polarity then
                        cur_bit := cur_bit + 1;
                        if cur_bit = cur_block_size then
                            state <= block_finished;
                        end if;
                    end if;
                    state <= data_set_wait;
                when data_set_wait =>
                    if prev_sclk /= cur_sclk then
                        state <= data_set;
                    else
                        state <= data_set_wait;
                    end if;
                when data_set =>
                    if cur_phase = cur_polarity then
                        cur_bit := cur_bit + 1;
                        if cur_bit >= cur_block_size then
                            state <= block_finished;
                        else
                            state <= data_get_wait;
                        end if;
                    else
                        state <= data_get_wait;
                    end if;
                when block_finished =>
                    cur_bit := 0;
                    if cur_phase = cur_polarity then
                        state <= data_get_wait;
                    else
                        state <= data_set_wait;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
