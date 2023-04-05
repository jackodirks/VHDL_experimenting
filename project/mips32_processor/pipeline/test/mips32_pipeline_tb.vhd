library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg;
use src.mips32_pkg;

library tb;
use tb.mips32_pipeline_simulated_memory_pkg;

entity mips32_pipeline_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_tb is
    constant clk_period : time := 20 ns;
    constant memActor : actor_t := new_actor("Mem");
    constant offset_address : natural := 16#100000#;
    constant resetAddress : mips32_pkg.address_type := std_logic_vector(to_unsigned(offset_address, mips32_pkg.address_type'length));

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean;

    signal if_stall_cycles : natural := 0;

    signal instructionAddress : mips32_pkg.address_type;
    signal instruction : mips32_pkg.data_type;

    signal dataAddress : mips32_pkg.address_type;
    signal dataRead : boolean;
    signal dataWrite : boolean;
    signal dataOut : mips32_pkg.data_type;
    signal dataIn : mips32_pkg.data_type;
begin
    clk <= not clk after (clk_period/2);
    main : process
        variable readData : mips32_pkg.data_type;
        variable expectedReadData : mips32_pkg.data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Looped add") then
                rst <= '1';
                mips32_pipeline_simulated_memory_pkg.write_file_to_address(
                    net => net,
                    actor => memActor,
                    addr => offset_address,
                    fileName => "./mips32_processor/pipeline/test/testPrograms/loopedAdd.txt");
                rst <= '0';
                expectedReadData := X"00000003";
                wait for 11*clk_period;
                rst <= '1';
                mips32_pipeline_simulated_memory_pkg.read_from_address(
                    net => net,
                    actor => memActor,
                    addr => 16#100024#,
                    data => readData);
                check_equal(readData, expectedReadData);
            elsif run("Delayed looped add") then
                if_stall_cycles <= 2;
                rst <= '1';
                mips32_pipeline_simulated_memory_pkg.write_file_to_address(
                    net => net,
                    actor => memActor,
                    addr => offset_address,
                    fileName => "./mips32_processor/pipeline/test/testPrograms/loopedAdd.txt");
                rst <= '0';
                expectedReadData := X"00000003";
                wait for 29*clk_period;
                rst <= '1';
                mips32_pipeline_simulated_memory_pkg.read_from_address(
                    net => net,
                    actor => memActor,
                    addr => 16#100024#,
                    data => readData);
                check_equal(readData, expectedReadData);
            end if;
        end loop;
        wait for 2*clk_period;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 10 ms);

    pipeline : entity src.mips32_pipeline
    generic map (
        resetAddress => resetAddress
   ) port map (
        clk => clk,
        rst => rst,
        stall => stall,
        instructionAddress => instructionAddress,
        instruction => instruction,
        dataAddress => dataAddress,
        dataRead => dataRead,
        dataWrite => dataWrite,
        dataOut => dataOut,
        dataIn => dataIn
    );

   simulated_memory : entity tb.mips32_pipeline_simulated_memory
   generic map (
        actor => memActor,
        memory_size_log2b => 10,
        offset_address => offset_address
    ) port map (
        clk => clk,
        rst => rst,
        stall => stall,
        if_stall_cycles => if_stall_cycles,
        ifRequestAddress => instructionAddress,
        ifData => instruction,
        doMemRead => dataRead,
        doMemWrite => dataWrite,
        memAddress => dataAddress,
        dataToMem => dataOut,
        dataFromMem => dataIn
    );
end architecture;
