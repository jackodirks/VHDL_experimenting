library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg;

entity mips32_pipeline is
    generic (
        resetAddress : mips32_pkg.address_type
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        instructionAddress : out mips32_pkg.address_type;
        instruction : in mips32_pkg.data_type;

        dataAddress : out mips32_pkg.address_type;
        dataRead : out boolean;
        dataWrite : out boolean;
        dataOut : out mips32_pkg.data_type;
        dataIn : in mips32_pkg.data_type
    );
end entity;

architecture behaviourial of mips32_pipeline is
    -- Instruction fetch to instruction decode
    signal instructionToID : mips32_pkg.instruction_type;
    signal pcPlusFourToID : mips32_pkg.address_type;
    -- Instruction decode to instruction fetch
    signal overridePcToIF : boolean;
    signal newPcToIF : mips32_pkg.address_type;
    signal repeatInstruction : boolean;
    -- Instruction fetch to execute
    signal exControlWordToEx : mips32_pkg.ExecuteControlWord_type;
    signal memControlWordToEx : mips32_pkg.MemoryControlWord_type;
    signal wbControlWordToEx : mips32_pkg.WriteBackControlWord_type;
    signal immidiateToEx : mips32_pkg.data_type;
    signal destRegToEx : mips32_pkg.registerFileAddress_type;
    signal aluFuncToEx : mips32_pkg.aluFunction_type;
    signal shamtToEx : mips32_pkg.shamt_type;
    -- Instruction fetch to forwarding
    signal rsDataToFwU : mips32_pkg.data_type;
    signal rsAddressToFwU : mips32_pkg.registerFileAddress_type;
    signal rtDataToFwU : mips32_pkg.data_type;
    signal rtAddressToFwU : mips32_pkg.registerFileAddress_type;
    -- Forwarding unit to execute
    signal rsDataToEx : mips32_pkg.data_type;
    signal rtDataToEx : mips32_pkg.data_type;
    -- Write back to instruction decode
    signal regWriteToID : boolean;
    signal regWriteAddrToID : mips32_pkg.registerFileAddress_type;
    signal regWriteDataToID : mips32_pkg.data_type;
    -- Execute to memory
    signal memControlWordToMem : mips32_pkg.MemoryControlWord_type;
    signal wbControlWordToMem : mips32_pkg.WriteBackControlWord_type;
    signal aluResToMem : mips32_pkg.data_type;
    signal regDataReadToMem : mips32_pkg.data_type;
    signal destRegToMem : mips32_pkg.registerFileAddress_type;
    -- Memory to write back
    signal wbControlWordToWb : mips32_pkg.WriteBackControlWord_type;
    signal aluResToWb : mips32_pkg.data_type;
    signal memReadToWb : mips32_pkg.data_type;
    signal destRegToWb : mips32_pkg.registerFileAddress_type;

begin
    instructionFetch : entity work.mips32_pipeline_instructionFetch
    generic map (
        resetAddress => resetAddress
    ) port map (
        clk => clk,
        rst => rst,
        stall => stall or repeatInstruction,

        requestFromBusAddress => instructionAddress,
        instructionFromBus => instruction,

        instructionToInstructionDecode => instructionToID,
        programCounterPlusFour => pcPlusFourToID,

        overrideProgramCounter => overridePcToIF,
        newProgramCounter => newPcToIF
    );

    instructionDecode : entity work.mips32_pipeline_instructionDecode
    port map (
        clk => clk,
        rst => rst,
        stall => stall,

        instructionFromInstructionDecode => instructionToID,
        programCounterPlusFour => pcPlusFourToID,

        overrideProgramCounter => overridePcToIF,
        repeatInstruction => repeatInstruction,
        newProgramCounter => newPcToIF,

        executeControlWord => exControlWordToEx,
        memoryControlWord => memControlWordToEx,
        writeBackControlWord => wbControlWordToEx,
        rsData => rsDataToFwU,
        rsAddress => rsAddressToFwU,
        rtData => rtDataToFwU,
        rtAddress => rtAddressToFwU,
        immidiate => immidiateToEx,
        destinationReg => destRegToEx,
        aluFunction => aluFuncToEx,
        shamt => shamtToEx,

        exInstructionIsMemLoad => memControlWordToEx.MemOp and not memControlWordToEx.MemOpIsWrite,
        exInstructionTargetReg => destRegToEx,

        regWrite => regWriteToID,
        regWriteAddress => regWriteAddrToID,
        regWriteData => regWriteDataToID
    );

    execute : entity work.mips32_pipeline_execute
    port map (
        clk => clk,
        rst => rst,
        stall => stall,

        executeControlWord => exControlWordToEx,
        memoryControlWord => memControlWordToEx,
        writeBackControlWord => wbControlWordToEx,
        rsData => rsDataToEx,
        rtData => rtDataToEx,
        immidiate => immidiateToEx,
        destinationReg => destRegToEx,
        aluFunction => aluFuncToEx,
        shamt => shamtToEx,

        memoryControlWordToMem => memControlWordToMem,
        writeBackControlWordToMem => wbControlWordToMem,
        aluResult => aluResToMem,
        regDataRead => regDataReadToMem,
        destinationRegToMem => destRegToMem
    );

    memory : entity work.mips32_pipeline_memory
    port map (
        clk => clk,
        rst => rst,
        stall => stall,

        memoryControlWord => memControlWordToMem,
        writeBackControlWord => wbControlWordToMem,
        aluResult => aluResToMem,
        regDataRead => regDataReadToMem,
        destinationReg => destRegToMem,

        writeBackControlWordToWriteBack => wbControlWordToWb,
        aluResultToWriteback => aluResToWb,
        memDataReadToWriteback => memReadToWb,
        destinationRegToWriteback => destRegToWb,

        doMemRead => dataRead,
        doMemWrite => dataWrite,
        memAddress => dataAddress,
        dataToMem => dataOut,
        dataFromMem => dataIn
    );

    writeBack : entity work.mips32_pipeline_writeBack
    port map (
        writeBackControlWord => wbControlWordToWb,
        aluResult => aluResToWb,
        memDataRead => memReadToWb,
        destinationReg => destRegToWb,

        regWrite => regWriteToID,
        regWriteAddress => regWriteAddrToID,
        regWriteData => regWriteDataToID
    );

    forwarding_unit : entity work.mips32_pipeline_forwarding_unit
    port map (
        rsDataFromID => rsDataToFwU,
        rsAddressFromID => rsAddressToFwU,
        rtDataFromID => rtDataToFwU,
        rtAddressFromID => rtAddressToFwU,

        regDataFromEx => aluResToMem,
        regAddressFromEx => destRegToMem,
        regWriteFromEx => wbControlWordToMem.regWrite,
        regDataFromMem => regWriteDataToID,
        regAddressFromMem => regWriteAddrToID,
        regWriteFromMem => regWriteToID,

        rsData => rsDataToEx,
        rtData => rtDataToEx
    );
end architecture;
