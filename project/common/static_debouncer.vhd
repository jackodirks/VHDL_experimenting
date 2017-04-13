library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity static_debouncer is
    generic (
        debounce_ticks      : natural range 2 to natural'high
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
    type state_type is (reset, wait_for_begin, debounce_begin, output, wait_for_end, debounce_end);

    signal debounce_rst         : STD_LOGIC := '1';
    signal debounce_done        : STD_LOGIC;

    signal state                : state_type := reset;

begin
    debounce_ticker : simple_multishot_timer
    generic map (
        match_val    => debounce_ticks
    )
    port map (
        clk          => clk,
        rst          => debounce_rst,
        done         => debounce_done
    );

    state_selector : process(clk, rst)
    begin
        if rst = '1' then
            state <= reset;
        elsif rising_edge(clk) then
            case state is
                when reset =>
                    state <= wait_for_begin;
                when wait_for_begin =>
                    if pulse_in = '1' then
                        state <= debounce_begin;
                    else
                        state <= wait_for_begin;
                    end if;
                when debounce_begin =>
                    if debounce_done = '1' then
                        state <= output;
                    else
                        state <= debounce_begin;
                    end if;
                when output =>
                    state <= wait_for_end;
                when wait_for_end =>
                    if pulse_in = '0' then
                        state <= debounce_end;
                    else
                        state <= wait_for_end;
                    end if;
                when debounce_end =>
                    if debounce_done = '1' then
                        state <= wait_for_begin;
                    else
                        state <= debounce_end;
                    end if;
            end case;
        end if;
    end process;

    state_output : process(state)
    begin
        case state is
            when reset|wait_for_begin|wait_for_end =>
                debounce_rst    <= '1';
                pulse_out       <= '0';
            when debounce_begin|debounce_end =>
                debounce_rst    <= '0';
                pulse_out       <= '0';
            when output =>
                pulse_out       <= '1';
                debounce_rst    <= '1';
        end case;
    end process;

end behavioral;
