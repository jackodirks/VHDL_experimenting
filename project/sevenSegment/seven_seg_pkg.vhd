library IEEE;
use IEEE.std_logic_1164.all;

package seven_seg_pkg is 

    subtype seven_seg_kath_type is std_logic_vector(7 downto 0);
    -- Four bits to represent the numbers 0 - f, one more bit for the dot
    subtype digit_info_type is std_logic_vector(4 downto 0);

    function hex_to_seven_seg (
        hex_in : in digit_info_type
    ) return seven_seg_kath_type;
end seven_seg_pkg;

package body seven_seg_pkg is 
    function hex_to_seven_seg (
        hex_in : in digit_info_type
    ) return seven_seg_kath_type is 
       variable  retval : seven_seg_kath_type;
    begin
        retval :=  "11000000" when (hex_in(3 downto 0) = "0000") else
                   "11111001" when (hex_in(3 downto 0) = "0001") else
                   "10100100" when (hex_in(3 downto 0) = "0010") else
                   "10110000" when (hex_in(3 downto 0) = "0011") else
                   "10011001" when (hex_in(3 downto 0) = "0100") else
                   "10010010" when (hex_in(3 downto 0) = "0101") else
                   "10000010" when (hex_in(3 downto 0) = "0110") else
                   "11111000" when (hex_in(3 downto 0) = "0111") else
                   "10000000" when (hex_in(3 downto 0) = "1000") else
                   "10010000" when (hex_in(3 downto 0) = "1001") else
                   "10001000" when (hex_in(3 downto 0) = "1010") else
                   "10000011" when (hex_in(3 downto 0) = "1011") else
                   "11000110" when (hex_in(3 downto 0) = "1100") else
                   "10100001" when (hex_in(3 downto 0) = "1101") else
                   "10000110" when (hex_in(3 downto 0) = "1110") else
                   "10001110" when (hex_in(3 downto 0) = "1111") else
                   "00000000";
        return retval;
    end function;
end seven_seg_pkg;
