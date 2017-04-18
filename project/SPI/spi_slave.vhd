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
        transmit_data_copied    : out   boolean;                            -- If this value is false, data is being read and data_in should be left stable. If this value is true, then data_in can be changed
        receive_done            : out   boolean                             -- Signals that data_out has updated
    );
end spi_slave;


architecture Behavioral of spi_slave is
    type state_type is (reset, wait_for_slave_select, wait_for_idle, data_get_wait, data_get, data_set_wait, data_set, block_done);

    signal sclk_debounced       : STD_LOGIC;
    signal cur_polarity         : STD_LOGIC;
    signal cur_phase            : STD_LOGIC;
    signal cur_block_size       : Natural range 1 to 32;

    signal output_buffer_1      : STD_LOGIC_VECTOR(31 downto 0);
    signal output_buffer_2      : STD_LOGIC_VECTOR(31 downto 0);
    signal intput_buffer        : STD_LOGIC_VECTOR(31 downto 0);

    signal switch_buffer        : boolean;
    signal selected_buffer      : Natural range 0 to 1;
    signal state                : state_type := reset;

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

    -- State transition
    process(clk, rst, mosi, sclk, ss)
        variable prev_sclk  : STD_LOGIC;
        variable cur_sclk   : STD_LOGIC;
        variable cur_bit    : STD_LOGIC;
    begin
        if rst = '1' then
            state <= reset;
            cur_bit := 0;
        elsif rising_edge(clk) then
            prev_sclk := cur_sclk;
            cur_sclk := sclk_debounced;
            case state is
                when reset =>
                    state <= wait_for_slave_select;
                when wait_for_slave_select =>
                    if ss = '0' then
                        state <= wait_for_idle;
                    else
                        state <= wait_for_slave_select;
                    end if;
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
                        if phase = '0' then
                            state <= data_get_wait;
                        else
                            state <= data_set_wait;
                        end if;
                    else
                        if phase = '1' then
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
                    if phase /= polarity then
                        cur_bit := cur_bit + 1;
                        if cur_bit = cur_block_size then
                            state <= block_done;
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
                    if phase = polarity then
                        cur_bit := cur_bit + 1;
                        if cur_bit = cur_block_size then
                            state <= block_done;
                        end if;
                    end if;
                    state <= data_get_wait;
                when block_done =>
                    cur_bit := 0;
                    if phase = polarity then
                        state <= data_get_wait;
                    else
                        state <= data_set_wait;
                    end if;
            end case;
        end if;
    end process;

    -- State behaviour
    process(state, polarity, phase, blocksize, mosi)
    begin
        case state is
            when reset =>
                cur_polarity <= polarity;
                cur_phase <= phase;
                cur_block_size <= block_size;
                switch_buffer <= false;
                selected_buffer <= 0;
                input_buffer <= data_in;
            when wait_for_slave_select|wait_for_idle|data_get_wait|data_set_wait =>
                switch_buffer <= false;
            when data_get =>
                if selected_buffer = 0 then
                    output_buffer_0 = mosi & output_buffer_0(1 to output_buffer_0'size);
                else
                    output_buffer_1 = mosi & output_buffer_1(1 to output_buffer_1'size);
                end if;
            when data_set =>


        end case;
    end process;
end Behavioral;
