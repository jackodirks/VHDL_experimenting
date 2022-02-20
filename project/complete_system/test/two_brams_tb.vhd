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
use src.depp_pkg.all;

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
        variable bus_address : bus_address_type := (others => '0');
        variable bus_writeData : bus_data_type := (others => '0');
        variable bus_readData : bus_data_type := (others => '0');

        variable depp_address : depp_address_type := (others => '0');
        variable depp_data : depp_data_type := (others => '0');
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Write then read") then
                -- Set both fast read and fast write
                depp_data(depp_mode_fast_write_bit) := '1';
                depp_data(depp_mode_fast_read_bit) := '1';
                depp_address := std_logic_vector(to_unsigned(depp2bus_mode_register_start, depp_address'length));
                depp_tb_depp_write_to_address (
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => depp_address,
                    data => depp_data
                );
                -- Set the bus address to all zeros
                depp_tb_bus_set_address (
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    address => bus_address
                );
                -- Set the writemask to all 1
                depp_address := std_logic_vector(to_unsigned(depp2bus_write_mask_reg_start, depp_address'length));
                depp_data := (others => '1');
                depp_tb_depp_write_to_address (
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => depp_address,
                    data => depp_data
                );
                -- Set the depp address to writeData start
                depp_address := std_logic_vector(to_unsigned(depp2bus_writeData_reg_start, depp_address'length));
                depp_tb_depp_set_address (
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => depp_address
                );
                -- Start with writing
                for i in 0 to 1023 loop
                    bus_writeData := std_logic_vector(to_unsigned(i, bus_writeData'length));
                    for j in 0 to 3 loop
                        depp_tb_depp_set_data (
                            clk => clk,
                            usb_db => usb_db,
                            usb_write => usb_write,
                            usb_astb => usb_astb,
                            usb_dstb => usb_dstb,
                            usb_wait => usb_wait,
                            data => bus_writeData((j+1)*8 - 1 downto j*8),
                            expect_completion => true
                        );
                    end loop;
                end loop;
                -- Set the bus address to all zeros
                bus_address := (others => '0');
                depp_tb_bus_set_address (
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    address => bus_address
                );
                -- Set the depp address to readData_start
                depp_address := std_logic_vector(to_unsigned(depp2bus_readData_reg_start, depp_address'length));
                depp_tb_depp_set_address (
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => depp_address
                );
                -- Now read it back
                for i in 0 to 1023 loop
                    for j in 0 to 3 loop
                        depp_tb_depp_get_data (
                            clk => clk,
                            usb_db => usb_db,
                            usb_write => usb_write,
                            usb_astb => usb_astb,
                            usb_dstb => usb_dstb,
                            usb_wait => usb_wait,
                            data => bus_readData((j+1)*8 - 1 downto j*8),
                            expect_completion => true
                        );
                    end loop;
                    check_equal(to_integer(unsigned(bus_readData)), i);
                end loop;
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
