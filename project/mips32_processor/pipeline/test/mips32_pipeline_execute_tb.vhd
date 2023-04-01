library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg;

entity mips32_pipeline_execute_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_execute_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean := false;

    signal writeBackControlWord : mips32_pkg.WriteBackControlWord_type := mips32_pkg.writeBackControlWordAllFalse;
    signal memoryControlWord : mips32_pkg.MemoryControlWord_type := mips32_pkg.memoryControlWordAllFalse;
    signal executeControlWord : mips32_pkg.ExecuteControlWord_type := mips32_pkg.executeControlWordAllFalse;

    signal rsData : mips32_pkg.data_type;
    signal regDataB : mips32_pkg.data_type;
    signal immidiate : mips32_pkg.data_type;
    signal destinationReg : mips32_pkg.registerFileAddress_type;
    signal aluFunction : mips32_pkg.aluFunction_type;
    signal shamt : mips32_pkg.shamt_type;

    signal memoryControlWordToMem : mips32_pkg.MemoryControlWord_type;
    signal writeBackControlWordToMem : mips32_pkg.WriteBackControlWord_type;
    signal aluResult : mips32_pkg.data_type;
    signal regDataRead : mips32_pkg.data_type;
    signal destinationRegToMem : mips32_pkg.registerFileAddress_type;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedAluResult : mips32_pkg.data_type;
        variable expectedDestinationRegToMem : mips32_pkg.registerFileAddress_type;
        variable expectedRegDataRead : mips32_pkg.data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Before the first rising edge, all control output is zero") then
                check(not memoryControlWordToMem.MemOp);
                check(not memoryControlWordToMem.MemOpIsWrite);
                check(not writeBackControlWordToMem.regWrite);
                check(not writeBackControlWordToMem.MemtoReg);
            elsif run("Input memory, writeback control is forwarded") then
                memoryControlWord.MemOpIsWrite <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(memoryControlWordToMem.MemOpIsWrite);
            elsif run("Synchronous reset works") then
                memoryControlWord.MemOp <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not memoryControlWordToMem.MemOp);
            elsif run("R-type subtract function works") then
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                regDataB <= std_logic_vector(to_signed(10, regDataB'length));
                aluFunction <= mips32_pkg.aluFunctionSubtract;
                destinationReg <= 13;
                expectedAluResult := std_logic_vector(to_signed(90, expectedAluResult'length));
                expectedDestinationRegToMem := 13;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(aluResult, expectedAluResult);
                check_equal(destinationRegToMem, expectedDestinationRegToMem);
            elsif run("I-type add instructions work") then
                rsData <= std_logic_vector(to_signed(32, rsData'length));
                regDataB <= std_logic_vector(to_signed(255, regDataB'length));
                immidiate <= std_logic_vector(to_signed(-4, immidiate'length));
                executeControlWord.ALUSrc <= true;
                executeControlWord.ALUOpIsAdd <= true;
                destinationReg <= 26;
                expectedAluResult := std_logic_vector(to_signed(28, expectedAluResult'length));
                expectedDestinationRegToMem := 26;
                expectedRegDataRead := std_logic_vector(to_signed(255, expectedRegDataRead'length));
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(aluResult, expectedAluResult);
                check_equal(destinationRegToMem, expectedDestinationRegToMem);
                check_equal(regDataRead, expectedRegDataRead);
            elsif run("Stall stalls the registers") then
                memoryControlWord.MemOp <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                stall <= true;
                memoryControlWord.MemOp <= false;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(memoryControlWordToMem.MemOp);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    executeStage : entity src.mips32_pipeline_execute
    port map (
        clk => clk,
        rst => rst,
        stall => stall,
        writeBackControlWord => writeBackControlWord,
        memoryControlWord => memoryControlWord,
        executeControlWord => executeControlWord,
        rsData => rsData,
        regDataB => regDataB,
        immidiate => immidiate,
        destinationReg => destinationReg,
        aluFunction => aluFunction,
        shamt => shamt,
        memoryControlWordToMem => memoryControlWordToMem,
        writeBackControlWordToMem => writeBackControlWordToMem,
        aluResult => aluResult,
        regDataRead => regDataRead,
        destinationRegToMem => destinationRegToMem
    );

end architecture;
