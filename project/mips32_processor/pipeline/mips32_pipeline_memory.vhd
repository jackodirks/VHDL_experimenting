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

    signal addressToMem : mips32_address_type;
    signal byteMaskToMem : mips32_byte_mask_type;
begin

    postProcessMemRead : process(dataFromMem, memoryControlWord, data_from_cpz, byteMaskToMem, regDataRead, execResult)
        variable readLenBit : natural range 0 to 31 := 31;
        variable subWordNumber : natural range 0 to 3;
    begin
        if memoryControlWord.loadStoreSize = ls_byte then
            readLenBit := 7;
        elsif memoryControlWord.loadStoreSize = ls_halfword then
            readLenBit := 15;
        else
            readLenBit := 31;
        end if;

        subWordNumber := to_integer(unsigned(execResult(mips32_data_width_log2b - mips32_byte_width_log2b - 1 downto 0)));

        if not memoryControlWord.MemOp then
            memDataRead <= data_from_cpz;
        elsif memoryControlWord.wordLeft then
            memDataRead <= regDataRead;
            memDataRead(31 downto (3 - subWordNumber)*8) <= dataFromMem(subWordNumber*8 + 7 downto 0);
        elsif memoryControlWord.wordRight then
            memDataRead <= regDataRead;
            memDataRead((3 - subWordNumber) * 8 + 7 downto 0) <= dataFromMem(31 downto subWordNumber * 8);
        elsif memoryControlWord.memReadSignExtend then
            memDataRead <= std_logic_vector(resize(signed(dataFromMem(readLenBit downto 0)), memDataRead'length));
        else
            memDataRead <= std_logic_vector(resize(unsigned(dataFromMem(readLenBit downto 0)), memDataRead'length));
        end if;
    end process;

    preProcessAddress : process(execResult, memoryControlWord)
    begin
        addressToMem <= execResult;
        if memoryControlWord.wordLeft or memoryControlWord.wordRight then
            addressToMem(mips32_data_width_log2b - mips32_byte_width_log2b - 1 downto 0) <= (others => '0');
        end if;
    end process;

    preProcessByteMask : process(memoryControlWord, execResult)
        variable subWordNumber : natural range 0 to 3;
    begin
        byteMaskToMem <= loadStoreSizeToByteMask(memoryControlWord.loadStoreSize);
        if memoryControlWord.wordLeft then
            subWordNumber := to_integer(unsigned(execResult(mips32_data_width_log2b - mips32_byte_width_log2b - 1 downto 0)));
            case subWordNumber is
                when 0 => byteMaskToMem <= "0001";
                when 1 => byteMaskToMem <= "0011";
                when 2 => byteMaskToMem <= "0111";
                when 3 => byteMaskToMem <= "1111";
            end case;
        elsif memoryControlWord.wordRight then
            subWordNumber := to_integer(unsigned(execResult(mips32_data_width_log2b - mips32_byte_width_log2b - 1 downto 0)));
            case subWordNumber is
                when 0 => byteMaskToMem <= "1111";
                when 1 => byteMaskToMem <= "1110";
                when 2 => byteMaskToMem <= "1100";
                when 3 => byteMaskToMem <= "1000";
            end case;
        end if;
    end process;

    mem2busOut : process(memoryControlWord, addressToMem, regDataRead, byteMaskToMem)
    begin
        doMemRead <= false;
        doMemWrite <= false;
        dataToMem <= regDataRead;
        memAddress <= addressToMem;
        memByteMask <= byteMaskToMem;
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
