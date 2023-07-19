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
        -- From/to instruction fetch: control
        overrideProgramCounter : out boolean;
        repeatInstruction : out boolean;

        -- From instruction fetch: data
        instructionFromInstructionFetch : in mips32_instruction_type;
        programCounterPlusFour : in mips32_address_type;

        -- To instruction fetch: data
        newProgramCounter : out mips32_address_type;

        -- To id/ex register: control
        nopOutput : out boolean;

        -- Data output
        executeControlWord : out mips32_ExecuteControlWord_type;
        memoryControlWord : out mips32_MemoryControlWord_type;
        writeBackControlWord : out mips32_WriteBackControlWord_type;
        rsData : out mips32_data_type;
        rsAddress : out mips32_registerFileAddress_type;
        rtData : out mips32_data_type;
        rtAddress : out mips32_registerFileAddress_type;
        immidiate : out mips32_data_type;
        destinationReg : out mips32_registerFileAddress_type;
        rdAddress : out mips32_registerFileAddress_type;
        aluFunction : out mips32_aluFunction_type;
        shamt : out mips32_shamt_type;

        -- From load hazard detected
        loadHazardDetected : in boolean;

        -- From writeBack stage: data
        regWrite : in boolean;
        regWriteAddress : in mips32_registerFileAddress_type;
        regWriteData : in mips32_data_type;

        -- From execute: control
        ignoreCurrentInstruction : in boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_instructionDecode is
    -- Control interaction
    signal opcode : mips32_opcode_type;
    signal mf : mips32_mf_type;
    signal decodedInstructionDecodeControlWord : mips32_InstructionDecodeControlWord_type;
    signal decodedExecuteControlWord : mips32_ExecuteControlWord_type;
    signal decodedMemoryControlWord : mips32_MemoryControlWord_type;
    signal decodedWriteBackControlWord : mips32_WriteBackControlWord_type;

    -- Registerfile interaction
    signal readPortOneData : mips32_data_type;
    signal readPortTwoData : mips32_data_type;

    signal jumpTarget : mips32_address_type;
    signal immidiate_buf : mips32_data_type;
    signal destinationReg_buf : mips32_registerFileAddress_type;

    signal overrideProgramCounter_buf : boolean := false;

    signal rsAddress_buf : mips32_registerFileAddress_type;
    signal rtAddress_buf : mips32_registerFileAddress_type;
    signal rdAddress_buf : mips32_registerFileAddress_type;
begin
    opcode <= to_integer(unsigned(instructionFromInstructionFetch(31 downto 26)));
    mf <= to_integer(unsigned(instructionFromInstructionFetch(25 downto 21)));
    repeatInstruction <= loadHazardDetected and not ignoreCurrentInstruction;
    overrideProgramCounter <= decodedInstructionDecodeControlWord.jump and not ignoreCurrentInstruction;
    newProgramCounter <= jumpTarget;

    rsAddress_buf <= to_integer(unsigned(instructionFromInstructionFetch(25 downto 21)));
    rtAddress_buf <= to_integer(unsigned(instructionFromInstructionFetch(20 downto 16)));
    rdAddress_buf <= to_integer(unsigned(instructionFromInstructionFetch(15 downto 11)));

    nopOutput <= loadHazardDetected or ignoreCurrentInstruction;
    writeBackControlWord <= decodedWriteBackControlWord;
    memoryControlWord <= decodedMemoryControlWord;
    executeControlWord <= decodedExecuteControlWord;
    rsData <= readPortOneData;
    rsAddress <= rsAddress_buf;
    rtData <= readPortTwoData;
    rtAddress <= rtAddress_buf;
    immidiate <= immidiate_buf;
    destinationReg <= destinationReg_buf;
    rdAddress <= rdAddress_buf;
    aluFunction <= to_integer(unsigned(instructionFromInstructionFetch(5 downto 0)));
    shamt <= to_integer(unsigned(instructionFromInstructionFetch(10 downto 6)));

    determineDestinationReg : process(rtAddress_buf, rdAddress_buf, decodedInstructionDecodeControlWord)
    begin
        if decodedInstructionDecodeControlWord.jump then
            destinationReg_buf <= 31;
        elsif decodedInstructionDecodeControlWord.regDstIsRd then
            destinationReg_buf <= rdAddress_buf;
        else
            destinationReg_buf <= rtAddress_buf;
        end if;
    end process;

    determineImmidiate : process(instructionFromInstructionFetch, decodedInstructionDecodeControlWord, programCounterPlusFour)
    begin
        if decodedInstructionDecodeControlWord.jump then
            immidiate_buf <= std_logic_vector(unsigned(programCounterPlusFour) + 4);
        else
            immidiate_buf <= std_logic_vector(resize(signed(instructionFromInstructionFetch(15 downto 0)), immidiate'length));
        end if;
    end process;

    determineJumpTarget : process(instructionFromInstructionFetch, programCounterPlusFour)
        variable outputAddress : mips32_address_type;
    begin
        outputAddress(1 downto 0) := (others => '0');
        outputAddress(27 downto 2) := instructionFromInstructionFetch(25 downto 0);
        outputAddress(31 downto 28) := programCounterPlusFour(31 downto 28);
        jumpTarget <= outputAddress;
    end process;

    controlDecode : entity work.mips32_control
    port map (
        opcode => opcode,
        mf => mf,
        instructionDecodeControlWord => decodedInstructionDecodeControlWord,
        executeControlWord => decodedExecuteControlWord,
        memoryControlWord => decodedMemoryControlWord,
        writeBackControlWord => decodedWriteBackControlWord
    );

    registerFile : entity work.mips32_registerFile
    port map (
        clk => clk,
        readPortOneAddress => rsAddress_buf,
        readPortOneData => readPortOneData,
        readPortTwoAddress => rtAddress_buf,
        readPortTwoData => readPortTwoData,
        writePortDoWrite => regWrite,
        writePortAddress => regWriteAddress,
        writePortData => regWriteData
    );
end architecture;
