library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library tb;
use tb.bus_tb_pkg.all;
use tb.depp_tb_pkg.all;

library src;
use src.bus_pkg.all;

entity two_brams_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of two_brams_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal usb_db : std_logic_vector(7 downto 0);
    signal usb_write : std_logic;
    signal usb_astb : std_logic;
    signal usb_dstb : std_logic;
    signal usb_wait : std_logic;

    signal addr : bus_address_type;
    signal data : bus_data_type;
    signal wMask : bus_write_mask;
begin

    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("sanity") then
                addr <= std_logic_vector(to_unsigned(1024, addr'length));
                data <= (others => '0');
                wMask <= (others => '0');
                depp_tb_single_write(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => addr,
                    data => data,
                    wMask => wMask
                );
            end if;
        end loop;

        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 1 ms);


    two_brams_system : entity src.two_brams
    port map (
        clk_50mhz => clk,
        usb_db => usb_db,
        usb_write => usb_write,
        usb_astb => usb_astb,
        usb_dstb => usb_dstb,
        usb_wait => usb_wait
    );
end architecture;
