library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;
use IEEE.NUMERIC_STD.ALL;

entity simple_multishot_timer is
    generic (
        match_val   : natural range 1 to natural'high
    );
    port (
        clk         : in STD_LOGIC;
        rst         : in STD_LOGIC;
        done        : out STD_LOGIC
    );
end simple_multishot_timer;

architecture behavioral of simple_multishot_timer is
    function check_timer_match(X : UNSIGNED; Y: natural) return boolean is
    begin
        return to_integer(X) = Y;
    end check_timer_match;

    constant count_bits_count : integer := (integer(ceil(log2(real(match_val)))));
    signal timer_value : UNSIGNED(count_bits_count DOWNTO 0) := (others => '0');
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                timer_value <= to_unsigned(0, timer_value'length);
                done <= '0';
            elsif check_timer_match(timer_value, match_val) then
                done <= '1';
                timer_value <= to_unsigned(1, timer_value'length);
            else
                timer_value <= timer_value + 1;
                done <= '0';
            end if;
        end if;
    end process;
end behavioral;
