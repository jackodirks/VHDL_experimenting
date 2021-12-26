library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

package seven_seg_pkg is

    subtype seven_seg_kath_type is std_logic_vector(7 downto 0);
    -- Four bits to represent the numbers 0 - f, one more bit for the dot
    subtype digit_info_type is std_logic_vector(4 downto 0);

    function hex_to_seven_seg (
        hex_in : digit_info_type
    ) return seven_seg_kath_type;
end seven_seg_pkg;

package body seven_seg_pkg is
    function hex_to_seven_seg (
        hex_in : digit_info_type
    ) return seven_seg_kath_type is
       variable  retval : seven_seg_kath_type;
       variable input : natural range 0 to 15;
    begin
        input := to_integer(unsigned(hex_in(3 downto 0)));
        case input is
            when 16#0# =>
                retval := "11000000";
            when 16#1# =>
                retval := "11111001";
            when 16#2# =>
                retval := "10100100";
            when 16#3# =>
                retval := "10110000";
            when 16#4# =>
                retval := "10011001";
            when 16#5# =>
                retval := "10010010";
            when 16#6# =>
                retval := "10000010";
            when 16#7# =>
                retval := "11111000";
            when 16#8# =>
                retval := "10000000";
            when 16#9# =>
                retval := "10010000";
            when 16#a# =>
                retval := "10001000";
            when 16#b# =>
                retval := "10000011";
            when 16#c# =>
                retval := "11000110";
            when 16#d# =>
                retval := "10100001";
            when 16#e# =>
                retval := "10000110";
            when 16#f# =>
                retval := "10001110";
            when others =>
                retval := "00000000";
        end case;

        if hex_in(digit_info_type'high) = '1' then
            retval(seven_seg_kath_type'high) := '0';
        end if;

        return retval;
    end function;
end seven_seg_pkg;
