library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;

entity common_tb is
    port (
        clk : in STD_LOGIC;
        done : out boolean;
        success : out boolean
    );
end common_tb;

architecture Behavioral of common_tb is

    component simple_multishot_timer is
        generic (
            match_val : integer
        );
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;

    component data_safe_8_bit is
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            read        : in STD_LOGIC;
            data_in     : in STD_LOGIC_VECTOR(7 DOWNTO 0);
            data_out    : out STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    end component;

    component button_to_single_pulse is
        generic (
            debounce_ticks      : natural range 2 to natural'high
        );
        port (
            clk                 : in STD_LOGIC;
            rst                 : in STD_LOGIC;
            pulse_in            : in STD_LOGIC;
            pulse_out           : out STD_LOGIC
        );
    end component;

    signal data_safe_8_bit_rst              : STD_LOGIC := '1';
    signal data_safe_8_bit_read             : STD_LOGIC := '0';
    signal data_safe_8_bit_data_in          : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    signal data_safe_8_bit_data_out         : STD_LOGIC_VECTOR(7 DOWNTO 0);

    signal debouncer_reset                  : STD_LOGIC := '1';
    signal debouncer_pulse_out              : STD_LOGIC;
    signal debouncer_pulse_in               : STD_LOGIC := '0';

    signal simple_multishot_timer_rst       : STD_LOGIC := '1';
    signal simple_multishot_timer_done      : STD_LOGIC;
    signal simple_multishot_timer_cur_val   : STD_LOGIC_VECTOR(6 DOWNTO 0);

    signal simple_multishot_test_done       : boolean := true;
    signal data_safe_test_done              : boolean := false;
    signal debouncer_test_done              : boolean := false;

    signal simple_multishot_test_success    : boolean := true;
    signal data_safe_test_success           : boolean := false;
    signal debouncer_test_success           : boolean := false;

begin

    done <= simple_multishot_test_done and data_safe_test_done and debouncer_test_done;
    success <= simple_multishot_test_success and data_safe_test_success and debouncer_test_success;

    simple_multishot_timer_500 : simple_multishot_timer
    generic map (
        match_val => 10
    )
    port map (
        clk => clk,
        rst => simple_multishot_timer_rst,
        done => simple_multishot_timer_done
    );

    debounce_tester : button_to_single_pulse
    generic map (
        debounce_ticks => 500
    )
    port map (
        clk => clk,
        rst => debouncer_reset,
        pulse_in => debouncer_pulse_in,
        pulse_out => debouncer_pulse_out
    );

    data_safe : data_safe_8_bit
    port map (
        clk => clk,
        rst => data_safe_8_bit_rst,
        read => data_safe_8_bit_read,
        data_in => data_safe_8_bit_data_in,
        data_out => data_safe_8_bit_data_out
    );

    debouncer_tester : process
        variable suc : boolean := true;
    begin
        debouncer_reset <= '0';
        debouncer_pulse_in <= '1';
        wait for 10065 ns;
        if debouncer_pulse_out /= '1' then
            report "Debouncer value is zero where it should be one" severity error;
            suc := false;
        end if;
        report "Debouncer test done" severity note;
        debouncer_test_done <= true;
        debouncer_test_success <= suc;
        wait;
    end process;

    data_safe_tester : process
        variable test_data : STD_LOGIC_VECTOR(7 DOWNTO 0 ) := "01100010";
        variable suc : boolean := true;
    begin
        data_safe_8_bit_data_in <= test_data;
        data_safe_8_bit_rst <= '0';
        wait for 100 ns;
        if data_safe_8_bit_data_out /= "00000000" then
            report "data_safe_8_bit_data_out has changed to early" severity error;
            suc := false;
        end if;
        data_safe_8_bit_read <= '1';
        wait for 100 ns;
        if data_safe_8_bit_data_out /= test_data then
            report "data_safe_8_bit_data_out has not changed while this was expected" severity error;
            suc := false;
        end if;
        data_safe_8_bit_read <= '0';
        data_safe_8_bit_data_in <= "01010101";
        wait for 100 ns;
        if data_safe_8_bit_data_out /= test_data then
            report "data_safe_8_bit_data_out has changed unexpected" severity error;
            suc := false;
        end if;
        report "data_safe_8_bit tests done" severity note;
        data_safe_test_done <= true;
        data_safe_test_success <= suc;
        wait;
    end process;

-- TODO: testbench for simple_multishot_timer
end Behavioral;
