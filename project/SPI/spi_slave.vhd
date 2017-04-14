library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- A change of polarity, phase and block size will only be accepted in the reset state: changing them during run will not affect anything

-- The data on the receive block will be stable for a couple of cycles. All other blocks are not guaranteed to be stable.
-- The receive_block starts at receive_block*block_size.

-- Whatch out with the data_in buffer: it is possible that the last bits will never be read because they are not part of a block;
-- For example, the block size 13 will never read the last 10 bits.

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
        data_in                 : in    STD_LOGIC_VECTOR(127 DOWNTO 0);     -- Data to be transmitted
        data_out                : out   STD_LOGIC_VECTOR(127 DOWNTO 0);     -- Data that has been received
        block_size              : in    Natural range 1 to 32;              -- Data block size
        receive_block           : out   Natural range 0 to 127;             -- Last written block
        transmit_block          : in    Natural range 0 to 127;             -- Block currently being read
        transmit_done           : out   STD_LOGIC;                          -- Signals that a full block was just transmitted
        receive_done            : out   STD_LOGIC                           -- Signals that data has been received.
    );
end spi_slave;


architecture Behavioral of spi_slave is
    type state_type is (reset, wait_for_slave_select, wait_for_idle, data_get, data_set, block_done);

    signal sclk_debounced       : STD_LOGIC;
    signal cur_polarity         : STD_LOGIC;
    signal cur_phase            : STD_LOGIC;
    signal cur_block_size       : Natural range 1 to 32;

    signal cur_read_block       : Natural range 0 to 127;
    signal cur_write_block      : Natural range 0 to 127;
    signal cur_read_address     : Natural range 0 to 127;
    signal cur_write_address    : Natural range 0 to 127;

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
        variable last_known_sclk : STD_LOGIC;
    begin
        if rst = '1' then
            state <= reset;
        elsif rising_edge(clk) then
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
                    if cur_polarity /= sclk then
                        state <= wait_for_idle;
                    elsif cur_polarity = '0' then
                        if phase = '0' then
                            state <= data_get;
                        else
                            state <= data_set;
                        end if;
                    else
                        if phase = '1' then
                            state <= data_get;
                        else
                            state <= data_set;
                        end if;
                    end if;
            end case;
        end if;
    end process;

    -- State behaviour
    process(state, polarity, phase, blocksize)
    begin
        case state is
            when reset =>
                cur_polarity <= polarity;
                cur_phase <= phase;
                cur_block_size <= block_size;
        end case;
    end process;
end Behavioral;
