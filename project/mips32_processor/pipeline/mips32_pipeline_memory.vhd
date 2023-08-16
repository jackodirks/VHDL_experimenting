library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_memory is
    port (
        -- Control in
        stall : in boolean;
        -- From execute stage: control signals
        memoryControlWord : in mips32_MemoryControlWord_type;

        -- From execute stage: data
        execResult : in mips32_data_type;
        regDataRead : in mips32_data_type;
        rdAddress : in mips32_registerFileAddress_type;

        -- To writeback stage: data
        memDataRead: out mips32_data_type;

        -- To mem2bus unit
        doMemRead : out boolean;
        doMemWrite : out boolean;
        memAddress : out mips32_address_type;
        memByteMask : out mips32_byte_mask_type;
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
    pure function loadStoreSizeToByteMask(size : mips32_load_store_size) return mips32_byte_mask_type is
        variable retVal : mips32_byte_mask_type := "1111";
    begin
        if size = ls_halfword then
            retVal := "0011";
        elsif size = ls_byte then
            retVal := "0001";
        end if;
        return retVal;
    end function;
begin

    postProcessMemRead : process(dataFromMem, memoryControlWord, data_from_cpz)
        variable readLenBit : natural range 0 to 31 := 31;
    begin
        if memoryControlWord.loadStoreSize = ls_byte then
            readLenBit := 7;
        elsif memoryControlWord.loadStoreSize = ls_halfword then
            readLenBit := 15;
        else
            readLenBit := 31;
        end if;

        if not memoryControlWord.MemOp then
            memDataRead <= data_from_cpz;
        elsif memoryControlWord.memReadSignExtend then
            memDataRead <= std_logic_vector(resize(signed(dataFromMem(readLenBit downto 0)), memDataRead'length));
        else
            memDataRead <= std_logic_vector(resize(unsigned(dataFromMem(readLenBit downto 0)), memDataRead'length));
        end if;
    end process;

    mem2busOut : process(memoryControlWord, execResult, regDataRead)
    begin
        doMemRead <= false;
        doMemWrite <= false;
        dataToMem <= regDataRead;
        memAddress <= execResult;
        memByteMask <= loadStoreSizeToByteMask(memoryControlWord.loadStoreSize);
        if memoryControlWord.MemOp then
            if memoryControlWord.MemOpIsWrite then
                doMemWrite <= true;
            else
                doMemRead <= true;
            end if;
        end if;
    end process;

    cpzOut : process(memoryControlWord, execResult, stall, rdAddress, regDataRead)
    begin
        address_to_cpz <= rdAddress;
        write_to_cpz <= memoryControlWord.cop0Write and not stall;
        data_to_cpz <= regDataRead;
    end process;
end architecture;
