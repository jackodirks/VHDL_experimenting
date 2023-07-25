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
    signal executeControlWord : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;

    signal rsData : mips32_data_type;
    signal rtData : mips32_data_type;
    signal immidiate : mips32_data_type;
    signal aluFunction : mips32_aluFunction_type;
    signal shamt : mips32_shamt_type;
    signal programCounterPlusFour : mips32_address_type;

    signal execResult : mips32_data_type;

    signal overrideProgramCounter : boolean;
    signal newProgramCounter : mips32_address_type;
begin
    main : process
        variable expectedExecResult : mips32_data_type;
        variable expectedDestinationRegToMem : mips32_registerFileAddress_type;
        variable expectedRegDataRead : mips32_data_type;
        variable expectedBranchTarget : mips32_address_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("R-type subtract function works") then
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                rtData <= std_logic_vector(to_signed(10, rtData'length));
                executeControlWord.isRtype <= true;
                aluFunction <= mips32_aluFunctionSubtract;
                expectedExecResult := std_logic_vector(to_signed(90, expectedExecResult'length));
                expectedDestinationRegToMem := 13;
                wait for 10 ns;
                check_equal(execResult, expectedExecResult);
            elsif run("I-type add instructions work") then
                rsData <= std_logic_vector(to_signed(32, rsData'length));
                rtData <= std_logic_vector(to_signed(255, rtData'length));
                immidiate <= std_logic_vector(to_signed(-4, immidiate'length));
                executeControlWord.ALUSrc <= true;
                executeControlWord.ALUOpDirective <= exec_add;
                expectedExecResult := std_logic_vector(to_signed(28, expectedExecResult'length));
                expectedDestinationRegToMem := 26;
                expectedRegDataRead := std_logic_vector(to_signed(255, expectedRegDataRead'length));
                wait for 10 ns;
                check_equal(execResult, expectedExecResult);
            elsif run("branch on equal branches when equal") then
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchEq <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("branch on equal does not branch when not equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchEq <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("Branch on not equal branches when not equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchNe <= true;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
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
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("Jump on jr") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                aluFunction <= mips32_aluFunctionJumpReg;
                executeControlWord.isRtype <= true;
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(rsData, newProgramCounter);
            elsif run("No jump if not rtype") then
                aluFunction <= mips32_aluFunctionJumpReg;
                executeControlWord.isRtype <= false;
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("branch target is correct when alufunc is jumpReg") then
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                executeControlWord.ALUOpDirective <= exec_sub;
                executeControlWord.branchEq <= true;
                aluFunction <= mips32_aluFunctionJumpReg;
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check_equal(newProgramCounter, expectedBranchTarget);
            end if;
        end loop;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    executeStage : entity src.mips32_pipeline_execute
    port map (
        executeControlWord => executeControlWord,
        rsData => rsData,
        rtData => rtData,
        immidiate => immidiate,
        aluFunction => aluFunction,
        shamt => shamt,
        programCounterPlusFour => programCounterPlusFour,
        execResult => execResult,
        overrideProgramCounter => overrideProgramCounter,
        newProgramCounter => newProgramCounter
    );

end architecture;
