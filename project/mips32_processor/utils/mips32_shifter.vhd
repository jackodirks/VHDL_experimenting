library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_shifter is
    port (
        input : in mips32_data_type;
        cmd : in mips32_alu_cmd;
        shamt : in mips32_shamt_type;

        output : out mips32_data_type;
        active : out boolean
    );
end entity;

architecture behaviourial of mips32_shifter is
begin

    process(input, cmd, shamt)
    begin
        case cmd is
            when cmd_sll =>
                output <= std_logic_vector(shift_left(unsigned(input), shamt));
                active <= true;
            when cmd_srl =>
                output <= std_logic_vector(shift_right(unsigned(input), shamt));
                active <= true;
            when cmd_sra =>
                output <= std_logic_vector(shift_right(signed(input), shamt));
                active <= true;
            when others =>
                output <= (others => 'X');
                active <= false;
        end case;
    end process;
    
end architecture;
