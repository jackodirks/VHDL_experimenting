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

    --constant count_bits_count : integer := (integer(ceil(log2(real(match_val)))));
    constant count_bits_count : integer := 12;
    signal timer_value : STD_LOGIC_VECTOR(count_bits_count DOWNTO 0);
    begin
        process (clk_50MHZ)
        begin
            if rising_edge(clk_50MHZ) then
                if (rst = '1') then
                    timer_value <= (others => '0');
                    done <= '0';
                elsif timer_value = std_logic_vector(to_unsigned(match_val, count_bits_count)) then
                    assert false report "dingen" severity note;
                    done <= '1';
                    timer_value <= (others => '0');
                else
                    timer_value <= std_logic_vector(unsigned(timer_value) + 1);
                    done <= '0';
                end if;
            end if;
        end process;
end behavioral;
