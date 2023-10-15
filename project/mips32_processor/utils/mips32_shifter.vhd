library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_shifter is
    port (
        input : in mips32_data_type;
        cmd : in mips32_shift_cmd;
        shamt : in mips32_shamt_type;

        output : out mips32_data_type
    );
end entity;

architecture behaviourial of mips32_shifter is
begin

    process(input, cmd, shamt)
    begin
        case cmd is
            when cmd_shift_sll =>
                output <= std_logic_vector(shift_left(unsigned(input), shamt));
            when cmd_shift_srl =>
                output <= std_logic_vector(shift_right(unsigned(input), shamt));
            when cmd_shift_sra =>
                output <= std_logic_vector(shift_right(signed(input), shamt));
        end case;
    end process;
end architecture;
