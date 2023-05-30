library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_pipeline_instructionDecode is
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        -- From/to instruction fetch
        instructionFromInstructionDecode : in mips32_instruction_type;
        programCounterPlusFour : in mips32_address_type;
        overrideProgramCounter : out boolean;
        repeatInstruction : out boolean;
        newProgramCounter : out mips32_address_type;

        -- To execute stage: control signals
        writeBackControlWord : out mips32_WriteBackControlWord_type;
        memoryControlWord : out mips32_MemoryControlWord_type;
        executeControlWord : out mips32_ExecuteControlWord_type;

        -- To execute stage: data
        rsData : out mips32_data_type;
        rsAddress : out mips32_registerFileAddress_type;
        rtData : out mips32_data_type;
        rtAddress : out mips32_registerFileAddress_type;
        immidiate : out mips32_data_type;
        destinationReg : out mips32_registerFileAddress_type;
        aluFunction : out mips32_aluFunction_type;
        shamt : out mips32_shamt_type;

        -- From execute stage: Hazard detection data
        exInstructionIsMemLoad : in boolean;
        exInstructionTargetReg : in mips32_registerFileAddress_type;

        -- From writeBack stage: data
        regWrite : in boolean;
        regWriteAddress : in mips32_registerFileAddress_type;
        regWriteData : in mips32_data_type
    );
end entity;

architecture behaviourial of mips32_pipeline_instructionDecode is
    -- Control interaction
    signal opcode : mips32_opcode_type;
    signal decodedInstructionDecodeControlWord : mips32_InstructionDecodeControlWord_type;
    signal decodedExecuteControlWord : mips32_ExecuteControlWord_type;
    signal decodedMemoryControlWord : mips32_MemoryControlWord_type;
    signal decodedWriteBackControlWord : mips32_WriteBackControlWord_type;

    -- Registerfile interaction
    signal readPortOneAddress : mips32_registerFileAddress_type;
    signal readPortOneData : mips32_data_type;
    signal readPortTwoAddress : mips32_registerFileAddress_type;
    signal readPortTwoData : mips32_data_type;

    signal jumpTarget : mips32_address_type;
    signal branchTarget : mips32_address_type;
    signal registerReadsAreEqual : boolean;
    signal immidiate_buf : mips32_data_type;
    signal destinationReg_buf : mips32_registerFileAddress_type;
    signal aluFunction_buf : mips32_aluFunction_type;
    signal shamt_buf : mips32_shamt_type;

    signal loadHazardDetected : boolean := false;
begin
    opcode <= to_integer(unsigned(instructionFromInstructionDecode(31 downto 26)));
    readPortOneAddress <= to_integer(unsigned(instructionFromInstructionDecode(25 downto 21)));
    readPortTwoAddress <= to_integer(unsigned(instructionFromInstructionDecode(20 downto 16)));
    registerReadsAreEqual <= readPortOneData = readPortTwoData;
    immidiate_buf <= std_logic_vector(resize(signed(instructionFromInstructionDecode(15 downto 0)), immidiate'length));
    shamt_buf <= to_integer(unsigned(instructionFromInstructionDecode(10 downto 6)));
    aluFunction_buf <= to_integer(unsigned(instructionFromInstructionDecode(5 downto 0)));
    repeatInstruction <= loadHazardDetected;

    determineDestinationReg : process(instructionFromInstructionDecode, decodedInstructionDecodeControlWord)
    begin
        if decodedInstructionDecodeControlWord.regDst then
            destinationReg_buf <= to_integer(unsigned(instructionFromInstructionDecode(15 downto 11)));
        else
            destinationReg_buf <= to_integer(unsigned(instructionFromInstructionDecode(20 downto 16)));
        end if;
    end process;


    handleProgramCounterOverride : process(decodedInstructionDecodeControlWord, registerReadsAreEqual, jumpTarget, branchTarget)
    begin
        if decodedInstructionDecodeControlWord.jump then
            overrideProgramCounter <= true;
            newProgramCounter <= jumpTarget;
        elsif decodedInstructionDecodeControlWord.branch and registerReadsAreEqual then
            overrideProgramCounter <= true;
            newProgramCounter <= branchTarget;
        else
            overrideProgramCounter <= false;
            newProgramCounter <= (others => 'X');
        end if;
    end process;

    determineJumpTarget : process(instructionFromInstructionDecode, programCounterPlusFour)
        variable outputAddress : mips32_address_type;
    begin
        outputAddress(1 downto 0) := (others => '0');
        outputAddress(27 downto 2) := instructionFromInstructionDecode(25 downto 0);
        outputAddress(31 downto 28) := programCounterPlusFour(31 downto 28);
        jumpTarget <= outputAddress;
    end process;

    determineBranchTarget : process(programCounterPlusFour, immidiate_buf)
        variable pcPlusFourAsSigned : signed(mips32_address_type'range);
        variable immidiateAsSigned : signed(mips32_data_type'range);
    begin
        pcPlusFourAsSigned := signed(programCounterPlusFour);
        immidiateAsSigned := signed(immidiate_buf);
        branchTarget <= std_logic_vector(pcPlusFourAsSigned + shift_left(immidiateAsSigned, 2));
    end process;

    detectLoadHazard : process(exInstructionIsMemLoad, exInstructionTargetReg, readPortOneAddress, readPortTwoAddress)
    begin
        loadHazardDetected <= exInstructionIsMemLoad and
                              (exInstructionTargetReg = readPortOneAddress or exInstructionTargetReg = readPortTwoAddress);
    end process;

    handleIDEXReg : process(clk)
        variable writeBackControlWord_var : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
        variable memoryControlWord_var : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
        variable executeControlWord_var : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                writeBackControlWord_var := mips32_writeBackControlWordAllFalse;
                memoryControlWord_var := mips32_memoryControlWordAllFalse;
                executeControlWord_var := mips32_executeControlWordAllFalse;
            elsif not stall then
                if loadHazardDetected then
                    writeBackControlWord_var := mips32_writeBackControlWordAllFalse;
                    memoryControlWord_var := mips32_memoryControlWordAllFalse;
                    executeControlWord_var := mips32_executeControlWordAllFalse;
                else
                    writeBackControlWord_var := decodedWriteBackControlWord;
                    memoryControlWord_var := decodedMemoryControlWord;
                    executeControlWord_var := decodedExecuteControlWord;
                    rsData <= readPortOneData;
                    rsAddress <= readPortOneAddress;
                    rtData <= readPortTwoData;
                    rtAddress <= readPortTwoAddress;
                    immidiate <= immidiate_buf;
                    destinationReg <= destinationReg_buf;
                    aluFunction <= aluFunction_buf;
                    shamt <= shamt_buf;
                end if;
            end if;
        end if;
        writeBackControlWord <= writeBackControlWord_var;
        memoryControlWord <= memoryControlWord_var;
        executeControlWord <= executeControlWord_var;
    end process;

    controlDecode : entity work.mips32_control
    port map (
        opcode => opcode,
        instructionDecodeControlWord => decodedInstructionDecodeControlWord,
        executeControlWord => decodedExecuteControlWord,
        memoryControlWord => decodedMemoryControlWord,
        writeBackControlWord => decodedWriteBackControlWord
    );

    registerFile : entity work.mips32_registerFile
    port map (
        clk => clk,
        readPortOneAddress => readPortOneAddress,
        readPortOneData => readPortOneData,
        readPortTwoAddress => readPortTwoAddress,
        readPortTwoData => readPortTwoData,
        writePortDoWrite => regWrite,
        writePortAddress => regWriteAddress,
        writePortData => regWriteData
    );
end architecture;
