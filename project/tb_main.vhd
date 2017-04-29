library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use std.textio.ALL;
use IEEE.MATH_REAL.ALL;


entity tb_main is
    generic ( SEED : natural);
end tb_main;

architecture tb of tb_main is
    -- Constant declaration --
    constant clock_period                   : time := 20 ns;    -- Please make sure this number is divisible by 2.

    -- Signal declaration --
    signal clk                              : STD_LOGIC := '0';

    signal seven_segments_done              : boolean := true;
    signal seven_segments_success           : boolean := true;

    signal common_done                      : boolean := true;
    signal common_success                   : boolean := true;

    signal uart_success                     : boolean := true;
    signal uart_done                        : boolean := true;

    signal spi_success                      : boolean := true;
    signal spi_done                         : boolean := true;

    constant run_seven_segments_test        : boolean := true;
    constant run_common_test                : boolean := true;
    constant run_uart_test                  : boolean := true;
    constant run_spi_test                   : boolean := true;

    signal randVal                          : natural := 0;
begin
    seven_segments_generate:
    if run_seven_segments_test generate
        seven_segments_test : entity work.seven_segments_tb
        generic map (
            clock_period => clock_period
        )
        port map (
            clk => clk,
            done => seven_segments_done,
            success => seven_segments_success
        );
    end generate seven_segments_generate;

    common_generate:
    if run_common_test generate
        common_test : entity work.common_tb
        generic map (
            clock_period => clock_period
        )
        port map (
            clk => clk,
            done => common_done,
            success => common_success
        );
    end generate common_generate;

    uart_generate:
    if run_uart_test generate
        uart_test : entity work.uart_tb
        generic map (
            clock_period => clock_period,
            randVal => randVal
        )
        port map (
            clk => clk,
            done => uart_done,
            success => uart_success
        );
    end generate uart_generate;

    spi_generate:
    if run_spi_test generate
        spi_test : entity work.spi_tb
        generic map (
            clock_period => clock_period,
            randVal => randVal
        )
        port map (
            clk => clk,
            done => spi_done,
            success => spi_success
        );
    end generate spi_generate;

    rand_gen : process
    begin
        wait for 20 ns;
        randVal <= SEED rem 256;
        wait for 20 ns;
        report "Seed is " & integer'image(SEED) severity note;
        report "randVal is " & integer'image(randVal) severity note;
        wait;
    end process;

    clock_gen : process
    begin
        if not (common_done and seven_segments_done and uart_done and spi_done) then
            -- 1/2 duty cycle
            clk <= not clk;
            wait for clock_period/2;
        else
            wait;
        end if;
    end process;

end tb;
