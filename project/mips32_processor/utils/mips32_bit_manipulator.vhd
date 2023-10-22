library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_bit_manipulator is
    port (
        rs : in mips32_data_type;
        rt : in mips32_data_type;
        msb : in natural range 0 to 31;
        lsb : in natural range 0 to 31;
        cmd : in mips32_bit_manipulator_cmd;

        output : out mips32_data_type
    );
end entity;

architecture behaviourial of mips32_bit_manipulator is
    pure function extract (
        data : mips32_data_type;
        pos : in natural range 0 to 31;
        size : in natural range 0 to 31
    ) return mips32_data_type is
        variable retval : mips32_data_type := (others => '0');
        constant input_size : natural range 0 to 31 := pos + size;
    begin
        retval(size downto 0) := data(input_size downto pos);
        return retval;
    end function;

    pure function insert (
        output_prototype : mips32_data_type;
        input : mips32_data_type;
        pos_high : in natural range 0 to 31;
        pos_low : in natural range 0 to 31
    ) return mips32_data_type is
        constant input_size : natural range 0 to 31 := pos_high - pos_low;
        variable retval : mips32_data_type := output_prototype;
    begin
        retval(pos_high downto pos_low) := input(input_size downto 0);
        return retval;
    end function;

begin
    process(rs, rt, msb, lsb, cmd)
    begin
        case cmd is
            when cmd_bit_manip_ext =>
                if lsb + msb > 31 then
                    output <= (others => 'X');
                else
                    output <= extract(rs, lsb, msb);
                end if;
            when cmd_bit_manip_ins =>
                if lsb > msb then
                    output <= (others => 'X');
                else
                    output <= insert(rt, rs, msb, lsb);
                end if;
        end case;
    end process;
end architecture;
