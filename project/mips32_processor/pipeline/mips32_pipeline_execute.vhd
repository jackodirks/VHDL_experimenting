library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.mips32_pkg;

entity mips32_pipeline_execute is
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : in boolean;

        -- From decode stage: control signals
        writeBackControlWord : in mips32_pkg.WriteBackControlWord_type;
        memoryControlWord : in mips32_pkg.MemoryControlWord_type;
        executeControlWord : in mips32_pkg.ExecuteControlWord_type;

        -- From decode stage: data
        regDataA : in mips32_pkg.data_type;
        regDataB : in mips32_pkg.data_type;
        immidiate : in mips32_pkg.data_type;
        destinationReg : in mips32_pkg.registerFileAddress_type;
        aluFunction : in mips32_pkg.aluFunction_type;
        shamt : in mips32_pkg.shamt_type;

        -- To Memory stage: control signals
        memoryControlWordToMem : out mips32_pkg.MemoryControlWord_type;
        writeBackControlWordToMem : out mips32_pkg.WriteBackControlWord_type;

        -- To Memory stage: data
        aluResult : out mips32_pkg.data_type;
        regDataRead : out mips32_pkg.data_type;
        destinationRegToMem : out mips32_pkg.registerFileAddress_type
    );
end entity;

architecture behaviourial of mips32_pipeline_execute is
    signal aluResult_buf : mips32_pkg.data_type;
    signal aluInputB : mips32_pkg.data_type;
    signal aluFunctionInput : mips32_pkg.aluFunction_type;
begin
    exMemReg : process(clk)
        variable memoryControlWordToMem_buf : mips32_pkg.MemoryControlWord_type := mips32_pkg.memoryControlWordAllFalse;
        variable writeBackControlWordToMem_buf : mips32_pkg.WriteBackControlWord_type := mips32_pkg.writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                memoryControlWordToMem_buf := mips32_pkg.memoryControlWordAllFalse;
                writeBackControlWordToMem_buf := mips32_pkg.writeBackControlWordAllFalse;
            elsif not stall then
                memoryControlWordToMem_buf := memoryControlWord;
                writeBackControlWordToMem_buf := writeBackControlWord;
                aluResult <= aluResult_buf;
                regDataRead <= regDataB;
                destinationRegToMem <= destinationReg;
            end if;
        end if;
        memoryControlWordToMem <= memoryControlWordToMem_buf;
        writeBackControlWordToMem <= writeBackControlWordToMem_buf;
    end process;

    determineAluInputB : process(executeControlWord, immidiate, regDataB)
    begin
        if executeControlWord.ALUSrc then
            aluInputB <= immidiate;
        else
            aluInputB <= regDataB;
        end if;
    end process;

    determineAluFunctionInput : process(executeControlWord, aluFunction)
    begin
        if executeControlWord.ALUOpIsAdd then
            aluFunctionInput <= mips32_pkg.aluFunctionAddUnsigned;
        else
            aluFunctionInput <= aluFunction;
        end if;
    end process;

    alu : entity work.mips32_alu
    port map (
        inputA => regDataA,
        inputB => aluInputB,
        funct => aluFunctionInput,
        output => aluResult_buf
    );
end architecture;
