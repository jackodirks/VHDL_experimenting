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

        -- To Memory stage: control signals
        memoryControlWordToMem : out mips32_MemoryControlWord_type;
        writeBackControlWordToMem : out mips32_WriteBackControlWord_type;

        -- To Memory stage: data
        execResult : out mips32_data_type;
        regDataRead : out mips32_data_type;
        destinationRegToMem : out mips32_registerFileAddress_type;

        -- To instruction fetch: branch
        overrideProgramCounter : out boolean;
        newProgramCounter : out mips32_address_type;

        -- To instrucion decode
        justBranched : out boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_execute is
    signal execResult_buf : mips32_data_type;
    signal aluResult : mips32_data_type;
    signal luiResult : mips32_data_type;
    signal aluInputB : mips32_data_type;
    signal aluFunctionInput : mips32_aluFunction_type;
    signal overrideProgramCounter_buf : boolean;
begin
    luiResult <= std_logic_vector(shift_left(unsigned(immidiate), 16));
    overrideProgramCounter <= overrideProgramCounter_buf;

    exMemReg : process(clk)
        variable memoryControlWordToMem_buf : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
        variable writeBackControlWordToMem_buf : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                memoryControlWordToMem_buf := mips32_memoryControlWordAllFalse;
                writeBackControlWordToMem_buf := mips32_writeBackControlWordAllFalse;
                justBranched <= false;
            elsif not stall then
                memoryControlWordToMem_buf := memoryControlWord;
                writeBackControlWordToMem_buf := writeBackControlWord;
                execResult <= execResult_buf;
                regDataRead <= rtData;
                destinationRegToMem <= destinationReg;
                justBranched <= overrideProgramCounter_buf;
            end if;
        end if;
        memoryControlWordToMem <= memoryControlWordToMem_buf;
        writeBackControlWordToMem <= writeBackControlWordToMem_buf;
    end process;

    determineBranchTarget : process(programCounterPlusFour, immidiate, rsData, aluFunction)
    begin
        if aluFunction = mips32_aluFunctionJumpReg then
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
        end if;

        if executeControlWord.branchNe and rsData /= rtData then
            overrideProgramCounter_buf <= true;
        end if;

        if aluFunction = mips32_aluFunctionJumpReg then
            overrideProgramCounter_buf <= true;
        end if;
    end process;

    determineAluInputB : process(executeControlWord, immidiate, rtData)
    begin
        if executeControlWord.ALUSrc then
            aluInputB <= immidiate;
        else
            aluInputB <= rtData;
        end if;
    end process;

    determineAluFunctionInput : process(executeControlWord, aluFunction)
    begin
        case executeControlWord.ALUOpDirective is
            when exec_add =>
                aluFunctionInput <= mips32_aluFunctionAddUnsigned;
            when exec_sub =>
                aluFunctionInput <= mips32_aluFunctionSubtractUnsigned;
            when others =>
                aluFunctionInput <= aluFunction;
        end case;
    end process;

    determineExecResult : process(aluResult, luiResult, executeControlWord)
    begin
        if executeControlWord.lui then
            execResult_buf <= luiResult;
        else
            execResult_buf <= aluResult;
        end if;
    end process;

    alu : entity work.mips32_alu
    port map (
        inputA => rsData,
        inputB => aluInputB,
        funct => aluFunctionInput,
        shamt => shamt,
        output => aluResult
    );
end architecture;
