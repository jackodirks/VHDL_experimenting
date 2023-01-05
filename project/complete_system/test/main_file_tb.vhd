library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library tb;
use tb.depp_master_simulation_pkg;

library src;
use src.bus_pkg.all;

entity main_file_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of main_file_tb is
    constant clk_period : time := 20 ns;
    signal clk : std_logic := '0';
    -- Depp
    signal usb_db : std_logic_vector(7 downto 0) := (others => 'Z');
    signal usb_write : std_logic := '1';
    signal usb_astb : std_logic := '1';
    signal usb_dstb : std_logic := '1';
    signal usb_wait : std_logic;
    -- SPI mem
    signal cs_n : std_logic_vector(2 downto 0);
    signal so_sio1 : std_logic;
    signal sio2 : std_logic;
    signal hold_n_sio3 : std_logic;
    signal sck : std_logic;
    signal si_sio0 : std_logic;
    -- Seven segment display
    signal seven_segment_an : std_logic_vector(3 downto 0);
    signal seven_segment_kath : std_logic_vector(7 downto 0);
    -- Slide switches
    signal slide_switch : std_logic_vector(7 downto 0) := (others => '0');
    -- Leds
    signal led : std_logic_vector(7 downto 0);
begin
    clk <= not clk after (clk_period/2);
    process
        constant bram_start_address : bus_address_type := std_logic_vector(to_unsigned(16#1000#, bus_address_type'length));
        constant spimem0_start_address : bus_address_type := std_logic_vector(to_unsigned(16#100000#, bus_address_type'length));
        constant spimem1_start_address : bus_address_type := std_logic_vector(to_unsigned(16#120000#, bus_address_type'length));
        constant spimem2_start_address : bus_address_type := std_logic_vector(to_unsigned(16#140000#, bus_address_type'length));

        variable write_mask : bus_write_mask := (others => '1');

        variable bram_test_input_data : bus_data_array(15 downto 0);
        variable bram_test_output_data : bus_data_array(15 downto 0);

        variable spimem0_test_input_data : bus_data_array(15 downto 0);
        variable spimem0_test_output_data : bus_data_array(15 downto 0);
        variable spimem1_test_input_data : bus_data_array(15 downto 0);
        variable spimem1_test_output_data : bus_data_array(15 downto 0);
        variable spimem2_test_input_data : bus_data_array(15 downto 0);
        variable spimem2_test_output_data : bus_data_array(15 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Bram is usable") then
                for i in 0 to bram_test_input_data'high loop
                    bram_test_input_data(i) := std_logic_vector(to_unsigned(i, bram_test_input_data(i)'length));
                end loop;
                depp_master_simulation_pkg.write_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => bram_start_address,
                    writeMask => write_mask,
                    data => bram_test_input_data
                );
                depp_master_simulation_pkg.read_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => bram_start_address,
                    data => bram_test_output_data
                );
                for i in 0 to bram_test_input_data'high loop
                    check_equal(bram_test_output_data(i), bram_test_input_data(i));
                end loop;
            elsif run("Spi mem is usable") then
                for i in 0 to spimem0_test_input_data'high loop
                    spimem0_test_input_data(i) := std_logic_vector(to_unsigned(i, bram_test_input_data(i)'length));
                end loop;
                for i in 0 to spimem1_test_input_data'high loop
                    spimem1_test_input_data(i) := std_logic_vector(to_unsigned(i + 255, bram_test_input_data(i)'length));
                end loop;
                for i in 0 to spimem2_test_input_data'high loop
                    spimem2_test_input_data(i) := std_logic_vector(to_unsigned(i + 1024, bram_test_input_data(i)'length));
                end loop;
                depp_master_simulation_pkg.write_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => spimem0_start_address,
                    writeMask => write_mask,
                    data => spimem0_test_input_data
                );
                depp_master_simulation_pkg.write_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => spimem1_start_address,
                    writeMask => write_mask,
                    data => spimem1_test_input_data
                );
                depp_master_simulation_pkg.write_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => spimem2_start_address,
                    writeMask => write_mask,
                    data => spimem2_test_input_data
                );
                depp_master_simulation_pkg.read_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => spimem0_start_address,
                    data => spimem0_test_output_data
                );
                depp_master_simulation_pkg.read_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => spimem1_start_address,
                    data => spimem1_test_output_data
                );
                depp_master_simulation_pkg.read_busWord_array(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    addr => spimem2_start_address,
                    data => spimem2_test_output_data
                );
                for i in 0 to spimem0_test_input_data'high loop
                    check_equal(spimem0_test_input_data(i), spimem0_test_input_data(i));
                end loop;
                for i in 0 to spimem1_test_input_data'high loop
                    check_equal(spimem1_test_input_data(i), spimem1_test_input_data(i));
                end loop;
                for i in 0 to spimem2_test_input_data'high loop
                    check_equal(spimem2_test_input_data(i), spimem2_test_input_data(i));
                end loop;
            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    mem_pcb : entity tb.triple_M23LC1024
    port map (
        cs_n => cs_n,
        so_sio1 => so_sio1,
        sio2 => sio2,
        hold_n_sio3 => hold_n_sio3,
        sck => sck,
        si_sio0 => si_sio0
    );

    main_file : entity src.main_file
    port map (
        JA_gpio(0) => si_sio0,
        JA_gpio(1) => so_sio1,
        JA_gpio(2) => sio2,
        JA_gpio(3) => hold_n_sio3,
        JB_gpio(3 downto 1) => cs_n,
        JB_gpio(0) => sck,
        slide_switch => slide_switch,
        led => led,
        seven_seg_kath => seven_segment_kath,
        seven_seg_an => seven_segment_an,
        clk => clk,
        usb_db => usb_db,
        usb_write => usb_write,
        usb_astb => usb_astb,
        usb_dstb => usb_dstb,
        usb_wait => usb_wait
    );
end architecture;
