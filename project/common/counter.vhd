library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter is
    generic (
        match_val : integer
    );
    port (
        clk_50Mhz   : in STD_LOGIC;
        rst         : in STD_LOGIC;
        done        : out STD_LOGIC
     );
end counter;

architecture behavioral of counter is

    function check_timer_match(X : STD_LOGIC_VECTOR; Y: integer) return boolean is
    begin
        return to_integer(unsigned(X)) = Y;
    end check_timer_match;

    type wait_type is (first, second);
    signal state : wait_type := first;
    constant count_bits_count : integer := (integer(ceil(log2(real(match_val)))));
    signal timer_value : STD_LOGIC_VECTOR(count_bits_count DOWNTO 0) := (others => '0');
    begin
        process (clk_50MHZ)
        begin
            if rising_edge(clk_50MHZ) then
                if (rst = '1') then
                    timer_value <= (others => '0');
                    done <= '0';
                elsif check_timer_match(timer_value, match_val - 1) and state = first then
                    done <= '1';
                    state <= second;
                elsif check_timer_match(timer_value, match_val - 1) and state = second then
                    timer_value <= std_logic_vector(to_unsigned(1, timer_value'length));
                    done <= '1';
                    state <= first;
                else
                    timer_value <= std_logic_vector(unsigned(timer_value) + 1);
                    done <= '0';
                end if;
            end if;
        end process;
end behavioral;
