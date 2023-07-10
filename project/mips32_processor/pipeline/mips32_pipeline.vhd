library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline is
    generic (
        startAddress : mips32_address_type
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        instructionAddress : out mips32_address_type;
        instruction : in mips32_instruction_type;

        dataAddress : out mips32_address_type;
        dataRead : out boolean;
        dataWrite : out boolean;
        dataOut : out mips32_data_type;
        dataIn : in mips32_data_type;

        -- To coprocessor 0
        address_to_cpz : out natural range 0 to 31;
        write_to_cpz : out boolean;
        data_to_cpz : out mips32_data_type;
        data_from_cpz : in mips32_data_type
    );
end entity;

architecture behaviourial of mips32_pipeline is
    -- Instruction fetch to instruction decode
    signal instructionToID : mips32_instruction_type;
    signal pcPlusFourToID : mips32_address_type;
    -- Instruction decode to instruction fetch
    signal overrideProgramCounterFromID : boolean;
    signal newProgramCounterFromID : mips32_address_type;
    signal repeatInstruction : boolean;
    -- Instruction decode to execute
    signal exControlWordToEx : mips32_ExecuteControlWord_type;
    signal memControlWordToEx : mips32_MemoryControlWord_type;
    signal wbControlWordToEx : mips32_WriteBackControlWord_type;
    signal immidiateToEx : mips32_data_type;
    signal destRegToEx : mips32_registerFileAddress_type;
    signal aluFuncToEx : mips32_aluFunction_type;
    signal shamtToEx : mips32_shamt_type;
    signal pcPlusFourToEx : mips32_address_type;
    -- Instruction decode to forwarding
    signal rsDataToFwU : mips32_data_type;
    signal rsAddressToFwU : mips32_registerFileAddress_type;
    signal rtDataToFwU : mips32_data_type;
    signal rtAddressToFwU : mips32_registerFileAddress_type;
    -- Forwarding unit to execute
    signal rsDataToEx : mips32_data_type;
    signal rtDataToEx : mips32_data_type;
    -- Write back to instruction decode
    signal regWriteToID : boolean;
    signal regWriteAddrToID : mips32_registerFileAddress_type;
    signal regWriteDataToID : mips32_data_type;
    -- Execute to memory
    signal memControlWordToMem : mips32_MemoryControlWord_type;
    signal wbControlWordToMem : mips32_WriteBackControlWord_type;
    signal execResToMem : mips32_data_type;
    signal regDataReadToMem : mips32_data_type;
    signal destRegToMem : mips32_registerFileAddress_type;
    -- Execute to instruction fetch
    signal overrideProgramCounterFromEx : boolean;
    signal newProgramCounterFromEx : mips32_address_type;
    -- Execute to instruction decode
    signal ignoreCurrentInstruction : boolean;
    -- Memory to write back
    signal wbControlWordToWb : mips32_WriteBackControlWord_type;
    signal execResToWb : mips32_data_type;
    signal memReadToWb : mips32_data_type;
    signal destRegToWb : mips32_registerFileAddress_type;

    signal instructionFetchStall : boolean;
    signal instructionDecode_exInstructionIsMemLoad : boolean;

begin
    instructionFetchStall <= stall or repeatInstruction;
    instructionDecode_exInstructionIsMemLoad <= memControlWordToEx.MemOp and not memControlWordToEx.MemOpIsWrite;

    instructionFetch : entity work.mips32_pipeline_instructionFetch
    generic map (
        startAddress
    ) port map (
        clk => clk,
        rst => rst,
        stall => instructionFetchStall,

        requestFromBusAddress => instructionAddress,
        instructionFromBus => instruction,

        instructionToInstructionDecode => instructionToID,
        programCounterPlusFour => pcPlusFourToID,

        overrideProgramCounterFromID => overrideProgramCounterFromID,
        newProgramCounterFromID => newProgramCounterFromID,
        overrideProgramCounterFromEx => overrideProgramCounterFromEx,
        newProgramCounterFromEx => newProgramCounterFromEx
    );

    instructionDecode : entity work.mips32_pipeline_instructionDecode
    port map (
        clk => clk,
        rst => rst,
        stall => stall,

        instructionFromInstructionFetch => instructionToID,
        programCounterPlusFour => pcPlusFourToID,

        overrideProgramCounter => overrideProgramCounterFromID,
        repeatInstruction => repeatInstruction,
        newProgramCounter => newProgramCounterFromID,

        rsAddress => rsAddressToFwU,
        rtAddress => rtAddressToFwU,

        executeControlWord => exControlWordToEx,
        memoryControlWord => memControlWordToEx,
        writeBackControlWord => wbControlWordToEx,
        rsData => rsDataToFwU,
        rtData => rtDataToFwU,
        immidiate => immidiateToEx,
        destinationReg => destRegToEx,
        aluFunction => aluFuncToEx,
        shamt => shamtToEx,
        programCounterPlusFourToEx => pcPlusFourToEx,

        exInstructionIsMemLoad => instructionDecode_exInstructionIsMemLoad,
        exInstructionTargetReg => destRegToEx,

        regWrite => regWriteToID,
        regWriteAddress => regWriteAddrToID,
        regWriteData => regWriteDataToID,
        ignoreCurrentInstruction => ignoreCurrentInstruction
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
        programCounterPlusFour => pcPlusFourToEx,

        memoryControlWordToMem => memControlWordToMem,
        writeBackControlWordToMem => wbControlWordToMem,
        execResult => execResToMem,
        regDataRead => regDataReadToMem,
        destinationRegToMem => destRegToMem,

        overrideProgramCounter => overrideProgramCounterFromEx,
        newProgramCounter => newProgramCounterFromEx,

       justBranched => ignoreCurrentInstruction
    );

    memory : entity work.mips32_pipeline_memory
    port map (
        clk => clk,
        rst => rst,
        stall => stall,

        memoryControlWord => memControlWordToMem,
        writeBackControlWord => wbControlWordToMem,
        execResult => execResToMem,
        regDataRead => regDataReadToMem,
        destinationReg => destRegToMem,

        writeBackControlWordToWriteBack => wbControlWordToWb,
        execResultToWriteback => execResToWb,
        memDataReadToWriteback => memReadToWb,
        destinationRegToWriteback => destRegToWb,

        doMemRead => dataRead,
        doMemWrite => dataWrite,
        memAddress => dataAddress,
        dataToMem => dataOut,
        dataFromMem => dataIn,

        address_to_cpz => address_to_cpz,
        write_to_cpz => write_to_cpz,
        data_to_cpz => data_to_cpz,
        data_from_cpz => data_from_cpz
    );

    writeBack : entity work.mips32_pipeline_writeBack
    port map (
        writeBackControlWord => wbControlWordToWb,
        execResult => execResToWb,
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

        regDataFromEx => execResToMem,
        regAddressFromEx => destRegToMem,
        regWriteFromEx => wbControlWordToMem.regWrite,
        regDataFromMem => regWriteDataToID,
        regAddressFromMem => regWriteAddrToID,
        regWriteFromMem => regWriteToID,

        rsData => rsDataToEx,
        rtData => rtDataToEx
    );
end architecture;
