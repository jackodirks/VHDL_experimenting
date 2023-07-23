library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_pipeline_execute is
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        -- From decode stage: control signals
        writeBackControlWord : in mips32_WriteBackControlWord_type;
        memoryControlWord : in mips32_MemoryControlWord_type;
        executeControlWord : in mips32_ExecuteControlWord_type;

        -- From decode stage: data
        rsData : in mips32_data_type;
        rtData : in mips32_data_type;
        immidiate : in mips32_data_type;
        destinationReg : in mips32_registerFileAddress_type;
        aluFunction : in mips32_aluFunction_type;
        shamt : in mips32_shamt_type;
        programCounterPlusFour : in mips32_address_type;
        rdAddress : in mips32_registerFileAddress_type;

        -- To Memory stage: control signals
        memoryControlWordToMem : out mips32_MemoryControlWord_type;
        writeBackControlWordToMem : out mips32_WriteBackControlWord_type;

        -- To Memory stage: data
        execResult : out mips32_data_type;
        regDataRead : out mips32_data_type;
        destinationRegToMem : out mips32_registerFileAddress_type;
        rdAddressToMem : out mips32_registerFileAddress_type;

        -- To instruction fetch: branch
        overrideProgramCounter : out boolean;
        newProgramCounter : out mips32_address_type
    );
end entity;

architecture behaviourial of mips32_pipeline_execute is
    signal execResult_buf : mips32_data_type;
    signal aluResultImmidiate : mips32_data_type;
    signal aluResultRtype : mips32_data_type;
    signal luiResult : mips32_data_type;
    signal shifterResult : mips32_data_type;
    signal shifterActive : boolean;
    signal aluCmd : mips32_alu_cmd;
    signal overrideProgramCounter_buf : boolean;

    pure function translateAluFunc( func : mips32_aluFunction_type) return mips32_alu_cmd is
        variable ret : mips32_alu_cmd := cmd_add;
    begin
        case func is
            when mips32_aluFunctionSll =>
                ret := cmd_sll;
            when mips32_aluFunctionSrl =>
                ret := cmd_srl;
            when mips32_aluFunctionAdd | mips32_aluFunctionAddUnsigned =>
                ret := cmd_add;
            when mips32_aluFunctionSubtract | mips32_aluFunctionSubtractUnsigned =>
                ret := cmd_sub;
            when mips32_aluFunctionAnd =>
                ret := cmd_and;
            when mips32_aluFunctionOr =>
                ret := cmd_or;
            when mips32_aluFunctionNor =>
                ret := cmd_nor;
            when mips32_aluFunctionSetLessThan =>
                ret := cmd_slt;
            when mips32_aluFunctionSetLessThanUnsigned =>
                ret := cmd_sltu;
            when mips32_aluFunctionSra =>
                ret := cmd_sra;
            when others =>
                ret := cmd_add;
        end case;
        return ret;
    end function;

begin
    overrideProgramCounter <= overrideProgramCounter_buf;
    luiResult <= std_logic_vector(shift_left(unsigned(immidiate), 16));

    determineExecResult : process(luiResult, aluResultRtype, aluResultImmidiate, shifterResult, executeControlWord, shifterActive)
    begin
        if executeControlWord.isLui then
            execResult_buf <= luiResult;
        elsif shifterActive and executeControlWord.isRtype then
            execResult_buf <= shifterResult;
        elsif executeControlWord.isRtype then
            execResult_buf <= aluResultRtype;
        else
            execResult_buf <= aluResultImmidiate;
        end if;
    end process;


    exMemReg : process(clk)
        variable memoryControlWordToMem_buf : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
        variable writeBackControlWordToMem_buf : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                memoryControlWordToMem_buf := mips32_memoryControlWordAllFalse;
                writeBackControlWordToMem_buf := mips32_writeBackControlWordAllFalse;
            elsif not stall then
                memoryControlWordToMem_buf := memoryControlWord;
                writeBackControlWordToMem_buf := writeBackControlWord;
                execResult <= execResult_buf;
                regDataRead <= rtData;
                destinationRegToMem <= destinationReg;
                rdAddressToMem <= rdAddress;
            end if;
        end if;
        memoryControlWordToMem <= memoryControlWordToMem_buf;
        writeBackControlWordToMem <= writeBackControlWordToMem_buf;
    end process;

    determineBranchTarget : process(programCounterPlusFour, immidiate, rsData, aluFunction)
    begin
        if executeControlWord.isRtype and aluFunction = mips32_aluFunctionJumpReg then
            newProgramCounter <= rsData;
        else
            newProgramCounter <= std_logic_vector(signed(programCounterPlusFour) + shift_left(signed(immidiate), 2));
        end if;
    end process;

    determineOverridePC : process(executeControlWord, rsData, rtData, aluFunction)
    begin
        overrideProgramCounter_buf <= false;
        if executeControlWord.branchEq and rsData = rtData then
            overrideProgramCounter_buf <= true;
        elsif executeControlWord.branchNe and rsData /= rtData then
            overrideProgramCounter_buf <= true;
        elsif executeControlWord.isRtype and aluFunction = mips32_aluFunctionJumpReg then
            overrideProgramCounter_buf <= true;
        end if;
    end process;

    determineAluFunctionInput : process(executeControlWord, aluFunction)
    begin
        case executeControlWord.ALUOpDirective is
            when exec_add =>
                aluCmd <= cmd_add;
            when others =>
                aluCmd <= cmd_sub;
        end case;
    end process;

    alu_immidiate : entity work.mips32_alu
    port map (
        inputA => rsData,
        inputB => immidiate,
        cmd => aluCmd,
        output => aluResultImmidiate
    );

    alu_rtype : entity work.mips32_alu
    port map (
        inputA => rsData,
        inputB => rtData,
        cmd => translateAluFunc(aluFunction),
        output => aluResultRtype
    );

    shifter : entity work.mips32_shifter
    port map (
        input => rtData,
        cmd => translateAluFunc(aluFunction),
        shamt => shamt,
        output => shifterResult,
        active => shifterActive
    );
end architecture;
