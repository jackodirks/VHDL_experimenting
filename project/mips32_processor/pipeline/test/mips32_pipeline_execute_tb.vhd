library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_pipeline_execute_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_execute_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean := false;

    signal writeBackControlWord : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    signal memoryControlWord : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
    signal executeControlWord : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;

    signal rsData : mips32_data_type;
    signal rtData : mips32_data_type;
    signal immidiate : mips32_data_type;
    signal destinationReg : mips32_registerFileAddress_type;
    signal aluFunction : mips32_aluFunction_type;
    signal shamt : mips32_shamt_type;
    signal programCounterPlusFour : mips32_address_type;

    signal memoryControlWordToMem : mips32_MemoryControlWord_type;
    signal writeBackControlWordToMem : mips32_WriteBackControlWord_type;
    signal execResult : mips32_data_type;
    signal regDataRead : mips32_data_type;
    signal destinationRegToMem : mips32_registerFileAddress_type;

    signal overrideProgramCounter : boolean;
    signal newProgramCounter : mips32_address_type;

    signal justBranched : boolean;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable expectedExecResult : mips32_data_type;
        variable expectedDestinationRegToMem : mips32_registerFileAddress_type;
        variable expectedRegDataRead : mips32_data_type;
        variable expectedBranchTarget : mips32_address_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Before the first rising edge, all control output is zero") then
                check(not memoryControlWordToMem.MemOp);
                check(not memoryControlWordToMem.MemOpIsWrite);
                check(not writeBackControlWordToMem.regWrite);
                check(not writeBackControlWordToMem.MemtoReg);
                check(not justBranched);
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
                rtData <= std_logic_vector(to_signed(10, rtData'length));
                aluFunction <= mips32_aluFunctionSubtract;
                destinationReg <= 13;
                expectedExecResult := std_logic_vector(to_signed(90, expectedExecResult'length));
                expectedDestinationRegToMem := 13;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(execResult, expectedExecResult);
                check_equal(destinationRegToMem, expectedDestinationRegToMem);
            elsif run("I-type add instructions work") then
                rsData <= std_logic_vector(to_signed(32, rsData'length));
                rtData <= std_logic_vector(to_signed(255, rtData'length));
                immidiate <= std_logic_vector(to_signed(-4, immidiate'length));
                executeControlWord.ALUSrc <= true;
                executeControlWord.ALUOpDirective <= exec_add;
                destinationReg <= 26;
                expectedExecResult := std_logic_vector(to_signed(28, expectedExecResult'length));
                expectedDestinationRegToMem := 26;
                expectedRegDataRead := std_logic_vector(to_signed(255, expectedRegDataRead'length));
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(execResult, expectedExecResult);
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
            elsif run("branch on equal branches when equal") then
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchEq <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait until rising_edge(clk);
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
                check(not justBranched);
                wait until falling_edge(clk);
                check(justBranched);
            elsif run("branch on equal does not branch when not equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchEq <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait until rising_edge(clk);
                check(not overrideProgramCounter);
            elsif run("Branch on not equal branches when not equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchNe <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait until rising_edge(clk);
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("Branch on not equal does not branch when equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(20, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchNe <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait until rising_edge(clk);
                check(not overrideProgramCounter);
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
        rtData => rtData,
        immidiate => immidiate,
        destinationReg => destinationReg,
        aluFunction => aluFunction,
        shamt => shamt,
        programCounterPlusFour => programCounterPlusFour,
        rdAddress => 0,
        memoryControlWordToMem => memoryControlWordToMem,
        writeBackControlWordToMem => writeBackControlWordToMem,
        execResult => execResult,
        regDataRead => regDataRead,
        destinationRegToMem => destinationRegToMem,
        overrideProgramCounter => overrideProgramCounter,
        newProgramCounter => newProgramCounter,
        justBranched => justBranched
    );

end architecture;
