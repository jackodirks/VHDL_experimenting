library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_pipeline_instructionFetch_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_instructionFetch_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    constant startAddress : mips32_address_type := X"00000014";
    signal requestFromBusAddress : mips32_address_type;
    signal instructionToInstructionDecode : mips32_instruction_type;
    signal programCounterPlusFour : mips32_address_type;
    signal instructionFromBus : mips32_instruction_type := (others => '1');
    signal overrideProgramCounterFromID : boolean := false;
    signal newProgramCounterFromID : mips32_instruction_type := (others => '1');
    signal overrideProgramCounterFromEx : boolean := false;
    signal newProgramCounterFromEx : mips32_instruction_type := (others => '1');
    signal stall : boolean := false;
    signal injectBubble : boolean := false;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedAddress : mips32_address_type;
        variable expectedInstruction : mips32_instruction_type;
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
            elsif run("The override address from ID should be respected") then
                expectedAddress := std_logic_vector(unsigned(startAddress) + 40);
                overrideProgramCounterFromID <= true;
                newProgramCounterFromID <= expectedAddress;
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check_equal(expectedAddress, requestFromBusAddress);
            elsif run("The override address from EX should be respected") then
                expectedAddress := std_logic_vector(unsigned(startAddress) + 40);
                overrideProgramCounterFromEx <= true;
                newProgramCounterFromEx <= expectedAddress;
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check_equal(expectedAddress, requestFromBusAddress);
            elsif run("The override address from EX should take precedence") then
                expectedAddress := std_logic_vector(unsigned(startAddress) + 40);
                overrideProgramCounterFromEx <= true;
                newProgramCounterFromEx <= expectedAddress;
                overrideProgramCounterFromID <= true;
                newProgramCounterFromID <= std_logic_vector(unsigned(startAddress) + 16);
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                check_equal(expectedAddress, requestFromBusAddress);
            elsif run("On the first rising edge, a nop should be send to ID") then
                wait until rising_edge(clk);
                check_equal(instructionToInstructionDecode, mips32_instructionNop);
            elsif run("On the second rising edge, the expected instruction and pc+4 should be send to ID") then
                expectedInstruction := X"00000001";
                instructionFromBus <= expectedInstruction;
                expectedAddress := std_logic_vector(unsigned(startAddress) + 4);
                wait until rising_edge(clk);
                instructionFromBus <= X"00000002";
                wait until rising_edge(clk);
                check_equal(expectedInstruction, instructionToInstructionDecode);
                check_equal(expectedAddress, requestFromBusAddress);
            elsif run("InjectBubble freezes the pc") then
                expectedAddress := std_logic_vector(unsigned(startAddress) + 4);
                wait until falling_edge(clk);
                injectBubble <= true;
                wait until falling_edge(clk);
                check_equal(requestFromBusAddress, expectedAddress);
            elsif run("InjectBubble creates a NOP") then
                instructionFromBus <= X"FF00FF00";
                expectedInstruction := mips32_instructionNop;
                wait until falling_edge(clk);
                injectBubble <= true;
                wait until falling_edge(clk);
                injectBubble <= false;
                wait until falling_edge(clk);
                check_equal(instructionToInstructionDecode, expectedInstruction);
            elsif run("During stall, injectBubble does nothing") then
                instructionFromBus <= X"FF00FF00";
                wait until falling_edge(clk);
                injectBubble <= true;
                stall <= true;
                wait until falling_edge(clk);
                stall <= false;
                wait until falling_edge(clk);
                check_equal(instructionToInstructionDecode, instructionFromBus);
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
        overrideProgramCounterFromID => overrideProgramCounterFromID,
        newProgramCounterFromID => newProgramCounterFromID,
        overrideProgramCounterFromEx => overrideProgramCounterFromEx,
        newProgramCounterFromEx => newProgramCounterFromEx,
        injectBubble => injectBubble,
        stall => stall
    );

end architecture;
