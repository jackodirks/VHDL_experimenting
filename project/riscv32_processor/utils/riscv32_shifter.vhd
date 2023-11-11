library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.riscv32_pkg.all;

entity riscv32_shifter is
    port (
        input : in riscv32_data_type;
        cmd : in riscv32_shift_cmd;
        shamt : in riscv32_shamt_type;

        output : out riscv32_data_type
    );
end entity;

architecture behaviourial of riscv32_shifter is
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
