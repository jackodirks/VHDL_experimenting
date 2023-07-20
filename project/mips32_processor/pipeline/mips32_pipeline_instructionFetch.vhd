library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_pipeline_instructionFetch is
    generic (
        startAddress : mips32_address_type
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        requestFromBusAddress : out mips32_address_type;
        instructionToInstructionDecode : out mips32_instruction_type;
        ignoreCurrentInstruction : out boolean;
        programCounterPlusFour : out mips32_address_type;
        instructionFromBus : in mips32_instruction_type;

        overrideProgramCounterFromID : in boolean;
        newProgramCounterFromID : in mips32_address_type;

        overrideProgramCounterFromEx : in boolean;
        newProgramCounterFromEx : in mips32_address_type;

        stall : in boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_instructionFetch is
    signal programCounter : mips32_address_type := startAddress;
    signal programCounterPlusFour_buf : mips32_address_type;
    signal nextProgramCounter : mips32_address_type;
begin

    requestFromBusAddress <= programCounter;

    determineProgramCounterPlusFour : process(programCounter)
    begin
        programCounterPlusFour_buf <= std_logic_vector(unsigned(programCounter) + 4);
    end process;

    determineNextProgramCounter : process(overrideProgramCounterFromID, newProgramCounterFromID, overrideProgramCounterFromEx,
                                          newProgramCounterFromEx, programCounterPlusFour_buf)
    begin
        if overrideProgramCounterFromEx then
            nextProgramCounter <= newProgramCounterFromEx;
        elsif overrideProgramCounterFromID then
            nextProgramCounter <= newProgramCounterFromID;
        else
            nextProgramCounter <= programCounterPlusFour_buf;
        end if;
    end process;

    programCounterControl : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                programCounter <= startAddress;
            elsif stall then
                -- pass
            else
                programCounter <= nextProgramCounter;
            end if;
        end if;
    end process;

    IFIDRegs : process(clk)
        variable instructionBuf : mips32_instruction_type := mips32_instructionNop;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                instructionBuf := mips32_instructionNop;
            elsif not stall then
                programCounterPlusFour <= programCounterPlusFour_buf;
                instructionBuf := instructionFromBus;
                ignoreCurrentInstruction <= overrideProgramCounterFromEx;
            end if;
        end if;
        instructionToInstructionDecode <= instructionBuf;
    end process;
end architecture;
