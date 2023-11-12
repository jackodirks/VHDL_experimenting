library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.riscv32_pkg.all;

library tb;
use tb.simulated_bus_memory_pkg;

entity riscv32_processor_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of riscv32_processor_tb is
    constant clk_period : time := 20 ns;
    constant memoryAddress : natural := 16#100000#;
    constant controllerAddress : natural := 16#2000#;
    constant resetAddress : riscv32_address_type := std_logic_vector(to_unsigned(memoryAddress, riscv32_address_type'length));
    constant iCache_rangeMap : addr_range_and_mapping_type :=
        address_range_and_map(
            low => std_logic_vector(to_unsigned(16#100000#, bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#160000# - 1, bus_address_type'length)),
            mapping => bus_map_constant(bus_address_type'high - 18, '0') & bus_map_range(18, 0)
        );
    constant iCache_word_count_log2b : natural := 8;
    constant dCache_word_count_log2b : natural := 8;

    constant memActor : actor_t := new_actor("slave");

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal demux2control : bus_mst2slv_type;
    signal control2demux : bus_slv2mst_type;

    signal instructionFetch2arbiter : bus_mst2slv_type;
    signal arbiter2instructionFetch : bus_slv2mst_type;

    signal memory2arbiter : bus_mst2slv_type;
    signal arbiter2memory : bus_slv2mst_type;

    signal arbiter2demux : bus_mst2slv_type;
    signal demux2arbiter : bus_slv2mst_type;

    signal demux2mem : bus_mst2slv_type;
    signal mem2demux : bus_slv2mst_type;

    signal test2slv : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal slv2test : bus_slv2mst_type;

    constant address_map : addr_range_and_mapping_array := (
        address_range_and_map(
            low => std_logic_vector(to_unsigned(controllerAddress, bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#2100# - 1, bus_address_type'length)),
            mapping => bus_map_constant(bus_address_type'high - 8, '0') & bus_map_range(8, 0)
        ),
        address_range_and_map(
            low => std_logic_vector(to_unsigned(memoryAddress, bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#160000# - 1, bus_address_type'length)),
            mapping => bus_map_constant(bus_address_type'high - 18, '0') & bus_map_range(18, 0)
        )
    );

    procedure start_cpu (signal mst2slv : inout bus_mst2slv_type; signal slv2mst : in bus_slv2mst_type) is
    begin
        mst2slv <= bus_mst2slv_write(
            address => std_logic_vector(to_unsigned(controllerAddress, bus_address_type'length)),
            write_data => (others => '0'),
            byte_mask => (others => '1'));
        wait until rising_edge(clk) and any_transaction(mst2slv, slv2mst);
        check(write_transaction(mst2slv, slv2mst));
        mst2slv <= BUS_MST2SLV_IDLE;
    end procedure;

    procedure check_word_at_address(
        signal net : inout network_t;
        constant address : in bus_address_type;
        constant data : in bus_data_type) is
        variable readData : bus_data_type;
    begin
        simulated_bus_memory_pkg.read_from_address(
            net => net,
            actor => memActor,
            addr => address,
            data => readData);
        check_equal(readData, data);
    end procedure;

begin
    clk <= not clk after (clk_period/2);
    main : process
        variable readAddr : bus_address_type;
        variable readData : bus_data_type;
        variable expectedReadData : bus_data_type;
        variable curAddr : natural;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Store and read one") then
                simulated_bus_memory_pkg.write_file_to_address(net, memActor, 0, "./riscv32_processor/test/programs/storeEleven.txt");
                start_cpu(test2slv, slv2test);
                wait for 100*clk_period;
                expectedReadData := X"0000000b";
                readAddr := std_logic_vector(to_unsigned(16#14#, bus_address_type'length));
                check_word_at_address(net, readAddr, expectedReadData);
            elsif run("Load, add and store") then
                simulated_bus_memory_pkg.write_file_to_address(net, memActor, 0, "./riscv32_processor/test/programs/loadThenStore.txt");
                start_cpu(test2slv, slv2test);
                wait for 100*clk_period;
                expectedReadData := X"0000000e";
                readAddr := std_logic_vector(to_unsigned(16#1c#, bus_address_type'length));
                check_word_at_address(net, readAddr, expectedReadData);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    processor : entity src.riscv32_processor
    generic map (
        startAddress => resetAddress,
        clk_period => clk_period,
        iCache_range => iCache_rangeMap.addr_range,
        iCache_word_count_log2b => iCache_word_count_log2b,
        dCache_range => iCache_rangeMap.addr_range,
        dCache_word_count_log2b => dCache_word_count_log2b
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
        allow_unaligned_access => true,
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
