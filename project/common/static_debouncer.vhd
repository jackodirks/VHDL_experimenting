library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity static_debouncer is
    generic (
        debounce_ticks      : natural range 3 to natural'high
    );
    port (
        clk                 : in STD_LOGIC;
        rst                 : in STD_LOGIC;
        pulse_in            : in STD_LOGIC;
        pulse_out           : out STD_LOGIC
    );
end static_debouncer;

architecture behavioral of static_debouncer is
    component simple_multishot_timer is
        generic (
            match_val   : natural range 1 to natural'high
        );
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;
    type state_type is (reset, wait_for_edge_change, wait_for_debounce, debounce_finished, update_output);

    signal debounce_rst         : STD_LOGIC := '1';
    signal debounce_done        : STD_LOGIC;

    signal state                : state_type := reset;
    signal read_input           : boolean;

begin
    debounce_ticker : simple_multishot_timer
    generic map (
        match_val    => debounce_ticks - 1
    )
    port map (
        clk          => clk,
        rst          => debounce_rst,
        done         => debounce_done
    );

    output_control : process(clk, read_input)
        variable output : STD_LOGIC;
    begin
        if rising_edge(clk) and read_input then
            output := pulse_in;
        end if;
        pulse_out <= output;
    end process;

    state_selector : process(clk, rst)
        variable stored_pulse_in : STD_LOGIC;
    begin
        if rst = '1' then
            state <= reset;
        elsif rising_edge(clk) then
            case state is
                when reset =>
                    stored_pulse_in := pulse_in;
                    state <= wait_for_edge_change;
                when wait_for_edge_change =>
                    if pulse_in /= stored_pulse_in then
                        stored_pulse_in := not stored_pulse_in;
                        state <= wait_for_debounce;
                    else
                        state <= wait_for_edge_change;
                    end if;
                when wait_for_debounce =>
                    if debounce_done = '1' then
                        state <=  debounce_finished;
                    else
                        state <= wait_for_debounce;
                    end if;
                when debounce_finished =>
                    if pulse_in = stored_pulse_in then
                        state <= update_output;
                    else
                        stored_pulse_in := not stored_pulse_in;
                        state <= wait_for_edge_change;
                    end if;
                when update_output =>
                    state <= wait_for_edge_change;
            end case;
        end if;
    end process;

    state_output : process(state)
    begin
        case state is
            when reset =>
                read_input <= true;
                debounce_rst <= '1';
            when wait_for_edge_change|debounce_finished =>
                read_input <= false;
                debounce_rst <= '1';
            when wait_for_debounce =>
                read_input <= false;
                debounce_rst <= '0';
            when update_output =>
                read_input <= true;
                debounce_rst <= '1';
        end case;
    end process;

end behavioral;
