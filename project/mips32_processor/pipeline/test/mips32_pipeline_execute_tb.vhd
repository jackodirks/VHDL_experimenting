library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

library tb;
use tb.mips32_instruction_builder_pkg.all;

entity mips32_pipeline_execute_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_execute_tb is
    signal executeControlWord : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;

    signal rsData : mips32_data_type;
    signal rtData : mips32_data_type;
    signal immidiate : mips32_data_type;
    signal shamt : mips32_shamt_type;
    signal programCounterPlusFour : mips32_address_type;
    signal rdAddress : mips32_registerFileAddress_type := 0;

    signal execResult : mips32_data_type;

    signal overrideProgramCounter : boolean;
    signal newProgramCounter : mips32_address_type;

    signal instruction : mips32_instruction_type := (others => '0');
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
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_special, funct => mips32_function_Subtract);
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                rtData <= std_logic_vector(to_signed(10, rtData'length));
                expectedExecResult := std_logic_vector(to_signed(90, expectedExecResult'length));
                expectedDestinationRegToMem := 13;
                wait for 10 ns;
                check_equal(execResult, expectedExecResult);
            elsif run("I-type add instructions work") then
                rsData <= std_logic_vector(to_signed(32, rsData'length));
                rtData <= std_logic_vector(to_signed(255, rtData'length));
                immidiate <= std_logic_vector(to_signed(-4, immidiate'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Addi);
                expectedExecResult := std_logic_vector(to_signed(28, expectedExecResult'length));
                expectedDestinationRegToMem := 26;
                expectedRegDataRead := std_logic_vector(to_signed(255, expectedRegDataRead'length));
                wait for 10 ns;
                check_equal(execResult, expectedExecResult);
            elsif run("branch on equal branches when equal") then
                rsData <= std_logic_vector(to_signed(100, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_beq);
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("branch on equal does not branch when not equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_beq);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("Branch on not equal branches when not equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(100, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_bne);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("Branch on not equal does not branch when equal") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                rtData <= std_logic_vector(to_signed(20, rtData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_bne);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("Jump on jr") then
                rsData <= std_logic_vector(to_signed(20, rsData'length));
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_special, funct => mips32_function_JumpReg);
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(rsData, newProgramCounter);
            elsif run("bgez branches on 0") then
                rsData <= std_logic_vector(to_signed(0, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_regimm, rt => mips32_regimm_bgez);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("bgez does not branch on -1") then
                rsData <= std_logic_vector(to_signed(-1, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_regimm, rt => mips32_regimm_bgez);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("bgez does branch on 5") then
                rsData <= std_logic_vector(to_signed(5, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_regimm, rt => mips32_regimm_bgez);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("blez branches on 0") then
                rsData <= std_logic_vector(to_signed(0, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_blez);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("blez does not branch on 1") then
                rsData <= std_logic_vector(to_signed(1, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_blez);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("blez branches on -1") then
                rsData <= std_logic_vector(to_signed(-1, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_blez);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("bgtz branches on 5") then
                rsData <= std_logic_vector(to_signed(5, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_bgtz);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("bgtz does not branch on 0") then
                rsData <= std_logic_vector(to_signed(0, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_bgtz);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("bgtz does not branch on -1") then
                rsData <= std_logic_vector(to_signed(-1, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_bgtz);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("bltz branches on -5") then
                rsData <= std_logic_vector(to_signed(-5, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_regimm, rt => mips32_regimm_bltz);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedBranchTarget);
            elsif run("bltz does not branch on 0") then
                rsData <= std_logic_vector(to_signed(0, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_regimm, rt => mips32_regimm_bltz);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
            elsif run("bltz does not branch on 10") then
                rsData <= std_logic_vector(to_signed(10, rsData'length));
                immidiate <= std_logic_vector(to_signed(-1, immidiate'length));
                programCounterPlusFour <= std_logic_vector(to_unsigned(16, programCounterPlusFour'length));
                instruction <= construct_itype_instruction(opcode => mips32_opcode_regimm, rt => mips32_regimm_bltz);
                expectedBranchTarget := std_logic_vector(to_unsigned(12, expectedBranchTarget'length));
                wait for 10 ns;
                check(not overrideProgramCounter);
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
        shamt => shamt,
        programCounterPlusFour => programCounterPlusFour,
        rdAddress => rdAddress,
        execResult => execResult,
        overrideProgramCounter => overrideProgramCounter,
        newProgramCounter => newProgramCounter
    );

    controlDecode : entity src.mips32_control
    port map (
        instruction => instruction,
        executeControlWord => executeControlWord
    );

end architecture;
