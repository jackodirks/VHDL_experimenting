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
    constant resetAddress : mips32_pkg.address_type := (others => '0');

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean;

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
            if run("Unforwarded add") then
                rst <= '1';
                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 0,
                    data => X"8C0A0050");
                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 4,
                    data => X"8C0B0054");
                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 8,
                    data => X"014B6020");
                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 12,
                    data => X"08000000");
                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 16,
                    data => X"AC0C0058");

                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 80,
                    data => X"00000001");
                mips32_pipeline_simulated_memory_pkg.write_to_address(
                    net => net,
                    actor => memActor,
                    addr => 84,
                    data => X"00000002");
                rst <= '0';
                expectedReadData := X"00000003";
                wait for 11*clk_period;
                rst <= '1';
                mips32_pipeline_simulated_memory_pkg.read_from_address(
                    net => net,
                    actor => memActor,
                    addr => 88,
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
        stall_cycles => 0
    ) port map (
        clk => clk,
        rst => rst,
        stall => stall,
        ifRequestAddress => instructionAddress,
        ifData => instruction,
        doMemRead => dataRead,
        doMemWrite => dataWrite,
        memAddress => dataAddress,
        dataToMem => dataOut,
        dataFromMem => dataIn
    );
end architecture;
