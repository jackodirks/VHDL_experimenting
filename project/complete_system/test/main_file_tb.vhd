library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library tb;
use tb.simulated_depp_master_pkg;

library src;
use src.bus_pkg.all;

entity main_file_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of main_file_tb is
    constant clk_period : time := 20 ns;
    constant deppMasterActor : actor_t := new_actor("Depp Master");
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
    -- Button
    signal push_button : std_logic := '0';
begin
    clk <= not clk after (clk_period/2);
    process
        constant processor_controller_start_address : bus_address_type := std_logic_vector(to_unsigned(16#2000#, bus_address_type'length));

        constant spimem0_start_address : bus_address_type := std_logic_vector(to_unsigned(16#100000#, bus_address_type'length));
        constant spimem1_start_address : bus_address_type := std_logic_vector(to_unsigned(16#120000#, bus_address_type'length));
        constant spimem2_start_address : bus_address_type := std_logic_vector(to_unsigned(16#140000#, bus_address_type'length));

        variable writeMask : bus_write_mask := (others => '1');

        variable spimem0_test_input_data : bus_data_array(15 downto 0);
        variable spimem0_test_output_data : bus_data_array(15 downto 0);
        variable spimem1_test_input_data : bus_data_array(15 downto 0);
        variable spimem1_test_output_data : bus_data_array(15 downto 0);
        variable spimem2_test_input_data : bus_data_array(15 downto 0);
        variable spimem2_test_output_data : bus_data_array(15 downto 0);

        variable data : bus_data_type;
        variable expectedData : bus_data_type;
        variable address : bus_address_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Spi mem is usable") then
                for i in 0 to spimem0_test_input_data'high loop
                    spimem0_test_input_data(i) := std_logic_vector(to_unsigned(i, spimem0_test_input_data(i)'length));
                end loop;
                for i in 0 to spimem1_test_input_data'high loop
                    spimem1_test_input_data(i) := std_logic_vector(to_unsigned(i + 255, spimem1_test_input_data(i)'length));
                end loop;
                for i in 0 to spimem2_test_input_data'high loop
                    spimem2_test_input_data(i) := std_logic_vector(to_unsigned(i + 1024, spimem2_test_input_data(i)'length));
                end loop;
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => spimem0_start_address,
                    mask => writeMask,
                    data => spimem0_test_input_data);
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => spimem1_start_address,
                    mask => writeMask,
                    data => spimem1_test_input_data);
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => spimem2_start_address,
                    mask => writeMask,
                    data => spimem2_test_input_data);
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => spimem0_start_address,
                    data => spimem0_test_output_data);
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => spimem1_start_address,
                    data => spimem1_test_output_data);
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => spimem2_start_address,
                    data => spimem2_test_output_data);
                for i in 0 to spimem0_test_input_data'high loop
                    check_equal(spimem0_test_input_data(i), spimem0_test_input_data(i));
                end loop;
                for i in 0 to spimem1_test_input_data'high loop
                    check_equal(spimem1_test_input_data(i), spimem1_test_input_data(i));
                end loop;
                for i in 0 to spimem2_test_input_data'high loop
                    check_equal(spimem2_test_input_data(i), spimem2_test_input_data(i));
                end loop;
            elsif run("processor: Looped add") then
                simulated_depp_master_pkg.write_file_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => to_integer(unsigned(spimem0_start_address)),
                    fileName => "./mips32_processor/test/programs/loopedAdd.txt");
                data := (others => '0');
                simulated_depp_master_pkg.write_to_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => processor_controller_start_address,
                    mask => (others => '1'),
                    data => data);
                wait for 1000*clk_period;
                expectedData := X"00000003";
                address := std_logic_vector(to_unsigned(to_integer(unsigned(spimem0_start_address)) + 16#24#, address'length));
                simulated_depp_master_pkg.read_from_address(
                    net => net,
                    actor => deppMasterActor,
                    addr => address,
                    data => data);
                check_equal(data, expectedData);
            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 200 us);

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
        push_button => push_button,
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

    depp_master : entity tb.simulated_depp_master
    generic map (
        actor => deppMasterActor
    ) port map (
        usb_db => usb_db,
        usb_write => usb_write,
        usb_astb => usb_astb,
        usb_dstb => usb_dstb,
        usb_wait => usb_wait
    );
end architecture;
