library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

library tb;
use tb.mips32_instruction_builder_pkg.all;

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

    signal instruction : mips32_instruction_type;
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
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Sw);
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
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_special, funct => mips32_function_sll);
                wait for 10 ns;
                check(not doMemWrite);
                check(not doMemRead);
            elsif run("Requesting a memory read works") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lw);
                expectedMemAddress := X"0000FFF0";
                execResult <= expectedMemAddress;
                dataFromMem <= X"F1020304";
                wait for 10 ns;
                check_equal(memAddress, expectedMemAddress);
                check(not doMemWrite);
                check(doMemRead);
                check_equal(memDataRead, dataFromMem);
            elsif run("mtc0 causes write to coprocessor 0") then
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_COP0, rs => mips32_mf_mtc0);
                rdAddress <= 5;
                regDataRead <= X"FAFBFCFD";
                wait for 1 fs;
                check(write_to_cpz);
                check(address_to_cpz = rdAddress);
                check(data_to_cpz = regDataRead);
            elsif run("Rtype does not cause write to coprocessor 0") then
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_special, funct => mips32_function_sll);
                wait for 1 fs;
                check(not write_to_cpz);
            elsif run("mtc0 does not write during a stall") then
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_COP0, rs => mips32_mf_mtc0);
                stall <= true;
                wait for 1 fs;
                check(not write_to_cpz);
            elsif run("Mem stage forwards cpz data") then
                instruction <= construct_rtype_instruction(opcode => mips32_opcode_COP0, rs => mips32_mf_mfc0);
                data_from_cpz <= X"F1F2F3F4";
                wait for 10 ns;
                check(memDataRead = data_from_cpz);
            elsif run("lhu sets correct bytemask 0011") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lhu);
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0011"));
            elsif run("lhu zeros the upper 2 byte") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lhu);
                dataFromMem <= X"01020304";
                wait for 1 fs;
                check_equal(memDataRead, X"0000" & dataFromMem(15 downto 0));
            elsif run("lbu sets correct bytemask 0001") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lbu);
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0001"));
            elsif run("lbu zeros the upper 3 byte") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lbu);
                dataFromMem <= X"01020304";
                wait for 1 fs;
                check_equal(memDataRead, X"000000" & dataFromMem(7 downto 0));
            elsif run("lb sets bytemask 0001") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lb);
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0001"));
            elsif run("lb sign-extends") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lb);
                dataFromMem <= X"01020384";
                wait for 1 fs;
                check_equal(memDataRead, X"ffffff" & dataFromMem(7 downto 0));
            elsif run("lh sets bytemask 0011") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lh);
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0011"));
            elsif run("lh sign-extends") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_Lh);
                dataFromMem <= X"01028384";
                wait for 1 fs;
                check_equal(memDataRead, X"ffff" & dataFromMem(15 downto 0));
            elsif run("sb sets bytemask 0001") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_sb);
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0001"));
            elsif run("sh sets bytemask 0011") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_sh);
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0011"));
            elsif run("lwl results in an aligned address") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_lwl);
                execResult <= X"00000006";
                wait for 1 fs;
                check_equal(memAddress, std_logic_vector'(X"00000004"));
            elsif run("lwl 6 results in a bytemask of 0111") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_lwl);
                execResult <= X"00000006";
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("0111"));
            elsif run("lwl merges incoming word and word from memory") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_lwl);
                execResult <= X"00000006";
                regDataRead <= X"f1f2f3f4";
                dataFromMem <= X"01020304";
                wait for 1 fs;
                check_equal(memDataRead, dataFromMem(23 downto 0) & regDataRead(7 downto 0));
            elsif run("lwr results in an aligned address") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_lwr);
                execResult <= X"00000003";
                wait for 1 fs;
                check_equal(memAddress, std_logic_vector'(X"00000000"));
            elsif run("lwr 3 results in a bytemask of 1000") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_lwr);
                execResult <= X"00000003";
                wait for 1 fs;
                check_equal(memByteMask, std_logic_vector'("1000"));
            elsif run("lwr merges incoming word and word from memory") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_lwr);
                execResult <= X"00000003";
                regDataRead <= X"f1f2f3f4";
                dataFromMem <= X"01020304";
                wait for 1 fs;
                check_equal(memDataRead, regDataRead(31 downto 8) & dataFromMem(31 downto 24));
            elsif run("swl results in an aligned address") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_swl);
                execResult <= X"00000006";
                wait for 1 fs;
                check_equal(memAddress, std_logic_vector'(X"00000004"));
            elsif run("swl correctly right shifts outgoing data") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_swl);
                execResult <= X"00000006";
                regDataRead <= X"ffffff00";
                wait for 1 fs;
                check_equal(dataToMem, std_logic_vector'(X"00ffffff"));
            elsif run("swl on address ending in 3 does not shift") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_swl);
                execResult <= X"000000f3";
                regDataRead <= X"ffffff00";
                wait for 1 fs;
                check_equal(dataToMem, std_logic_vector'(X"ffffff00"));
            elsif run("swr results in an aligned address") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_swr);
                execResult <= X"00000003";
                wait for 1 fs;
                check_equal(memAddress, std_logic_vector'(X"00000000"));
            elsif run("swr correctly left-shifts outgoing data") then
                instruction <= construct_itype_instruction(opcode => mips32_opcode_swr);
                execResult <= X"00000003";
                regDataRead <= X"ffffffee";
                wait for 1 fs;
                check_equal(dataToMem, std_logic_vector'(X"ee000000"));
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
        instruction => instruction,
        memoryControlWord => memoryControlWord
    );

end architecture;
