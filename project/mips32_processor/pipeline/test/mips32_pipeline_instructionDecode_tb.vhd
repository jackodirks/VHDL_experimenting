library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_pipeline_instructionDecode_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_instructionDecode_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean := false;

    signal instructionFromInstructionFetch : mips32_instruction_type := (others => '1');
    signal programCounterPlusFour : mips32_address_type := (others => '1');
    signal overrideProgramCounter : boolean;
    signal newProgramCounter : mips32_address_type;
    signal repeatInstruction : boolean;

    signal writeBackControlWord : mips32_WriteBackControlWord_type;
    signal memoryControlWord : mips32_MemoryControlWord_type;
    signal executeControlWord : mips32_ExecuteControlWord_type;

    signal rsData : mips32_data_type;
    signal rsAddress : mips32_registerFileAddress_type;
    signal rtData : mips32_data_type;
    signal rtAddress : mips32_registerFileAddress_type;
    signal immidiate : mips32_data_type;
    signal destinationReg : mips32_registerFileAddress_type;
    signal aluFunction : mips32_aluFunction_type;
    signal shamt : mips32_shamt_type;

    signal exInstructionIsMemLoad : boolean;
    signal exInstructionTargetReg : mips32_registerFileAddress_type;

    signal regWrite : boolean := false;
    signal regWriteAddress : mips32_registerFileAddress_type := 16#0#;
    signal regWriteData : mips32_data_type := (others => '0');

    signal ignoreCurrentInstruction : boolean := false;
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable instructionIn : mips32_instruction_type;
        variable expectedJumpTarget : mips32_address_type;
        variable inputAddress : mips32_address_type;
        variable expectedRsData : mips32_data_type;
        variable expectedRtData : mips32_data_type;
        variable expectedDestinationReg : mips32_registerFileAddress_type;
        variable expectedAluFunction : mips32_aluFunction_type;
        variable expectedShamt : mips32_shamt_type;
        variable expectedImmidiate : mips32_data_type;
        variable expectedRsAddress : mips32_registerFileAddress_type;
        variable expectedRtAddress : mips32_registerFileAddress_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Jump instruction works") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeJ, 6));
                instructionIn(25 downto 1) := (others => '0');
                instructionIn(0) := '1';
                expectedJumpTarget := (others => '0');
                expectedJumpTarget(31 downto 28) := (others => '1');
                expectedJumpTarget(2) := '1';
                instructionFromInstructionFetch <= instructionIn;
                wait until rising_edge(clk);
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedJumpTarget);
            elsif run("R-type instructions work") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                expectedRsData := std_logic_vector(to_unsigned(11, expectedRsData'length));
                expectedRtData := std_logic_vector(to_unsigned(12, expectedRtData'length));
                expectedDestinationReg := 3;
                expectedAluFunction := 4;
                expectedShamt := 10;
                regWrite <= true;
                regWriteAddress <= 2;
                regWriteData <= expectedRsData;
                wait until rising_edge(clk);
                instructionFromInstructionFetch <= instructionIn;
                regWriteAddress <= 1;
                regWriteData <= expectedRtData;
                wait until rising_edge(clk);
                instructionFromInstructionFetch <= (others => '1');
                regWrite <= false;
                wait until falling_edge(clk);
                check_equal(rsData, expectedRsData);
                check_equal(rtData, expectedRtData);
                check_equal(destinationReg, expectedDestinationReg);
                check_equal(aluFunction, expectedAluFunction);
                check_equal(shamt, expectedShamt);
                check(executeControlWord = mips32_executeControlWordAllFalse);
                check(memoryControlWord = mips32_memoryControlWordAllFalse);
                check(writeBackControlWord.regWrite);
                check(not writeBackControlWord.MemtoReg);
            elsif run("Before the first rising_edge, all control logic should be false") then
                check(executeControlWord = mips32_executeControlWordAllFalse);
                check(memoryControlWord = mips32_memoryControlWordAllFalse);
                check(writeBackControlWord = mips32_writeBackControlWordAllFalse);
            elsif run("On reset, all control logic should be reset to false") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionFetch <= instructionIn;
                rst <= '0';
                wait until rising_edge(clk);
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(executeControlWord = mips32_executeControlWordAllFalse);
                check(memoryControlWord = mips32_memoryControlWordAllFalse);
                check(writeBackControlWord = mips32_writeBackControlWordAllFalse);
            elsif run("On stall, the incoming instruction should be ignored") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                expectedAluFunction := 4;
                instructionFromInstructionFetch <= instructionIn;
                stall <= false;
                wait until rising_edge(clk);
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(5, 6));
                instructionFromInstructionFetch <= instructionIn;
                stall <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(aluFunction, expectedAluFunction);
            elsif run("Load word behaves as expected") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeLw, 6));
                instructionIn(25 downto 21) := (others => '0');
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(6, 5));
                instructionIn(15 downto 0) := std_logic_vector(to_signed(-32, 16));
                expectedDestinationReg := 6;
                expectedImmidiate := std_logic_vector(to_signed(-32, expectedImmidiate'length));
                instructionFromInstructionFetch <= instructionIn;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(destinationReg, expectedDestinationReg);
                check_equal(immidiate, expectedImmidiate);
                check(executeControlWord.ALUSrc);
                check(executeControlWord.ALUOpDirective = exec_add);
                check(memoryControlWord.MemOp);
                check(not memoryControlWord.MemOpIsWrite);
                check(writeBackControlWord.regWrite);
                check(writeBackControlWord.MemtoReg);
            elsif run("Store word behaves as expected") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeSw, 6));
                instructionIn(25 downto 21) := (others => '0');
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(12, 5));
                instructionIn(15 downto 0) := std_logic_vector(to_signed(128, 16));
                expectedDestinationReg := 12;
                expectedImmidiate := std_logic_vector(to_signed(128, expectedImmidiate'length));
                instructionFromInstructionFetch <= instructionIn;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(destinationReg, expectedDestinationReg);
                check_equal(immidiate, expectedImmidiate);
                check(executeControlWord.ALUSrc);
                check(executeControlWord.ALUOpDirective = exec_add);
                check(memoryControlWord.MemOp);
                check(memoryControlWord.MemOpIsWrite);
                check(writeBackControlWord = mips32_writeBackControlWordAllFalse);
            elsif run("ID forwards registerAddresses") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionFetch <= instructionIn;
                expectedRsAddress := 2;
                expectedRtAddress := 1;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(rsAddress, expectedRsAddress);
                check_equal(rtAddress, expectedRtAddress);
            elsif run("Dependend R-type after load word causes repeat") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionFetch <= instructionIn;
                exInstructionIsMemLoad <= true;
                exInstructionTargetReg <= 2;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(repeatInstruction);
                check(executeControlWord = mips32_executeControlWordAllFalse);
                check(memoryControlWord = mips32_memoryControlWordAllFalse);
                check(writeBackControlWord = mips32_writeBackControlWordAllFalse);
            elsif run("Dependend R-type after load word during stall does not reset controlwords") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionFetch <= instructionIn;
                exInstructionIsMemLoad <= false;
                exInstructionTargetReg <= 2;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(writeBackControlWord.regWrite);
                stall <= true;
                exInstructionIsMemLoad <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(writeBackControlWord.regWrite);
            elsif run("Inependend R-type after load word does not cause repeat") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionFetch <= instructionIn;
                exInstructionIsMemLoad <= true;
                exInstructionTargetReg <= 6;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not repeatInstruction);
            elsif run("ignoreCurrentInstruction works") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionFetch <= instructionIn;
                ignoreCurrentInstruction <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not writeBackControlWord.regWrite);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    instructionDecode : entity src.mips32_pipeline_instructionDecode
    port map (
        clk => clk,
        rst => rst,
        stall => stall,
        instructionFromInstructionFetch => instructionFromInstructionFetch,
        programCounterPlusFour => programCounterPlusFour,
        overrideProgramCounter => overrideProgramCounter,
        repeatInstruction => repeatInstruction,
        newProgramCounter => newProgramCounter,
        writeBackControlWord => writeBackControlWord,
        memoryControlWord => memoryControlWord,
        executeControlWord => executeControlWord,
        rsData => rsData,
        rsAddress => rsAddress,
        rtData => rtData,
        rtAddress => rtAddress,
        immidiate => immidiate,
        destinationReg => destinationReg,
        aluFunction => aluFunction,
        shamt => shamt,
        exInstructionIsMemLoad => exInstructionIsMemLoad,
        exInstructionTargetReg => exInstructionTargetReg,
        regWrite => regWrite,
        regWriteAddress => regWriteAddress,
        regWriteData => regWriteData,
        ignoreCurrentInstruction => ignoreCurrentInstruction
    );
end architecture;
