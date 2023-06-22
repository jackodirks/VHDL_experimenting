library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.seven_seg_pkg.all;

library tb;
use tb.bus_tb_pkg.all;

entity seven_seg_controller_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of seven_seg_controller_tb is

    constant clk_period : time := 20 ns;
    constant ss1_ticks : natural := 1;
    constant ss1_digit_count : natural := 1;
    constant ss2_ticks : natural := 10;
    constant ss2_digit_count : natural := 4;

    constant all_one_digit : digit_info_type := (others => '1');
    constant digit_others_zeros : std_logic_vector(bus_data_type'high - digit_info_type'high - 1 downto 0) := (others => '0');

    signal mst2ss1 : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal ss1_2mst : bus_slv2mst_type := BUS_SLV2MST_IDLE;
    signal mst2ss2 : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal ss2_2mst : bus_slv2mst_type := BUS_SLV2MST_IDLE;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal ss1_digit_anodes : std_logic_vector(ss1_digit_count - 1 downto 0);
    signal ss1_kathode : seven_seg_kath_type;
    signal ss2_digit_anodes : std_logic_vector(ss2_digit_count - 1 downto 0);
    signal ss2_kathode : seven_seg_kath_type;

begin

    clk <= not clk after (clk_period/2);

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Address out of range") then
                wait until falling_edge(clk);
                mst2ss1 <= bus_tb_mst2slv(address => 10, readReady => '1');
                wait until rising_edge(clk) and fault_transaction(mst2ss1, ss1_2mst);
                check_equal(bus_fault_address_out_of_range, ss1_2mst.faultData);
                mst2ss1 <= bus_tb_mst2slv(address => 0, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss1, ss1_2mst);
                mst2ss1 <= bus_tb_mst2slv(address => 1, readReady => '1');
                wait until rising_edge(clk) and fault_transaction(mst2ss1, ss1_2mst);
                check_equal(bus_fault_address_out_of_range, ss1_2mst.faultData);
            end if;
            if run("Memory check") then
                wait until falling_edge(clk);
                mst2ss1 <= bus_tb_mst2slv(address => 0, writeData => 255,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss1, ss1_2mst);
                mst2ss1 <= bus_tb_mst2slv(address => 0, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss1, ss1_2mst);
                check(to_integer(unsigned(ss1_2mst.readData)) = 255);
                mst2ss1 <= bus_tb_mst2slv(address => 0, writeData => 0,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss1, ss1_2mst);
                mst2ss1 <= BUS_MST2SLV_IDLE;
                mst2ss1 <= bus_tb_mst2slv(address => 0, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss1, ss1_2mst);
                check(to_integer(unsigned(ss1_2mst.readData)) = 0);
            end if;
            if run("Single output check") then
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                -- Default register content should be all zeros.
                check(ss1_digit_anodes(0) = '0');
                check(ss1_kathode = "11000000");
                -- Only enable the dot
                mst2ss1 <= bus_tb_mst2slv(address => 0, writeData => 16#10#,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss1, ss1_2mst);
                mst2ss1 <= BUS_MST2SLV_IDLE;
                wait for 2*clk_period;
                check(ss1_digit_anodes(0) = '0');
                check(ss1_kathode = "01000000");
            end if;
            if run("Multiple output check") then
                wait until falling_edge(clk);
                -- First, enter all values
                -- Digit 1: 1, with dot
                mst2ss2 <= bus_tb_mst2slv(address => 0, writeData => 16#11#,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                -- Digit 2: 8, no dot
                mst2ss2 <= bus_tb_mst2slv(address => 1, writeData => 16#08#,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                -- Digit 3: a, with dot
                mst2ss2 <= bus_tb_mst2slv(address => 2, writeData => 16#1a#,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                -- Digit 4: f, no dot
                mst2ss2 <= bus_tb_mst2slv(address => 3, writeData => 16#0f#,  writeReady => '1', byteMask => 1);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                mst2ss2 <= BUS_MST2SLV_IDLE;
                -- Check the actual outputs. We expect digit 1 to be active right now
                check(ss2_digit_anodes = "1110");
                check(ss2_kathode = "01111001");
                -- Wait the timeout for the next digit to activate..
                wait for ss2_ticks * clk_period;
                -- We expect digit 2 to be active right now.
                check(ss2_digit_anodes = "1101");
                check(ss2_kathode = "10000000");
                wait for ss2_ticks * clk_period;
                -- We expect digit 3 to be active right now.
                check(ss2_digit_anodes = "1011");
                check(ss2_kathode = "00001000");
                wait for ss2_ticks * clk_period;
                -- We expect digit 4 to be active right now.
                check(ss2_digit_anodes = "0111");
                check(ss2_kathode = "10001110");
            end if;
            if run("Multiple byte write") then
                wait until falling_edge(clk);
                mst2ss2 <= bus_tb_mst2slv(address => 0, writeData => 16#14131211#,  writeReady => '1', byteMask => 15);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                mst2ss2 <= BUS_MST2SLV_IDLE;
                wait for 2*clk_period;
                -- Check the actual outputs. We expect digit 1 to be active right now
                check(ss2_digit_anodes = "1110");
                check(ss2_kathode = "01111001");
                -- Wait the timeout for the next digit to activate..
                wait for ss2_ticks * clk_period;
                -- We expect digit 2 to be active right now.
                check(ss2_digit_anodes = "1101");
                check(ss2_kathode = "00100100");
                wait for ss2_ticks * clk_period;
                -- We expect digit 3 to be active right now.
                check(ss2_digit_anodes = "1011");
                check(ss2_kathode = "00110000");
                wait for ss2_ticks * clk_period;
                -- We expect digit 4 to be active right now.
                check(ss2_digit_anodes = "0111");
                check(ss2_kathode = "00011001");
                wait until falling_edge(clk);
                mst2ss2 <= bus_tb_mst2slv(address => 1, writeData => 16#14131211#,  writeReady => '1', byteMask => 15);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                mst2ss2 <= BUS_MST2SLV_IDLE;
                wait for clk_period;
                wait until (ss2_digit_anodes = "1110");
                check(ss2_kathode = "01111001");
                wait until (ss2_digit_anodes = "1101");
                check(ss2_kathode = "01111001");
                wait until (ss2_digit_anodes = "1011");
                check(ss2_kathode = "00100100");
                wait until (ss2_digit_anodes = "0111");
                check(ss2_kathode = "00110000");
                wait until falling_edge(clk);
                mst2ss2 <= bus_tb_mst2slv(address => 2, writeData => 16#18181818#,  writeReady => '1', byteMask => 16#9#);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                mst2ss2 <= BUS_MST2SLV_IDLE;
                wait until (ss2_digit_anodes = "1110");
                check(ss2_kathode = "01111001");
                wait until (ss2_digit_anodes = "1101");
                check(ss2_kathode = "01111001");
                wait until (ss2_digit_anodes = "1011");
                check(ss2_kathode = "00000000");
                wait until (ss2_digit_anodes = "0111");
                check(ss2_kathode = "00110000");
            end if;
            if run("Multiple byte read") then
                wait until falling_edge(clk);
                mst2ss2 <= bus_tb_mst2slv(address => 0, writeData => 16#14131211#,  writeReady => '1', byteMask => 15);
                wait until rising_edge(clk) and write_transaction(mst2ss2, ss2_2mst);
                mst2ss2 <= bus_tb_mst2slv(address => 0, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss2, ss2_2mst);
                check_equal(to_integer(unsigned(ss2_2mst.readData)), 16#14131211#);
                mst2ss2 <= bus_tb_mst2slv(address => 1, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss2, ss2_2mst);
                check_equal(to_integer(unsigned(ss2_2mst.readData)), 16#141312#);
                mst2ss2 <= bus_tb_mst2slv(address => 2, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss2, ss2_2mst);
                check_equal(to_integer(unsigned(ss2_2mst.readData)), 16#1413#);
                mst2ss2 <= bus_tb_mst2slv(address => 3, readReady => '1');
                wait until rising_edge(clk) and read_transaction(mst2ss2, ss2_2mst);
                check_equal(to_integer(unsigned(ss2_2mst.readData)), 16#14#);
            end if;
        end loop;
        wait until rising_edge(clk) or falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    ss_1 : entity src.seven_seg_controller
    generic map (
        hold_count => ss1_ticks,
        digit_count => ss1_digit_count
    )
    port map (
        clk => clk,
        rst => rst,
        mst2slv => mst2ss1,
        slv2mst => ss1_2mst,
        digit_anodes => ss1_digit_anodes,
        kathode => ss1_kathode
    );

    ss_2 : entity src.seven_seg_controller
    generic map (
        hold_count => ss2_ticks,
        digit_count => ss2_digit_count
    )
    port map (
        clk => clk,
        rst => rst,
        mst2slv => mst2ss2,
        slv2mst => ss2_2mst,
        digit_anodes => ss2_digit_anodes,
        kathode => ss2_kathode
    );
end architecture;
