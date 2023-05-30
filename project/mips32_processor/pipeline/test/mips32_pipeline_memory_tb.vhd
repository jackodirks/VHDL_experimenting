library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_pipeline_memory_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_memory_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean := false;

    signal writeBackControlWord : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    signal memoryControlWord : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;

    signal execResult : mips32_data_type;
    signal regDataRead : mips32_data_type;
    signal destinationReg : mips32_registerFileAddress_type;

    signal writeBackControlWordToWriteBack : mips32_WriteBackControlWord_type;
    signal execResultToWriteback : mips32_data_type;
    signal memDataReadToWriteback : mips32_data_type;
    signal destinationRegToWriteback : mips32_registerFileAddress_type;

    signal doMemRead : boolean;
    signal doMemWrite : boolean;
    signal memAddress : mips32_address_type;
    signal dataToMem : mips32_data_type;
    signal dataFromMem : mips32_data_type;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedMemAddress : mips32_address_type;
        variable expectedDataToMem : mips32_data_type;
        variable expectedExecResultToWriteback : mips32_data_type;
        variable expectedDestinationRegToWriteback : mips32_registerFileAddress_type;
        variable expectedMemDataReadToWriteback : mips32_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Before the first rising edge, all control output is zero") then
                check(not writeBackControlWordToWriteBack.regWrite);
                check(not writeBackControlWordToWriteBack.MemtoReg);
            elsif run("Requesting a memory write works") then
                memoryControlWord.MemOp <= true;
                memoryControlWord.MemOpIsWrite <= true;
                expectedMemAddress := X"0000FFF0";
                expectedDataToMem := X"FFFF0000";
                execResult <= expectedMemAddress;
                regDataRead <= expectedDataToMem;
                wait until rising_edge(clk);
                check_equal(memAddress, expectedMemAddress);
                check_equal(dataToMem, expectedDataToMem);
                check(doMemWrite);
                check(not doMemRead);
            elsif run("Not requesting any MemOp works") then
                memoryControlWord.MemOp <= false;
                memoryControlWord.MemOpIsWrite <= false;
                wait until rising_edge(clk);
                check(not doMemWrite);
                check(not doMemRead);
            elsif run("Data is forwarded to writeBack on rising edge") then
                expectedExecResultToWriteback := X"AABBCCDD";
                expectedDestinationRegToWriteback := 5;
                writeBackControlWord.regWrite <= true;
                writeBackControlWord.MemtoReg <= true;
                execResult <= expectedExecResultToWriteback;
                destinationReg <= expectedDestinationRegToWriteback;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(writeBackControlWordToWriteBack.regWrite);
                check(writeBackControlWordToWriteBack.MemtoReg);
                check_equal(execResultToWriteback, expectedExecResultToWriteback);
                check_equal(destinationRegToWriteback, expectedDestinationRegToWriteback);
            elsif run("Requesting a memory read works") then
                memoryControlWord.MemOp <= true;
                memoryControlWord.MemOpIsWrite <= false;
                expectedMemAddress := X"0000FFF0";
                execResult <= expectedMemAddress;
                wait until rising_edge(clk);
                check_equal(memAddress, expectedMemAddress);
                check(not doMemWrite);
                check(doMemRead);
            elsif run("Data read from memory is forwarded to writeBack") then
                memoryControlWord.MemOp <= true;
                memoryControlWord.MemOpIsWrite <= false;
                expectedMemDataReadToWriteback := X"F0FAFAFA";
                dataFromMem <= expectedMemDataReadToWriteback;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(memDataReadToWriteback, expectedMemDataReadToWriteback);
            elsif run("On stall, the output data is not updated") then
                writeBackControlWord.regWrite <= true;
                writeBackControlWord.MemtoReg <= true;
                wait until rising_edge(clk);
                writeBackControlWord.regWrite <= false;
                stall <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(writeBackControlWordToWriteBack.regWrite);
                check(writeBackControlWordToWriteBack.MemtoReg);
            elsif run("On reset, the output control signals are all false") then
                writeBackControlWord.regWrite <= true;
                writeBackControlWord.MemtoReg <= true;
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not writeBackControlWordToWriteBack.regWrite);
                check(not writeBackControlWordToWriteBack.MemtoReg);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    memoryStage : entity src.mips32_pipeline_memory
    port map (
        clk => clk,
        rst => rst,
        stall => stall,
        writeBackControlWord => writeBackControlWord,
        memoryControlWord => memoryControlWord,
        execResult => execResult,
        regDataRead => regDataRead,
        destinationReg => destinationReg,
        writeBackControlWordToWriteBack => writeBackControlWordToWriteBack,
        execResultToWriteback => execResultToWriteback,
        memDataReadToWriteback => memDataReadToWriteback,
        destinationRegToWriteback => destinationRegToWriteback,
        doMemRead => doMemRead,
        doMemWrite => doMemWrite,
        memAddress => memAddress,
        dataToMem => dataToMem,
        dataFromMem => dataFromMem
    );

end architecture;
