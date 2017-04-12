library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- A change of polarity, phase and block size will only be accepted in the reset state: changing them during run will not affect anything

-- The data on the receive block will be stable for a couple of cycles. All other blocks are not guaranteed to be stable.
-- The receive_block starts at receive_block*block_size.

-- Whatch out with the data_in buffer: it is possible that the last bits will never be read because they are not part of a block;
-- For example, the block size 13 will never read the last 10 bits.

entity spi_slave is
    port (
        rst                     : in    STD_LOGIC;
        clk                     : in    STD_LOGIC;
        polarity                : in    STD_LOGIC;                          -- Polarity, CPOL
        phase                   : in    STD_LOGIC;                          -- Phase, CPHA
        sclk                    : in    STD_LOGIC;                          -- Serial clock
        mosi                    : in    STD_LOGIC;                          -- Master output slave input
        miso                    : out   STD_LOGIC;                          -- Master input slave output
        data_in                 : in    STD_LOGIC_VECTOR(127 DOWNTO 0);     -- Data to be transmitted
        data_out                : out   STD_LOGIC_VECTOR(127 DOWNTO 0);     -- Data that has been received
        block_size              : in    Natural range 1 to 32;              -- Data block size
        receive_block           : out   Natural range 0 to 127;             -- Last written block
        transmit_block          : out   Natural range 0 to 127;             -- Block currently being read
        transmit_done           : out   STD_LOGIC;                          -- Signals that a full block was just transmitted
        receive_done            : out   STD_LOGIC                           -- Signals that data has been received.
    );
end uart_receiv;


architecture Behavioral of spi_slave is
begin
end Behavioral;
