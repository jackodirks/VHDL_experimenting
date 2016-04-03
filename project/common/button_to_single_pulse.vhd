library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity button_to_single_pulse is
    generic (
        debounce_ticks      : natural range 2 to natural'high
    );
    port (
        clk                 : in STD_LOGIC;
        rst                 : in STD_LOGIC;
        pulse_in            : in STD_LOGIC;
        pulse_out           : out STD_LOGIC
    );
end button_to_single_pulse;
