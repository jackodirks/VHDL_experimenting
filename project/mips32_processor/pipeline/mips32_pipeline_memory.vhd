library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg;

entity mips32_pipeline_memory is
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        -- From execute stage: control signals
        writeBackControlWord : in mips32_pkg.WriteBackControlWord_type;
        memoryControlWord : in mips32_pkg.MemoryControlWord_type;

        -- From execute stage: data
        aluResult : in mips32_pkg.data_type;
        regDataRead : in mips32_pkg.data_type;
        destinationReg : in mips32_pkg.registerFileAddress_type;

        -- To writeback stage: control signals
        writeBackControlWordToWriteBack : out mips32_pkg.WriteBackControlWord_type;

        -- To writeback stage: data
        aluResultToWriteback : out mips32_pkg.data_type;
        memDataReadToWriteback : out mips32_pkg.data_type;
        destinationRegToWriteback : out mips32_pkg.registerFileAddress_type;

        -- To mem2bus unit
        doMemRead : out boolean;
        doMemWrite : out boolean;
        memAddress : out mips32_pkg.address_type;
        dataToMem : out mips32_pkg.data_type;
        dataFromMem : in mips32_pkg.data_type
    );
end entity;

architecture behaviourial of mips32_pipeline_memory is
begin
    mem2busOut : process(memoryControlWord, aluResult, regDataRead)
    begin
        doMemRead <= false;
        doMemWrite <= false;
        dataToMem <= regDataRead;
        memAddress <= aluResult;
        if memoryControlWord.MemOp then
            if memoryControlWord.MemOpIsWrite then
                doMemWrite <= true;
            else
                doMemRead <= true;
            end if;
        end if;
    end process;

    MemWBRegs : process(clk)
        variable writeBackControlWordToWriteBack_buf : mips32_pkg.WriteBackControlWord_type := mips32_pkg.writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                writeBackControlWordToWriteBack_buf := mips32_pkg.writeBackControlWordAllFalse;
            elsif not stall then
                writeBackControlWordToWriteBack_buf := writeBackControlWord;
                aluResultToWriteback <= aluResult;
                destinationRegToWriteback <= destinationReg;
                memDataReadToWriteback <= dataFromMem;
            end if;
        end if;
        writeBackControlWordToWriteBack <= writeBackControlWordToWriteBack_buf;
    end process;
end architecture;
