library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- A note about parity:
-- 0: odd parity
-- 1: even parity
-- 2: always 0 parity
-- 3: always 1 parity
-- if parity_bit is false, this parameter is ignored

entity uart_main is
    generic (
        clk_freq                : Natural;
        baudrate                : Natural;
        parity_bit_en           : boolean;
        parity_bit_type         : integer range 0 to 3;
        bit_count               : integer range 5 to 9;
        stop_bits_count         : integer range 1 to 2
    );
    Port (
        rst                     : in STD_LOGIC;
        clk                     : in STD_LOGIC;
        uart_rx                 : in STD_LOGIC;
        uart_tx                 : out STD_LOGIC;
        send_start              : in STD_LOGIC;
        data_in                 : in STD_LOGIC_VECTOR(8 DOWNTO 0);
        data_out                : out STD_LOGIC_VECTOR(8 DOWNTO 0);
        data_ready              : out STD_LOGIC;
        data_error              : out STD_LOGIC;
        parity_error            : out STD_LOGIC;
        send_ready              : out STD_LOGIC
    );
end uart_main;

architecture Behavioral of uart_main is
begin
    transmitter : entity work.uart_transmit
    generic map (
        baudrate            => baudrate,
        clk_freq            => clk_freq,
        parity_bit_en       => parity_bit_en,
        parity_bit_type     => parity_bit_type,
        bit_count           => bit_count,
        stop_bits           => stop_bits_count
    )
    port map (
        rst                 => rst,
        clk                 => clk,
        uart_tx             => uart_tx,
        data_in             => data_in,
        data_send_start     => send_start,
        ready               => send_ready
    );

    receiver : entity work.uart_receiv
    generic map (
        baudrate            => baudrate,
        clk_freq            => clk_freq,
        parity_bit_in       => parity_bit_en,
        parity_bit_in_type  => parity_bit_type,
        bit_count_in        => bit_count,
        stop_bits_in        => stop_bits_count
    )
    port map (
        rst                 => rst,
        clk                 => clk,
        uart_rx             => uart_rx,
        received_data       => data_out,
        data_ready          => data_ready,
        parity_error        => parity_error,
        data_error          => data_error
    );
end Behavioral;
