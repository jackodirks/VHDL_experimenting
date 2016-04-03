library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity data_safe_8_bit is
    port (
        clk         : in STD_LOGIC;
        rst         : in STD_LOGIC;
        read        : in STD_LOGIC;
        data_in     : in STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_out    : out STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
end data_safe_8_bit;


architecture behavioral of data_safe_8_bit is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            if (read = '1') then
                data_out <= data_in;
            end if;
        end if;
    end process;
end behavioral;
