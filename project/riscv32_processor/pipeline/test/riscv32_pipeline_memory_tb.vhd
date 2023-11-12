library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.riscv32_pkg.all;

library tb;
use tb.riscv32_instruction_builder_pkg.all;

entity riscv32_pipeline_memory_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of riscv32_pipeline_memory_tb is
    signal memoryControlWord : riscv32_MemoryControlWord_type := riscv32_memoryControlWordAllFalse;

    signal requestAddress : riscv32_data_type := (others => '0');
    signal rs2Data : riscv32_data_type := (others => '0');

    signal memDataRead : riscv32_data_type;

    signal doMemRead : boolean;
    signal doMemWrite : boolean;
    signal memAddress : riscv32_address_type;
    signal memByteMask : riscv32_byte_mask_type;
    signal dataToMem : riscv32_data_type;
    signal dataFromMem : riscv32_data_type;

    signal instruction : riscv32_instruction_type;
begin
    main : process
        variable expectedMemAddress : riscv32_address_type;
        variable expectedDataToMem : riscv32_data_type;
        variable expectedExecResultToWriteback : riscv32_data_type;
        variable expectedDestinationRegToWriteback : riscv32_registerFileAddress_type;
        variable expectedMemDataReadToWriteback : riscv32_data_type;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Test store word") then
                instruction <= construct_stype_instruction(opcode => riscv32_opcode_store, funct3 => riscv32_funct3_sw);
                requestAddress <= X"00004004";
                rs2Data <= X"ABABABAB";
                wait for 1 ns;
                check(not doMemRead);
                check(doMemWrite);
                check_equal(memAddress, requestAddress);
                check_equal(memByteMask, std_logic_vector'(X"f"));
                check_equal(dataToMem, rs2Data);
            elsif run("Test store halfword, aligned") then
                instruction <= construct_stype_instruction(opcode => riscv32_opcode_store, funct3 => riscv32_funct3_sh);
                requestAddress <= X"00004004";
                rs2Data <= X"11112222";
                wait for 1 ns;
                check(not doMemRead);
                check(doMemWrite);
                check_equal(memAddress, requestAddress);
                check_equal(memByteMask, std_logic_vector'(X"3"));
                check_equal(dataToMem(15 downto 0), rs2Data(15 downto 0));
            elsif run("Test store halfword, unaligned") then
                instruction <= construct_stype_instruction(opcode => riscv32_opcode_store, funct3 => riscv32_funct3_sh);
                requestAddress <= X"00004006";
                rs2Data <= X"11112222";
                wait for 1 ns;
                check(not doMemRead);
                check(doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"3"));
                check_equal(dataToMem(15 downto 0), rs2Data(31 downto 16));
            elsif run("Test store byte, aligned") then
                instruction <= construct_stype_instruction(opcode => riscv32_opcode_store, funct3 => riscv32_funct3_sb);
                requestAddress <= X"00004004";
                rs2Data <= X"11223344";
                wait for 1 ns;
                check(not doMemRead);
                check(doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"1"));
                check_equal(dataToMem(7 downto 0), rs2Data(7 downto 0));
            elsif run("Test store byte, offset 1") then
                instruction <= construct_stype_instruction(opcode => riscv32_opcode_store, funct3 => riscv32_funct3_sb);
                requestAddress <= X"00004005";
                rs2Data <= X"11223344";
                wait for 1 ns;
                check(not doMemRead);
                check(doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"1"));
                check_equal(dataToMem(7 downto 0), rs2Data(15 downto 8));
            elsif run("Test store byte, offset 3") then
                instruction <= construct_stype_instruction(opcode => riscv32_opcode_store, funct3 => riscv32_funct3_sb);
                requestAddress <= X"00004007";
                rs2Data <= X"11223344";
                wait for 1 ns;
                check(not doMemRead);
                check(doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"1"));
                check_equal(dataToMem(7 downto 0), rs2Data(31 downto 24));
            elsif run("Test load word") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lw);
                requestAddress <= X"00004004";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"f"));
                dataFromMem <= X"11223344";
                wait for 1 ns;
                check_equal(memDataRead, dataFromMem);
            elsif run("Test load halfword unsigned, aligned") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lhu);
                requestAddress <= X"00004004";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"3"));
                dataFromMem <= X"11223344";
                wait for 1 ns;
                check_equal(memDataRead(15 downto 0), dataFromMem(15 downto 0));
                check_equal(memDataRead(31 downto 16), std_logic_vector'(X"0000"));
            elsif run("Test load halfword unsigned, unaligned") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lhu);
                requestAddress <= X"00004006";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"c"));
                dataFromMem <= X"11223344";
                wait for 1 ns;
                check_equal(memDataRead(15 downto 0), dataFromMem(31 downto 16));
                check_equal(memDataRead(31 downto 16), std_logic_vector'(X"0000"));
            elsif run("Test load byte unsigned, aligned") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lbu);
                requestAddress <= X"00004004";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"1"));
                dataFromMem <= X"11223344";
                wait for 1 ns;
                check_equal(memDataRead(7 downto 0), dataFromMem(7 downto 0));
                check_equal(memDataRead(31 downto 8), std_logic_vector'(X"000000"));
            elsif run("Test load byte unsigned, offset 1") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lbu);
                requestAddress <= X"00004005";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"2"));
                dataFromMem <= X"11223344";
                wait for 1 ns;
                check_equal(memDataRead(7 downto 0), dataFromMem(15 downto 8));
                check_equal(memDataRead(31 downto 8), std_logic_vector'(X"000000"));
            elsif run("Test load byte unsigned, offset 3") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lbu);
                requestAddress <= X"00004007";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"8"));
                dataFromMem <= X"11223344";
                wait for 1 ns;
                check_equal(memDataRead(7 downto 0), dataFromMem(31 downto 24));
                check_equal(memDataRead(31 downto 8), std_logic_vector'(X"000000"));
            elsif run("Test load halfword signed, aligned") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lh);
                requestAddress <= X"00004004";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"3"));
                dataFromMem <= X"0000fffc";
                wait for 1 ns;
                check_equal(memDataRead(15 downto 0), dataFromMem(15 downto 0));
                check_equal(memDataRead(31 downto 16), std_logic_vector'(X"ffff"));
            elsif run("Test load halfword signed, unaligned") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lh);
                requestAddress <= X"00004006";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"c"));
                dataFromMem <= X"fffc0000";
                wait for 1 ns;
                check_equal(memDataRead(15 downto 0), dataFromMem(31 downto 16));
                check_equal(memDataRead(31 downto 16), std_logic_vector'(X"ffff"));
            elsif run("Test load byte signed, aligned") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lb);
                requestAddress <= X"00004004";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"1"));
                dataFromMem <= X"000000fb";
                wait for 1 ns;
                check_equal(memDataRead(7 downto 0), dataFromMem(7 downto 0));
                check_equal(memDataRead(31 downto 8), std_logic_vector'(X"ffffff"));
            elsif run("Test load byte signed, offset 3") then
                instruction <= construct_itype_instruction(opcode => riscv32_opcode_load, funct3 => riscv32_funct3_lb);
                requestAddress <= X"00004007";
                wait for 1 ns;
                check(doMemRead);
                check(not doMemWrite);
                check_equal(memAddress, std_logic_vector'(X"00004004"));
                check_equal(memByteMask, std_logic_vector'(X"8"));
                dataFromMem <= X"fa112233";
                wait for 1 ns;
                check_equal(memDataRead(7 downto 0), dataFromMem(31 downto 24));
                check_equal(memDataRead(31 downto 8), std_logic_vector'(X"ffffff"));
            end if;
        end loop;
        wait for 5 ns;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    memoryStage : entity src.riscv32_pipeline_memory
    port map (
        memoryControlWord => memoryControlWord,
        requestAddress => requestAddress,
        rs2Data => rs2Data,
        memDataRead => memDataRead,
        doMemRead => doMemRead,
        doMemWrite => doMemWrite,
        memAddress => memAddress,
        memByteMask => memByteMask,
        dataToMem => dataToMem,
        dataFromMem => dataFromMem
    );

    controlDecode : entity src.riscv32_control
    port map (
        instruction => instruction,
        memoryControlWord => memoryControlWord
    );

end architecture;
