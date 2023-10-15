library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_pipeline_execute is
    port (
        -- From decode stage: control signals
        executeControlWord : in mips32_ExecuteControlWord_type;

        -- From decode stage: data
        rsData : in mips32_data_type;
        rtData : in mips32_data_type;
        immidiate : in mips32_data_type;
        shamt : in mips32_shamt_type;
        programCounterPlusFour : in mips32_address_type;

        -- To Memory stage: data
        execResult : out mips32_data_type;

        -- To instruction fetch: branch
        overrideProgramCounter : out boolean;
        newProgramCounter : out mips32_address_type
    );
end entity;

architecture behaviourial of mips32_pipeline_execute is
    signal aluResultImmidiate : mips32_data_type;
    signal aluResultRtype : mips32_data_type;
    signal shifterResult : mips32_data_type;
begin
    determineExecResult : process(executeControlWord, shifterResult, aluResultRtype, aluResultImmidiate)
    begin
        if executeControlWord.exec_directive = mips32_exec_alu then
            if executeControlWord.use_immidiate then
                execResult <= aluResultImmidiate;
            else
                execResult <= aluResultRtype;
            end if;
        elsif executeControlWord.exec_directive = mips32_exec_shift then
            execResult <= shifterResult;
        else
            execResult <= (others => 'X');
        end if;
    end process;

    determineBranchTarget : process(programCounterPlusFour, immidiate, rsData, executeControlWord)
    begin
        if executeControlWord.branch_cmd = cmd_branch_jumpreg then
            newProgramCounter <= rsData;
        else
            newProgramCounter <= std_logic_vector(signed(programCounterPlusFour) + shift_left(signed(immidiate), 2));
        end if;
    end process;

    determineOverridePC : process(executeControlWord, rsData, rtData)
    begin
        overrideProgramCounter <= false;
        if executeControlWord.exec_directive = mips32_exec_branch then
            case executeControlWord.branch_cmd is
                when cmd_branch_eq =>
                    overrideProgramCounter <= rsData = rtData;
                when cmd_branch_ne =>
                    overrideProgramCounter <= rsData /= rtData;
                when cmd_branch_bgez =>
                    overrideProgramCounter <= signed(rsData) >= 0;
                when cmd_branch_jumpreg =>
                    overrideProgramCounter <= true;
            end case;
        end if;
    end process;

    alu_immidiate : entity work.mips32_alu
    port map (
        inputA => rsData,
        inputB => immidiate,
        cmd => executeControlWord.alu_cmd,
        output => aluResultImmidiate
    );

    alu_rtype : entity work.mips32_alu
    port map (
        inputA => rsData,
        inputB => rtData,
        cmd => executeControlWord.alu_cmd,
        output => aluResultRtype
    );

    shifter : entity work.mips32_shifter
    port map (
        input => rtData,
        cmd => executeControlWord.shift_cmd,
        shamt => shamt,
        output => shifterResult
    );
end architecture;
