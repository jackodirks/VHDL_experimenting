library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg;

entity mips32_coprocessor_zero is
    port (
        clk : in std_logic;
        rst : in std_logic;

        address_from_controller : in natural range 0 to 31;
        address_from_pipeline : in natural range 0 to 31;

        write_from_controller : in boolean;
        write_from_pipeline : in boolean;

        data_from_controller : in mips32_pkg.mips32_data_type;
        data_from_pipeline : in mips32_pkg.mips32_data_type;

        data_to_controller : out mips32_pkg.mips32_data_type;
        data_to_pipeline : out mips32_pkg.mips32_data_type;

        cpu_reset : out boolean;
        cpu_stall : out boolean
    );
end entity;

architecture behaviourial of mips32_coprocessor_zero is
begin
    process(clk, address_from_controller, address_from_pipeline)
        variable regZero_buf : mips32_pkg.mips32_data_type := (0 => '1', others => '0');
    begin

        if address_from_pipeline = 0 then
            data_to_pipeline <= regZero_buf;
        else
            data_to_pipeline <= (others => '0');
        end if;

        if address_from_controller = 0 then
            data_to_controller <= regZero_buf;
        else
            data_to_controller <= (others => '0');
        end if;

        if rising_edge(clk) then
            if rst = '1' then
                regZero_buf := (0 => '1', others => '0');
            else
                if write_from_pipeline and address_from_pipeline = 0 then
                    regZero_buf := data_from_pipeline;
                end if;

                if  write_from_controller and address_from_controller = 0 then
                    regZero_buf := data_from_controller;
                end if;
            end if;
        end if;
        regZero_buf(31 downto 2) := (others => '0');
        cpu_reset <= regZero_buf(0) = '1';
        cpu_stall <= regZero_buf(1) = '1';
    end process;


end architecture;
