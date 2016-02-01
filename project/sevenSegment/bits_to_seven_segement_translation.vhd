library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bits_to_seven_segement_translation is
    Port ( bit_input : in  STD_LOGIC_VECTOR (3 downto 0);
           ss_out : out  STD_LOGIC_VECTOR (7 downto 0));
end bits_to_seven_segement_translation;

architecture Behavioral of bits_to_seven_segement_translation is

begin
 ss_out <=  "00000011" when (bit_input = "0000") else
                    "10011111" WHEN (bit_input = "0001") else
                    "00100101" WHEN (bit_input = "0010") else
                    "00001101" WHEN (bit_input = "0011") else
                    "10011001" WHEN (bit_input = "0100") else
                    "01001001" WHEN (bit_input = "0101") else
                    "01000001" WHEN (bit_input = "0110") else
                    "00011111" WHEN (bit_input = "0111") else
                    "00000001" WHEN (bit_input = "1000") else
                    "00001001" WHEN (bit_input = "1001") else
                    "00010001" WHEN (bit_input = "1010") else
                    "11000001" WHEN (bit_input = "1011") else
                    "01100011" WHEN (bit_input = "1100") else
                    "10000101" WHEN (bit_input = "1101") else
                    "01100001" WHEN (bit_input = "1110") else
                    "01110001" WHEN (bit_input = "1111") else
                    "00000000";
end Behavioral;

