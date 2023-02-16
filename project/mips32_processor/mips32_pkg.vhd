library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package mips32_pkg is
    constant address_width_log2b : natural := 5;
    constant data_width_log2b : natural := 5;
    constant instruction_width_log2b : natural := 5;

    subtype address_type is std_logic_vector(2**address_width_log2b - 1 downto  0);
    subtype data_type is std_logic_vector(2**data_width_log2b -1 downto 0);
    subtype instruction_type is std_logic_vector(2**instruction_width_log2b - 1 downto 0);

    -- To begin, this processor will support the following instructions:
    -- lw, sw, beq, add, sub, and, or, set on less than
    -- The nop, for now, will be and $0 $0 $0
    constant instructionNop : instruction_type := X"00000024";
end package;
