library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;

entity common_tb is
    generic (
        clock_period : time
    );
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
            debounce_ticks      : natural range 3 to natural'high
        );
        port (
            clk                 : in STD_LOGIC;
            rst                 : in STD_LOGIC;
            pulse_in            : in STD_LOGIC;
            pulse_out           : out STD_LOGIC
        );
    end component;

    component static_debouncer is
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

    signal b_to_s_p_reset                   : STD_LOGIC := '1';
    signal b_to_s_p_pulse_out               : STD_LOGIC;
    signal b_to_s_p_pulse_in                : STD_LOGIC := '0';

    signal debouncer_reset                  : STD_LOGIC := '1';
    signal debouncer_pulse_in               : STD_LOGIC;
    signal debouncer_pulse_out              : STD_LOGIC;

    signal simple_multishot_timer_rst       : STD_LOGIC := '1';
    signal simple_multishot_timer_done      : STD_LOGIC;

    signal simple_multishot_test_done       : boolean := false;
    signal data_safe_test_done              : boolean := false;
    signal b_to_s_p_test_done               : boolean := false;
    signal debouncer_test_done              : boolean := false;

    signal simple_multishot_test_success    : boolean := false;
    signal data_safe_test_success           : boolean := false;
    signal b_to_s_p_test_success            : boolean := false;
    signal debouncer_test_success            : boolean := false;

    constant simple_multishot_maxval        : natural := 10;

begin

    done <= simple_multishot_test_done and data_safe_test_done and b_to_s_p_test_done and debouncer_test_done;
    success <= simple_multishot_test_success and data_safe_test_success and b_to_s_p_test_success and debouncer_test_success;

    simple_multishot_timer_500 : simple_multishot_timer
    generic map (
        match_val => simple_multishot_maxval
    )
    port map (
        clk => clk,
        rst => simple_multishot_timer_rst,
        done => simple_multishot_timer_done
    );

    debouncer : static_debouncer
    generic map (
        debounce_ticks => 10
    )
    port map (
        clk => clk,
        rst => debouncer_reset,
        pulse_in => debouncer_pulse_in,
        pulse_out => debouncer_pulse_out
    );

    button_to_single_pulse_500 : button_to_single_pulse
    generic map (
        debounce_ticks => 500
    )
    port map (
        clk => clk,
        rst =>          b_to_s_p_reset,
        pulse_in =>     b_to_s_p_pulse_in,
        pulse_out =>    b_to_s_p_pulse_out
    );

    data_safe : data_safe_8_bit
    port map (
        clk => clk,
        rst => data_safe_8_bit_rst,
        read => data_safe_8_bit_read,
        data_in => data_safe_8_bit_data_in,
        data_out => data_safe_8_bit_data_out
    );

    debounce_tester : process
        variable suc : boolean := true;
    begin
        debouncer_pulse_in <= '0';
        debouncer_reset <= '0';
        -- Let the debouncer relax for a while
        for I in 0 to 15 loop
            wait until rising_edge(clk);
        end loop;
        if debouncer_pulse_out /= '0' then
            suc := false;
            report "debouncer failure, expected 0 got 1" severity error;
        end if;
        -- Detect normal edge change behaviour
        debouncer_pulse_in <= '1';
        for I in 0 to 15 loop
            wait until rising_edge(clk);
        end loop;
        if debouncer_pulse_out /= '1' then
            suc := false;
            report "debouncer failure, expected 1 got 0" severity error;
        end if;
        -- Weird, halfway change
        debouncer_pulse_in <= '0';
        for I in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;
        debouncer_pulse_in <= '1';
        for I in 0 to 10 loop
            wait until rising_edge(clk);
        end loop;
        if debouncer_pulse_out /= '1' then
            suc := false;
            report "debouncer failure, expected 1 got 0" severity error;
        end if;
        report "debouncer test done" severity note;
        debouncer_test_done <= true;
        debouncer_test_success <= suc;
        wait;
    end process;

    simple_multishot_tester : process
        variable suc : boolean := true;
    begin
        simple_multishot_timer_rst <= '0';
        wait until rising_edge(clk);
        for J in 0 to 5 loop
            for I in 0 to (simple_multishot_maxval-1) loop
                wait until rising_edge(clk);
            end loop;
            wait for clock_period/2;
            if simple_multishot_timer_done /= '1' then
                report "Simple multishot timer was expected to be one, but was zero" severity error;
                suc := false;
            end if;
        end loop;
        -- Check the workings of the reset
        for I in 0 to (simple_multishot_maxval/2) loop
            wait until rising_edge(clk);
        end loop;
        simple_multishot_timer_rst <= '1';
        wait for clock_period/2;
        simple_multishot_timer_rst <= '0';
        wait until rising_edge(clk);
        for J in 0 to 5 loop
            for I in 0 to (simple_multishot_maxval-1) loop
                wait until rising_edge(clk);
            end loop;
            wait for clock_period/2;
            if simple_multishot_timer_done /= '1' then
                report "Simple multishot timer was expected to be one, but was zero (after reset test)" severity error;
                suc := false;
            end if;
        end loop;
        report "Simple multishot timer finished" severity note;
        simple_multishot_test_done <= true;
        simple_multishot_test_success <= suc;
        wait;
    end process;

    button_to_single_pulse_tester : process
        variable suc : boolean := true;
    begin
        b_to_s_p_reset <= '0';
        b_to_s_p_pulse_in <= '1';
        wait for 10065 ns;
        if b_to_s_p_pulse_out /= '1' then
            report "Button to single pulse pulse_out value is zero where it should be one" severity error;
            suc := false;
        end if;
        report "Button to single pulse test done" severity note;
        b_to_s_p_test_done <= true;
        b_to_s_p_test_success <= suc;
        wait;
    end process;

    data_safe_tester : process
        variable test_data : STD_LOGIC_VECTOR(7 DOWNTO 0 ) := "01100010";
        variable suc : boolean := true;
    begin
        data_safe_8_bit_data_in <= test_data;
        data_safe_8_bit_rst <= '0';
        for I in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;
        if data_safe_8_bit_data_out /= "00000000" then
            report "data_safe_8_bit_data_out has changed to early" severity error;
            suc := false;
        end if;
        data_safe_8_bit_read <= '1';
        for I in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;
        if data_safe_8_bit_data_out /= test_data then
            report "data_safe_8_bit_data_out has not changed while this was expected" severity error;
            suc := false;
        end if;
        data_safe_8_bit_read <= '0';
        data_safe_8_bit_data_in <= "01010101";
        for I in 0 to 5 loop
            wait until rising_edge(clk);
        end loop;
        if data_safe_8_bit_data_out /= test_data then
            report "data_safe_8_bit_data_out has changed unexpected" severity error;
            suc := false;
        end if;
        report "data_safe_8_bit tests done" severity note;
        data_safe_test_done <= true;
        data_safe_test_success <= suc;
        wait;
    end process;

end Behavioral;
