library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

package triple_23lc1024_pkg is
    pure function reorder_nibbles (
        word_in : bus_data_type
    ) return bus_data_type;

    pure function is_address_legal_for_burst (
        address : bus_address_type
    ) return boolean;

end triple_23lc1024_pkg;

package body triple_23lc1024_pkg is
    pure function reorder_nibbles (
        word_in : bus_data_type
    ) return bus_data_type is
    variable ret_val : bus_data_type;
    constant nibble_size : natural := bus_byte_size/2;
    begin
        for i in 0 to bus_bytes_per_word - 1 loop
           ret_val(nibble_size + i*bus_byte_size - 1 downto i*bus_byte_size) := word_in((i + 1)*bus_byte_size - 1 downto (i + 1)*bus_byte_size - nibble_size);
           ret_val((i + 1)*bus_byte_size - 1 downto (i + 1)*bus_byte_size - nibble_size) := word_in(nibble_size + i*bus_byte_size - 1 downto i*bus_byte_size);
        end loop;
        return ret_val;
    end reorder_nibbles;

    pure function is_address_legal_for_burst (
        address : bus_address_type
    ) return boolean is
        constant addr_num : natural := to_integer(unsigned(address));
        variable new_addr : natural := addr_num + bus_bytes_per_word;
        constant mask : natural := 16#1ffff#;
    begin
        return (addr_num mod mask) < (new_addr mod mask);
    end is_address_legal_for_burst;

end triple_23lc1024_pkg;
