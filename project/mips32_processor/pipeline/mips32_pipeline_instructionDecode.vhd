library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_pipeline_instructionDecode is
    port (
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
        rsAddress : out mips32_registerFileAddress_type;
        rtAddress : out mips32_registerFileAddress_type;
        immidiate : out mips32_data_type;
        destinationReg : out mips32_registerFileAddress_type;
        rdAddress : out mips32_registerFileAddress_type;
        shamt : out mips32_shamt_type;

        -- From load hazard detected
        loadHazardDetected : in boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_instructionDecode is
    -- Control interaction
    signal decodedInstructionDecodeControlWord : mips32_InstructionDecodeControlWord_type;
    signal decodedExecuteControlWord : mips32_ExecuteControlWord_type;
    signal decodedMemoryControlWord : mips32_MemoryControlWord_type;
    signal decodedWriteBackControlWord : mips32_WriteBackControlWord_type;

    signal jumpTarget : mips32_address_type;
    signal immidiate_buf : mips32_data_type;
    signal destinationReg_buf : mips32_registerFileAddress_type;

    signal overrideProgramCounter_buf : boolean := false;

    signal rtAddress_buf : mips32_registerFileAddress_type;
    signal rdAddress_buf : mips32_registerFileAddress_type;
begin
    repeatInstruction <= loadHazardDetected;
    overrideProgramCounter <= decodedInstructionDecodeControlWord.jump;
    newProgramCounter <= jumpTarget;

    rtAddress_buf <= to_integer(unsigned(instructionFromInstructionFetch(20 downto 16)));
    rdAddress_buf <= to_integer(unsigned(instructionFromInstructionFetch(15 downto 11)));

    nopOutput <= loadHazardDetected;
    writeBackControlWord <= decodedWriteBackControlWord;
    memoryControlWord <= decodedMemoryControlWord;
    executeControlWord <= decodedExecuteControlWord;
    rsAddress <= to_integer(unsigned(instructionFromInstructionFetch(25 downto 21)));
    rtAddress <= rtAddress_buf;
    immidiate <= immidiate_buf;
    destinationReg <= destinationReg_buf;
    rdAddress <= rdAddress_buf;
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
        opcode => to_integer(unsigned(instructionFromInstructionFetch(31 downto 26))),
        mf => to_integer(unsigned(instructionFromInstructionFetch(25 downto 21))),
        func => to_integer(unsigned(instructionFromInstructionFetch(5 downto 0))),
        regimm => to_integer(unsigned(instructionFromInstructionFetch(20 downto 16))),
        instructionDecodeControlWord => decodedInstructionDecodeControlWord,
        executeControlWord => decodedExecuteControlWord,
        memoryControlWord => decodedMemoryControlWord,
        writeBackControlWord => decodedWriteBackControlWord
    );

end architecture;
