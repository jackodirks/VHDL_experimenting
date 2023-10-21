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
        dataByteMask : out mips32_byte_mask_type;
        dataRead : out boolean;
        dataWrite : out boolean;
        dataOut : out mips32_data_type;
        dataIn : in mips32_data_type;

        -- To coprocessor 0
        address_to_cpz : out natural range 0 to 31;
        write_to_cpz : out boolean;
        data_to_cpz : out mips32_data_type;
        data_from_cpz : in mips32_data_type;

        -- From/to bus slave
        address_to_regFile : in mips32_registerFileAddress_type;
        write_to_regFile : in boolean;
        data_to_regFile : in mips32_data_type;
        data_from_regFile : out mips32_data_type
    );
end entity;

architecture behaviourial of mips32_pipeline is
    -- Instruction fetch to instruction decode
    signal instructionToID : mips32_instruction_type;
    signal pcPlusFourFromIf : mips32_address_type;
    -- Instruction decode to instruction fetch
    signal overrideProgramCounterFromID : boolean;
    signal newProgramCounterFromID : mips32_address_type;
    signal repeatInstruction : boolean;
    -- Branchhelper to IF
    signal injectBubbleFromBranchHelper : boolean;
    -- Instruction decode to id/ex
    signal nopOutputFromId : boolean;
    signal exControlWordFromId : mips32_ExecuteControlWord_type;
    signal memControlWordFromId : mips32_MemoryControlWord_type;
    signal wbControlWordFromId : mips32_WriteBackControlWord_type;
    signal rsAddressFromId : mips32_registerFileAddress_type;
    signal rtAddressFromId : mips32_registerFileAddress_type;
    signal immidiateFromId : mips32_data_type;
    signal destRegFromId : mips32_registerFileAddress_type;
    signal rdAddressFromId : mips32_registerFileAddress_type;
    signal shamtFromId : mips32_shamt_type;
    -- Registerfile to id/ex
    signal rsDataFromRegFile : mips32_data_type;
    signal rtDataFromRegFile : mips32_data_type;
    -- From id/ex
    signal exControlWordFromIdEx : mips32_ExecuteControlWord_type;
    signal memControlWordFromIdEx : mips32_MemoryControlWord_type;
    signal wbControlWordFromIdEx : mips32_WriteBackControlWord_type;
    signal pcPlusFourFromIdEx : mips32_address_type;
    signal rsDataFromIdEx : mips32_data_type;
    signal rsAddressFromIdEx : mips32_registerFileAddress_type;
    signal rtDataFromIdEx : mips32_data_type;
    signal rtAddressFromIdEx : mips32_registerFileAddress_type;
    signal immidiateFromIdEx : mips32_data_type;
    signal destRegFromIdEx : mips32_registerFileAddress_type;
    signal shamtFromIdEx : mips32_shamt_type;
    signal rdAddrFromIdEx : mips32_registerFileAddress_type;
    -- Instruction decode to forwarding
    signal rsDataToFwU : mips32_data_type;
    signal rsAddressToFwU : mips32_registerFileAddress_type;
    signal rtDataToFwU : mips32_data_type;
    signal rtAddressToFwU : mips32_registerFileAddress_type;
    -- Instruction decode to loadHazardDetector
    signal portOneAddrToLHD : mips32_registerFileAddress_type;
    signal portTwoAddrToLHD : mips32_registerFileAddress_type;
    -- loadHazardDetector to ID
    signal loadHazardDetected : boolean;
    -- Forwarding unit to execute
    signal rsDataFromFwu : mips32_data_type;
    signal rtDataFromFwu : mips32_data_type;
    -- Execute to memory
    signal execResFromExec : mips32_data_type;
    signal regWriteOverrideFromExec : boolean;
    -- From ex/mem
    signal memControlWordFromExMem : mips32_MemoryControlWord_type;
    signal wbControlWordFromExMem : mips32_WriteBackControlWord_type;
    signal execResFromExMem : mips32_data_type;
    signal regDataReadFromExMem : mips32_data_type;
    signal destRegFromExMem : mips32_registerFileAddress_type;
    signal rdAddrFromExMem : mips32_registerFileAddress_type;
    signal regWriteOverrideFromExMem : boolean;
    -- Execute to instruction fetch
    signal overrideProgramCounterFromEx : boolean;
    signal newProgramCounterFromEx : mips32_address_type;
    -- From memory
    signal memDataFromMem : mips32_data_type;
    signal cpzDataFromMem : mips32_data_type;
    -- From mem/wb
    signal wbControlWordFromMemWb : mips32_WriteBackControlWord_type;
    signal execResFromMemWb : mips32_data_type;
    signal memDataFromMemWb : mips32_data_type;
    signal destRegFromMemWb : mips32_registerFileAddress_type;
    signal regWriteOverrideFromMemWb : boolean;
    -- From writeback
    signal regWriteFromWb : boolean;
    signal regWriteAddrFromWb : mips32_registerFileAddress_type;
    signal regWriteDataFromWb : mips32_data_type;

    signal instructionFetchStall : boolean;

begin
    instructionFetchStall <= stall or repeatInstruction;

    instructionFetch : entity work.mips32_pipeline_instructionFetch
    generic map (
        startAddress
    ) port map (
        clk => clk,
        rst => rst,
        stall => instructionFetchStall,
        injectBubble => injectBubbleFromBranchHelper,

        requestFromBusAddress => instructionAddress,
        instructionFromBus => instruction,

        instructionToInstructionDecode => instructionToID,
        programCounterPlusFour => pcPlusFourFromIf,

        overrideProgramCounterFromID => overrideProgramCounterFromID,
        newProgramCounterFromID => newProgramCounterFromID,
        overrideProgramCounterFromEx => overrideProgramCounterFromEx,
        newProgramCounterFromEx => newProgramCounterFromEx
    );

    instructionDecode : entity work.mips32_pipeline_instructionDecode
    port map (
        overrideProgramCounter => overrideProgramCounterFromID,
        repeatInstruction => repeatInstruction,

        instructionFromInstructionFetch => instructionToID,
        programCounterPlusFour => pcPlusFourFromIf,

        newProgramCounter => newProgramCounterFromID,

        nopOutput => nopOutputFromId,

        executeControlWord => exControlWordFromId,
        memoryControlWord => memControlWordFromId,
        writeBackControlWord => wbControlWordFromId,
        rsAddress => rsAddressFromId,
        rtAddress => rtAddressFromId,
        immidiate => immidiateFromId,
        destinationReg => destRegFromId,
        rdAddress => rdAddressFromId,
        shamt => shamtFromId,

        loadHazardDetected => loadHazardDetected
    );

    idexReg : entity work.mips32_pipeline_idexRegister
    port map (
        clk => clk,
        -- Control in
        stall => stall,
        nop => nopOutputFromId or rst = '1',
        -- Pipeline control in
        executeControlWordIn => exControlWordFromId,
        memoryControlWordIn => memControlWordFromId,
        writeBackControlWordIn => wbControlWordFromId,
        -- Pipeline data in
        programCounterPlusFourIn => pcPlusFourFromIf,
        rsDataIn => rsDataFromRegFile,
        rsAddressIn => rsAddressFromId,
        rtDataIn => rtDataFromRegFile,
        rtAddressIn => rtAddressFromId,
        immidiateIn => immidiateFromId,
        destinationRegIn => destRegFromId,
        rdAddressIn => rdAddressFromId,
        shamtIn => shamtFromId,
        -- Pipeline control out
        executeControlWordOut => exControlWordFromIdEx,
        memoryControlWordOut => memControlWordFromIdEx,
        writeBackControlWordOut => wbControlWordFromIdEx,
        -- Pipeline data out
        programCounterPlusFourOut => pcPlusFourFromIdEx,
        rsDataOut => rsDataFromIdEx,
        rsAddressOut => rsAddressFromIdEx,
        rtDataOut => rtDataFromIdEx,
        rtAddressOut => rtAddressFromIdEx,
        immidiateOut => immidiateFromIdEx,
        destinationRegOut => destRegFromIdEx,
        rdAddressOut => rdAddrFromIdEx,
        shamtOut => shamtFromIdEx
    );

    execute : entity work.mips32_pipeline_execute
    port map (
        executeControlWord => exControlWordFromIdEx,
        rsData => rsDataFromFwu,
        rtData => rtDataFromFwu,
        immidiate => immidiateFromIdEx,
        shamt => shamtFromIdEx,
        programCounterPlusFour => pcPlusFourFromIdEx,

        execResult => execResFromExec,
        regWrite_override => regWriteOverrideFromExec,

        overrideProgramCounter => overrideProgramCounterFromEx,
        newProgramCounter => newProgramCounterFromEx
    );

    exMemReg : entity work.mips32_pipeline_exmemRegister
    port map (
       clk => clk,
       stall => stall,
       nop => rst = '1',
       memoryControlWordIn => memControlWordFromIdEx,
       writeBackControlWordIn => wbControlWordFromIdEx,
       execResultIn => execResFromExec,
       regDataReadIn => rtDataFromFwu,
       destinationRegIn => destRegFromIdEx,
       rdAddressIn => rdAddrFromIdEx,
       regWrite_override_in => regWriteOverrideFromExec,
       memoryControlWordOut => memControlWordFromExMem,
       writeBackControlWordOut => wbControlWordFromExMem,
       execResultOut => execResFromExMem,
       regDataReadOut => regDataReadFromExMem,
       destinationRegOut => destRegFromExMem,
       rdAddressOut => rdAddrFromExMem,
       regWrite_override_out => regWriteOverrideFromExMem
   );

    memory : entity work.mips32_pipeline_memory
    port map (
        stall => stall,

        memoryControlWord => memControlWordFromExMem,
        execResult => execResFromExMem,
        regDataRead => regDataReadFromExMem,
        rdAddress => rdAddrFromExMem,

        memDataRead => memDataFromMem,

        doMemRead => dataRead,
        doMemWrite => dataWrite,
        memAddress => dataAddress,
        memByteMask => dataByteMask,
        dataToMem => dataOut,
        dataFromMem => dataIn,

        address_to_cpz => address_to_cpz,
        write_to_cpz => write_to_cpz,
        data_to_cpz => data_to_cpz,
        data_from_cpz => data_from_cpz
    );

    memWbReg : entity work.mips32_pipeline_memwbRegister
    port map (
       clk => clk,
       stall => stall,
       nop => rst = '1',
       writeBackControlWordIn => wbControlWordFromExMem,
       execResultIn => execResFromExMem,
       memDataReadIn => memDataFromMem,
       destinationRegIn => destRegFromExMem,
       regWrite_override_in => regWriteOverrideFromExMem,
       writeBackControlWordOut => wbControlWordFromMemWb,
       execResultOut => execResFromMemWb,
       memDataReadOut => memDataFromMemWb,
       destinationRegOut => destRegFromMemWb,
       regWrite_override_out => regWriteOverrideFromMemWb
   );

    writeBack : entity work.mips32_pipeline_writeBack
    port map (
        writeBackControlWord => wbControlWordFromMemWb,
        execResult => execResFromMemWb,
        memDataRead => memDataFromMemWb,
        destinationReg => destRegFromMemWb,
        regWrite_override => regWriteOverrideFromMemWb,

        regWrite => regWriteFromWb,
        regWriteAddress => regWriteAddrFromWb,
        regWriteData => regWriteDataFromWb
    );

    -- Lives in EX stage
    forwarding_unit : entity work.mips32_pipeline_forwarding_unit
    port map (
        rsDataFromID => rsDataFromIdEx,
        rsAddressFromID => rsAddressFromIdEx,
        rtDataFromID => rtDataFromIdEx,
        rtAddressFromID => rtAddressFromIdEx,

        regDataFromEx => execResFromExMem,
        regAddressFromEx => destRegFromExMem,
        regWriteFromEx => wbControlWordFromExMem.regWrite,

        regDataFromMem => regWriteDataFromWb,
        regAddressFromMem => regWriteAddrFromWb,
        regWriteFromMem => regWriteFromWb,

        rsData => rsDataFromFwu,
        rtData => rtDataFromFwu
    );

    -- Lives in ID stage
    loadHazardDetector : entity work.mips32_pipeline_loadHazardDetector
    port map (
        writeBackControlWordFromEx => wbControlWordFromIdEx,
        targetRegFromEx => destRegFromIdEx,
        readPortOneAddressFromID => rtAddressFromId,
        readPortTwoAddressFromID => rsAddressFromId,
        loadHazardDetected => loadHazardDetected
    );

    -- Lives in ID stage
    registerFile : entity work.mips32_pipeline_registerFile
    port map (
        clk => clk,
        readPortOneAddress => rsAddressFromId,
        readPortOneData => rsDataFromRegFile,
        readPortTwoAddress => rtAddressFromId,
        readPortTwoData => rtDataFromRegFile,
        writePortDoWrite => regWriteFromWb,
        writePortAddress => regWriteAddrFromWb,
        writePortData => regWriteDataFromWb,
        extPortAddress => address_to_regFile,
        readPortExtData => data_from_regFile,
        writePortExtDoWrite => write_to_regFile,
        writePortExtData => data_to_regFile
    );

    branchHelper : entity work.mips32_pipeline_branchHelper
    port map (
        executeControlWord => exControlWordFromId,
        injectBubble => injectBubbleFromBranchHelper
    );

end architecture;
