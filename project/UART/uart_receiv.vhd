library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Handles the incoming data.

entity uart_receiv is
    generic (
        baudrate                : Natural;
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
        data_error              : out STD_LOGIC                     -- Signals that data receiving has encoutered errors
    );
end uart_receiv;

