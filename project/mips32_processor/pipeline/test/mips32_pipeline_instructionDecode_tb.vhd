library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg;
use src.mips32_pkg;

entity mips32_pipeline_instructionDecode_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_instructionDecode_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stall : boolean := false;

    signal instructionFromInstructionDecode : mips32_pkg.instruction_type := (others => '1');
    signal programCounterPlusFour : mips32_pkg.address_type := (others => '1');
    signal overrideProgramCounter : boolean;
    signal newProgramCounter : mips32_pkg.address_type;

    signal writeBackControlWord : mips32_pkg.WriteBackControlWord_type;
    signal memoryControlWord : mips32_pkg.MemoryControlWord_type;
    signal executeControlWord : mips32_pkg.ExecuteControlWord_type;

    signal regDataA : mips32_pkg.data_type;
    signal regDataB : mips32_pkg.data_type;
    signal immidiate : mips32_pkg.immidiate_type;
    signal destinationReg : mips32_pkg.registerFileAddress_type;
    signal aluFunction : mips32_pkg.aluFunction_type;
    signal shamt : mips32_pkg.shamt_type;

    signal regWrite : boolean := false;
    signal regWriteAddress : mips32_pkg.registerFileAddress_type := 16#0#;
    signal regWriteData : mips32_pkg.data_type := (others => '0');
begin
    clk <= not clk after (clk_period/2);

    main : process
        variable instructionIn : mips32_pkg.instruction_type;
        variable expectedJumpTarget : mips32_pkg.address_type;
        variable inputAddress : mips32_pkg.address_type;
        variable expectedRegDataA : mips32_pkg.data_type;
        variable expectedRegDataB : mips32_pkg.data_type;
        variable expectedDestinationReg : mips32_pkg.registerFileAddress_type;
        variable expectedAluFunction : mips32_pkg.aluFunction_type;
        variable expectedShamt : mips32_pkg.shamt_type;
        variable expectedImmidiate : mips32_pkg.immidiate_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Jump instruction works") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeJ, 6));
                instructionIn(25 downto 1) := (others => '0');
                instructionIn(0) := '1';
                expectedJumpTarget := (others => '0');
                expectedJumpTarget(31 downto 28) := (others => '1');
                expectedJumpTarget(2) := '1';
                wait until rising_edge(clk);
                instructionFromInstructionDecode <= instructionIn;
                programCounterPlusFour <= (others => '1');
                wait until falling_edge(clk);
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedJumpTarget);
            elsif run("beq should branch on equal") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeBeq, 6));
                instructionIn(25 downto 16) := (others => '0');
                instructionIn(15 downto 0) := std_logic_vector(to_signed(-1, 16));
                inputAddress := std_logic_vector(to_unsigned(16, inputAddress'length));
                expectedJumpTarget := std_logic_vector(to_unsigned(12, expectedJumpTarget'length));
                wait until rising_edge(clk);
                programCounterPlusFour <= inputAddress;
                instructionFromInstructionDecode <= instructionIn;
                wait until falling_edge(clk);
                check(overrideProgramCounter);
                check_equal(newProgramCounter, expectedJumpTarget);
            elsif run("beq should not branch on not equal") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeBeq, 6));
                instructionIn(25 downto 21) := (others => '0');
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 0) := std_logic_vector(to_signed(10, 16));
                inputAddress := std_logic_vector(to_unsigned(16, inputAddress'length));
                wait until rising_edge(clk);
                programCounterPlusFour <= inputAddress;
                instructionFromInstructionDecode <= instructionIn;
                regWrite <= true;
                regWriteAddress <= 1;
                regWriteData <= std_logic_vector(to_unsigned(1, regWriteData'length));
                wait until falling_edge(clk);
                check(not overrideProgramCounter);
            elsif run("R-type instructions work") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                expectedRegDataA := std_logic_vector(to_unsigned(11, expectedRegDataA'length));
                expectedRegDataB := std_logic_vector(to_unsigned(12, expectedRegDataB'length));
                expectedDestinationReg := 3;
                expectedAluFunction := 4;
                expectedShamt := 10;
                regWrite <= true;
                regWriteAddress <= 2;
                regWriteData <= expectedRegDataA;
                wait until rising_edge(clk);
                instructionFromInstructionDecode <= instructionIn;
                regWriteAddress <= 1;
                regWriteData <= expectedRegDataB;
                wait until rising_edge(clk);
                instructionFromInstructionDecode <= (others => '1');
                regWrite <= false;
                wait until falling_edge(clk);
                check_equal(regDataA, expectedRegDataA);
                check_equal(regDataB, expectedRegDataB);
                check_equal(destinationReg, expectedDestinationReg);
                check_equal(aluFunction, expectedAluFunction);
                check_equal(shamt, expectedShamt);
                check(not executeControlWord.ALUSrc);
                check(not executeControlWord.ALUOpIsAdd);
                check(not memoryControlWord.MemRead);
                check(not memoryControlWord.MemWrite);
                check(writeBackControlWord.regWrite);
                check(not writeBackControlWord.MemtoReg);
            elsif run("Before the first rising_edge, all control logic should be false") then
                check(not executeControlWord.ALUSrc);
                check(not executeControlWord.ALUOpIsAdd);
                check(not memoryControlWord.MemRead);
                check(not memoryControlWord.MemWrite);
                check(not writeBackControlWord.regWrite);
                check(not writeBackControlWord.MemtoReg);
            elsif run("On reset, all control logic should be reset to false") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                instructionFromInstructionDecode <= instructionIn;
                rst <= '0';
                wait until rising_edge(clk);
                rst <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check(not executeControlWord.ALUSrc);
                check(not executeControlWord.ALUOpIsAdd);
                check(not memoryControlWord.MemRead);
                check(not memoryControlWord.MemWrite);
                check(not writeBackControlWord.regWrite);
                check(not writeBackControlWord.MemtoReg);
            elsif run("On stall, the incoming instruction should be ignored") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeRType, 6));
                instructionIn(25 downto 21) := std_logic_vector(to_unsigned(2, 5));
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(1, 5));
                instructionIn(15 downto 11) := std_logic_vector(to_unsigned(3, 5));
                instructionIn(10 downto 6) := std_logic_vector(to_unsigned(10, 5));
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(4, 6));
                expectedAluFunction := 4;
                instructionFromInstructionDecode <= instructionIn;
                stall <= false;
                wait until rising_edge(clk);
                instructionIn(5 downto 0) := std_logic_vector(to_unsigned(5, 6));
                instructionFromInstructionDecode <= instructionIn;
                stall <= true;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(aluFunction, expectedAluFunction);
            elsif run("Load word behaves as expected") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeLw, 6));
                instructionIn(25 downto 21) := (others => '0');
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(6, 5));
                instructionIn(15 downto 0) := std_logic_vector(to_signed(-32, 16));
                expectedDestinationReg := 6;
                expectedImmidiate := to_signed(-32, expectedImmidiate'length);
                instructionFromInstructionDecode <= instructionIn;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(destinationReg, expectedDestinationReg);
                check_equal(immidiate, expectedImmidiate);
                check(executeControlWord.ALUSrc);
                check(executeControlWord.ALUOpIsAdd);
                check(memoryControlWord.MemRead);
                check(not memoryControlWord.MemWrite);
                check(writeBackControlWord.regWrite);
                check(writeBackControlWord.MemtoReg);
            elsif run("Store word behaves as expected") then
                instructionIn(31 downto 26) := std_logic_vector(to_unsigned(mips32_pkg.opcodeSw, 6));
                instructionIn(25 downto 21) := (others => '0');
                instructionIn(20 downto 16) := std_logic_vector(to_unsigned(12, 5));
                instructionIn(15 downto 0) := std_logic_vector(to_signed(128, 16));
                expectedDestinationReg := 12;
                expectedImmidiate := to_signed(128, expectedImmidiate'length);
                instructionFromInstructionDecode <= instructionIn;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                check_equal(destinationReg, expectedDestinationReg);
                check_equal(immidiate, expectedImmidiate);
                check(executeControlWord.ALUSrc);
                check(executeControlWord.ALUOpIsAdd);
                check(not memoryControlWord.MemRead);
                check(memoryControlWord.MemWrite);
                check(not writeBackControlWord.regWrite);
                check(not writeBackControlWord.MemtoReg);
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
        instructionFromInstructionDecode => instructionFromInstructionDecode,
        programCounterPlusFour => programCounterPlusFour,
        overrideProgramCounter => overrideProgramCounter,
        newProgramCounter => newProgramCounter,
        writeBackControlWord => writeBackControlWord,
        memoryControlWord => memoryControlWord,
        executeControlWord => executeControlWord,
        regDataA => regDataA,
        regDataB => regDataB,
        immidiate => immidiate,
        destinationReg => destinationReg,
        aluFunction => aluFunction,
        shamt => shamt,
        regWrite => regWrite,
        regWriteAddress => regWriteAddress,
        regWriteData => regWriteData
    );
end architecture;