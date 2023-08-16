library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_pipeline_memory_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_memory_tb is
    signal stall : boolean := false;

    signal memoryControlWord : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;

    signal execResult : mips32_data_type;
    signal regDataRead : mips32_data_type;
    signal rdAddress : mips32_registerFileAddress_type;

    signal memDataRead : mips32_data_type;

    signal doMemRead : boolean;
    signal doMemWrite : boolean;
    signal memAddress : mips32_address_type;
    signal memByteMask : mips32_byte_mask_type;
    signal dataToMem : mips32_data_type;
    signal dataFromMem : mips32_data_type;

    signal address_to_cpz : natural range 0 to 31;
    signal write_to_cpz : boolean;
    signal data_to_cpz : mips32_data_type;
    signal data_from_cpz : mips32_data_type := (others => '0');

    signal decodedMemoryControlWord : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
    signal opcode : mips32_opcode_type;
    signal mf : mips32_mf_type;
begin
    main : process
        variable expectedMemAddress : mips32_address_type;
        variable expectedDataToMem : mips32_data_type;
        variable expectedExecResultToWriteback : mips32_data_type;
        variable expectedDestinationRegToWriteback : mips32_registerFileAddress_type;
        variable expectedMemDataReadToWriteback : mips32_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Requesting a memory write works") then
                memoryControlWord.MemOp <= true;
                memoryControlWord.MemOpIsWrite <= true;
                expectedMemAddress := X"0000FFF0";
                expectedDataToMem := X"FFFF0000";
                execResult <= expectedMemAddress;
                regDataRead <= expectedDataToMem;
                wait for 10 ns;
                check_equal(memAddress, expectedMemAddress);
                check_equal(dataToMem, expectedDataToMem);
                check(doMemWrite);
                check(not doMemRead);
            elsif run("Not requesting any MemOp works") then
                memoryControlWord.MemOp <= false;
                memoryControlWord.MemOpIsWrite <= false;
                wait for 10 ns;
                check(not doMemWrite);
                check(not doMemRead);
            elsif run("Requesting a memory read works") then
                memoryControlWord.MemOp <= true;
                memoryControlWord.MemOpIsWrite <= false;
                expectedMemAddress := X"0000FFF0";
                execResult <= expectedMemAddress;
                dataFromMem <= X"F1020304";
                wait for 10 ns;
                check_equal(memAddress, expectedMemAddress);
                check(not doMemWrite);
                check(doMemRead);
                check_equal(memDataRead, dataFromMem);
            elsif run("mtc0 causes write to coprocessor 0") then
                opcode <= mips32_opcodeCOP0;
                mf <= 4;
                rdAddress <= 5;
                regDataRead <= X"FAFBFCFD";
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check(write_to_cpz);
                check(address_to_cpz = rdAddress);
                check(data_to_cpz = regDataRead);
            elsif run("Rtype does not cause write to coprocessor 0") then
                opcode <= mips32_opcodeRType;
                mf <= 0;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check(not write_to_cpz);
            elsif run("mtc0 does not write during a stall") then
                opcode <= mips32_opcodeCOP0;
                mf <= 4;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                stall <= true;
                wait for 1 fs;
                check(not write_to_cpz);
            elsif run("Mem stage forwards cpz data") then
                opcode <= mips32_opcodeCOP0;
                mf <= 0;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                data_from_cpz <= X"F1F2F3F4";
                wait for 10 ns;
                check(memDataRead = data_from_cpz);
            elsif run("lhu sets correct bytemask 0011") then
                opcode <= mips32_opcodeLhu;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0011"));
            elsif run("lhu zeros the upper 2 byte") then
                opcode <= mips32_opcodeLhu;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                dataFromMem <= X"01020304";
                wait for 1 fs;
                check_equal(memDataRead, X"0000" & dataFromMem(15 downto 0));
            elsif run("lbu sets correct bytemask 0001") then
                opcode <= mips32_opcodeLbu;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0001"));
            elsif run("lbu zeros the upper 3 byte") then
                opcode <= mips32_opcodeLbu;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                dataFromMem <= X"01020304";
                wait for 1 fs;
                check_equal(memDataRead, X"000000" & dataFromMem(7 downto 0));
            elsif run("lb sets bytemask 0001") then
                opcode <= mips32_opcodeLb;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0001"));
            elsif run("lb sign-extends") then
                opcode <= mips32_opcodeLb;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                dataFromMem <= X"01020384";
                wait for 1 fs;
                check_equal(memDataRead, X"ffffff" & dataFromMem(7 downto 0));
            elsif run("lh sets bytemask 0011") then
                opcode <= mips32_opcodeLh;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0011"));
            elsif run("lh sign-extends") then
                opcode <= mips32_opcodeLh;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                dataFromMem <= X"01028384";
                wait for 1 fs;
                check_equal(memDataRead, X"ffff" & dataFromMem(15 downto 0));
            elsif run("sb sets bytemask 0001") then
                opcode <= mips32_opcodeSb;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0001"));
            elsif run("sh sets bytemask 0011") then
                opcode <= mips32_opcodeSh;
                wait for 1 fs;
                memoryControlWord <= decodedMemoryControlWord;
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0011"));
            end if;
        end loop;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    memoryStage : entity src.mips32_pipeline_memory
    port map (
        stall => stall,
        memoryControlWord => memoryControlWord,
        execResult => execResult,
        regDataRead => regDataRead,
        rdAddress => rdAddress,
        memDataRead => memDataRead,
        doMemRead => doMemRead,
        doMemWrite => doMemWrite,
        memAddress => memAddress,
        memByteMask => memByteMask,
        dataToMem => dataToMem,
        dataFromMem => dataFromMem,
        address_to_cpz => address_to_cpz,
        write_to_cpz => write_to_cpz,
        data_to_cpz => data_to_cpz,
        data_from_cpz => data_from_cpz
    );

    controlDecode : entity src.mips32_control
    port map (
        opcode => opcode,
        mf => mf,
        memoryControlWord => decodedMemoryControlWord
    );

end architecture;
