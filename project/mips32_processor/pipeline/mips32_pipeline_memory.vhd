library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_memory is
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        -- From execute stage: control signals
        writeBackControlWord : in mips32_WriteBackControlWord_type;
        memoryControlWord : in mips32_MemoryControlWord_type;

        -- From execute stage: data
        execResult : in mips32_data_type;
        regDataRead : in mips32_data_type;
        destinationReg : in mips32_registerFileAddress_type;
        rdAddress : in mips32_registerFileAddress_type;

        -- To writeback stage: control signals
        writeBackControlWordToWriteBack : out mips32_WriteBackControlWord_type;

        -- To writeback stage: data
        execResultToWriteback : out mips32_data_type;
        memDataReadToWriteback : out mips32_data_type;
        destinationRegToWriteback : out mips32_registerFileAddress_type;

        -- To mem2bus unit
        doMemRead : out boolean;
        doMemWrite : out boolean;
        memAddress : out mips32_address_type;
        dataToMem : out mips32_data_type;
        dataFromMem : in mips32_data_type;

        -- To coprocessor 0
        address_to_cpz : out natural range 0 to 31;
        write_to_cpz : out boolean;
        data_to_cpz : out mips32_data_type;
        data_from_cpz : in mips32_data_type
    );
end entity;

architecture behaviourial of mips32_pipeline_memory is
begin
    mem2busOut : process(memoryControlWord, execResult, regDataRead)
    begin
        doMemRead <= false;
        doMemWrite <= false;
        dataToMem <= regDataRead;
        memAddress <= execResult;
        if memoryControlWord.MemOp then
            if memoryControlWord.MemOpIsWrite then
                doMemWrite <= true;
            else
                doMemRead <= true;
            end if;
        end if;
    end process;

    cpzOut : process(memoryControlWord, execResult, destinationReg, stall)
    begin
        address_to_cpz <= rdAddress;
        write_to_cpz <= memoryControlWord.cop0Write and not stall;
        data_to_cpz <= execResult;
    end process;

    MemWBRegs : process(clk)
        variable writeBackControlWordToWriteBack_buf : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                writeBackControlWordToWriteBack_buf := mips32_writeBackControlWordAllFalse;
            elsif not stall then
                writeBackControlWordToWriteBack_buf := writeBackControlWord;
                execResultToWriteback <= execResult;
                destinationRegToWriteback <= destinationReg;
                memDataReadToWriteback <= dataFromMem;
            end if;
        end if;
        writeBackControlWordToWriteBack <= writeBackControlWordToWriteBack_buf;
    end process;
end architecture;
