library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity static_debouncer is
    generic (
        debounce_ticks      : natural range 1 to natural'high
    );
    port (
        clk                 : in STD_LOGIC;
        pulse_in            : in STD_LOGIC;
        pulse_out           : out STD_LOGIC
    );
end static_debouncer;

architecture behavioral of static_debouncer is
    type state_type is (start, wait_for_edge_change, wait_for_debounce);

    signal state                : state_type := start;
    signal read_input           : boolean;

    signal counter_rst          : boolean;
    signal counter_run          : boolean;
    signal counter_done         : boolean;

    signal output_signal        : std_logic;
    signal cur_different        : boolean;
    signal difference_detected  : boolean;
    signal detector_rst         : boolean;

begin
    cur_different <= output_signal /= pulse_in;
    pulse_out <= output_signal;

    difference_detector : process(cur_different, detector_rst)
        variable d : boolean;
    begin
        if detector_rst then
            d := false;
        elsif cur_different then
            d := true;
        end if;
        difference_detected <= d;
    end process;

    rising_edge_counter : process(clk, counter_rst, counter_run)
        variable cur_count : natural range 0 to natural'high;
        variable count_done : boolean;
    begin
        if counter_rst then
            cur_count := 0;
            count_done := false;
        elsif rising_edge(clk) and counter_run then
            cur_count := cur_count + 1;
        end if;

        if cur_count = (debounce_ticks - 1) then
            count_done := true;
        end if;
        counter_done <= count_done;
    end process;

    output_control : process(clk, read_input)
        variable cur_output : std_logic;
    begin
        if rising_edge(clk) and read_input then
            cur_output := pulse_in;
        end if;
        output_signal <= cur_output;
    end process;

    state_selector : process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when start =>
                    state <= wait_for_edge_change;
                when wait_for_edge_change =>
                    if difference_detected then
                        state <= wait_for_debounce;
                    else
                        state <= wait_for_edge_change;
                    end if;
                when wait_for_debounce =>
                    if counter_done then
                        state <= wait_for_edge_change;
                    else
                        state <= wait_for_debounce;
                    end if;
            end case;
        end if;
    end process;

    state_output : process(state, counter_done, cur_different)
    begin
        case state is
            when start =>
                read_input <= true;
                counter_rst <= true;
                counter_run <= false;
                detector_rst <= true;
            when wait_for_edge_change =>
                read_input <= false;
                counter_rst <= true;
                counter_run <= false;
                detector_rst <= false;
            when wait_for_debounce =>
                if (counter_done and cur_different) then
                    read_input <= true;
                else
                    read_input <= false;
                end if;
                counter_rst <= false;
                counter_run <= true;
                detector_rst <= true;
        end case;
    end process;

end behavioral;
