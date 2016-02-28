library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bits_to_seven_segement_translation is
    Port (
        bit_input : in  STD_LOGIC_VECTOR (3 downto 0);
        ss_out : out  STD_LOGIC_VECTOR (7 downto 0)
    );
end bits_to_seven_segement_translation;

architecture Behavioral of bits_to_seven_segement_translation is

begin
    ss_out <=  "11000000" when (bit_input = "0000") else
               "11111001" when (bit_input = "0001") else
               "10100100" when (bit_input = "0010") else
               "10110000" when (bit_input = "0011") else
               "10011001" when (bit_input = "0100") else
               "10010010" when (bit_input = "0101") else
               "10000010" when (bit_input = "0110") else
               "11111000" when (bit_input = "0111") else
               "10000000" when (bit_input = "1000") else
               "10010000" when (bit_input = "1001") else
               "10001000" when (bit_input = "1010") else
               "10000011" when (bit_input = "1011") else
               "11000110" when (bit_input = "1100") else
               "10100001" when (bit_input = "1101") else
               "10000110" when (bit_input = "1110") else
               "10001110" when (bit_input = "1111") else
               "00000000";
end Behavioral;

