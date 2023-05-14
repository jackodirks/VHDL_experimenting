library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg;

entity mips32_pipeline_instructionFetch_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_instructionFetch_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    constant startAddress : mips32_pkg.address_type := X"00000014";
    signal requestFromBusAddress : mips32_pkg.address_type;
    signal instructionToInstructionDecode : mips32_pkg.instruction_type;
    signal programCounterPlusFour : mips32_pkg.address_type;
    signal instructionFromBus : mips32_pkg.instruction_type := (others => '1');
    signal overrideProgramCounter : boolean := false;
    signal newProgramCounter : mips32_pkg.instruction_type := (others => '1');
    signal stall : boolean := false;


begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedAddress : mips32_pkg.address_type;
        variable expectedInstruction : mips32_pkg.instruction_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("On start, the requested address should be the reset address") then
                wait until rising_edge(clk);
                check_equal(startAddress, requestFromBusAddress);
            elsif run("On stall, the requested address should not increase") then
                stall <= true;
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check_equal(startAddress, requestFromBusAddress);
            elsif run("Without stall, the requested address should increase") then
                expectedAddress := std_logic_vector(unsigned(startAddress) + 4);
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check_equal(expectedAddress, requestFromBusAddress);
            elsif run("The override address should be respected") then
                expectedAddress := std_logic_vector(unsigned(startAddress) + 40);
                overrideProgramCounter <= true;
                newProgramCounter <= expectedAddress;
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check_equal(expectedAddress, requestFromBusAddress);
            elsif run("On the first rising edge, a nop should be send to ID") then
                wait until rising_edge(clk);
                check_equal(instructionToInstructionDecode, mips32_pkg.instructionNop);
            elsif run("On the second rising edge, the expected instruction and pc+4 should be send to ID") then
                expectedInstruction := X"00000001";
                instructionFromBus <= expectedInstruction;
                expectedAddress := std_logic_vector(unsigned(startAddress) + 4);
                wait until rising_edge(clk);
                instructionFromBus <= X"00000002";
                wait until rising_edge(clk);
                check_equal(expectedInstruction, instructionToInstructionDecode);
                check_equal(expectedAddress, requestFromBusAddress);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    instructionFetch : entity src.mips32_pipeline_instructionFetch
    generic map (
        startAddress => startAddress
    ) port map (
        clk => clk,
        rst => rst,
        requestFromBusAddress => requestFromBusAddress,
        instructionToInstructionDecode => instructionToInstructionDecode,
        programCounterPlusFour => programCounterPlusFour,
        instructionFromBus => instructionFromBus,
        overrideProgramCounter => overrideProgramCounter,
        newProgramCounter => newProgramCounter,
        stall => stall
    );

end architecture;
