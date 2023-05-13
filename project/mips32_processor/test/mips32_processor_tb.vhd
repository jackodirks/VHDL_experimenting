library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg;
use src.bus_pkg."&";
use src.mips32_pkg;

library tb;
use tb.simulated_bus_memory_pkg;

entity mips32_processor_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_processor_tb is
    constant clk_period : time := 20 ns;
    constant memoryAddress : natural := 16#100000#;
    constant controllerAddress : natural := 16#2000#;
    constant resetAddress : mips32_pkg.address_type := std_logic_vector(to_unsigned(memoryAddress, mips32_pkg.address_type'length));

    constant memActor : actor_t := new_actor("slave");

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal demux2control : bus_pkg.bus_mst2slv_type;
    signal control2demux : bus_pkg.bus_slv2mst_type;

    signal instructionFetch2arbiter : bus_pkg.bus_mst2slv_type;
    signal arbiter2instructionFetch : bus_pkg.bus_slv2mst_type;

    signal memory2arbiter : bus_pkg.bus_mst2slv_type;
    signal arbiter2memory : bus_pkg.bus_slv2mst_type;

    signal arbiter2demux : bus_pkg.bus_mst2slv_type;
    signal demux2arbiter : bus_pkg.bus_slv2mst_type;

    signal demux2mem : bus_pkg.bus_mst2slv_type;
    signal mem2demux : bus_pkg.bus_slv2mst_type;

    signal test2slv : bus_pkg.bus_mst2slv_type := bus_pkg.BUS_MST2SLV_IDLE;
    signal slv2test : bus_pkg.bus_slv2mst_type;

    constant address_map : bus_pkg.addr_range_and_mapping_array := (
        bus_pkg.address_range_and_map(
            low => std_logic_vector(to_unsigned(controllerAddress, bus_pkg.bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#2040# - 1, bus_pkg.bus_address_type'length)),
            mapping => bus_pkg.bus_map_constant(bus_pkg.bus_address_type'high - 6, '0') & bus_pkg.bus_map_range(6, 0)
        ),
        bus_pkg.address_range_and_map(
            low => std_logic_vector(to_unsigned(memoryAddress, bus_pkg.bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#160000# - 1, bus_pkg.bus_address_type'length)),
            mapping => bus_pkg.bus_map_constant(bus_pkg.bus_address_type'high - 18, '0') & bus_pkg.bus_map_range(18, 0)
        )
    );
begin
    clk <= not clk after (clk_period/2);
    main : process
        variable readAddr : bus_pkg.bus_address_type;
        variable readData : bus_pkg.bus_data_type;
        variable expectedReadData : bus_pkg.bus_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Looped add") then
                simulated_bus_memory_pkg.write_file_to_address(
                    net => net,
                    actor => memActor,
                    addr => 0,
                    fileName => "./mips32_processor/test/programs/loopedAdd.txt");
                -- Clear CPU internal reset
                test2slv <= bus_pkg.bus_mst2slv_write(
                    address => std_logic_vector(to_unsigned(controllerAddress, bus_pkg.bus_address_type'length)),
                    write_data => (others => '0'),
                    write_mask => (others => '1'));
                wait until rising_edge(clk) and bus_pkg.any_transaction(test2slv, slv2test);
                check(bus_pkg.write_transaction(test2slv, slv2test));
                test2slv <= bus_pkg.BUS_MST2SLV_IDLE;
                wait for 102*clk_period;
                expectedReadData := X"00000003";
                readAddr := std_logic_vector(to_unsigned(16#24#, bus_pkg.bus_address_type'length));
                simulated_bus_memory_pkg.read_from_address(
                    net => net,
                    actor => memActor,
                    addr => readAddr,
                    data => readData);
                check_equal(readData, expectedReadData);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    processor : entity src.mips32_processor
    generic map (
        resetAddress => resetAddress
    ) port map (
        clk => clk,
        rst => rst,
        mst2control => demux2control,
        control2mst => control2demux,
        instructionFetch2slv => instructionFetch2arbiter,
        slv2instructionFetch => arbiter2instructionFetch,
        memory2slv => memory2arbiter,
        slv2memory => arbiter2memory
    );

    arbiter : entity src.bus_arbiter
    generic map (
        masterCount => 3
   ) port map (
        clk => clk,
        mst2arbiter(0) => instructionFetch2arbiter,
        mst2arbiter(1) => memory2arbiter,
        mst2arbiter(2) => test2slv,
        arbiter2mst(0) => arbiter2instructionFetch,
        arbiter2mst(1) => arbiter2memory,
        arbiter2mst(2) => slv2test,
        arbiter2slv => arbiter2demux,
        slv2arbiter => demux2arbiter
    );

   demux : entity src.bus_demux
   generic map (
        address_map => address_map
   ) port map (
        mst2demux => arbiter2demux,
        demux2mst => demux2arbiter,
        demux2slv(0) => demux2control,
        demux2slv(1) => demux2mem,
        slv2demux(0) => control2demux,
        slv2demux(1) => mem2demux
    );

   mem : entity work.simulated_bus_memory
   generic map (
        depth_log2b => 10,
        allow_unaligned_access => false,
        actor => memActor,
        read_delay => 5,
        write_delay => 5
    ) port map (
        clk => clk,
        mst2mem => demux2mem,
        mem2mst => mem2demux
    );

    test_runner_watchdog(runner, 10 ms);
end architecture;
