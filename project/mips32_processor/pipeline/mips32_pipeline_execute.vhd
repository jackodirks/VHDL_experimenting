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
        rdAddress : in mips32_registerFileAddress_type;

        -- To Memory stage: data
        execResult : out mips32_data_type;
        regWrite_override : out boolean;

        -- To instruction fetch: branch
        overrideProgramCounter : out boolean;
        newProgramCounter : out mips32_address_type
    );
end entity;

architecture behaviourial of mips32_pipeline_execute is
    signal aluResultImmidiate : mips32_data_type;
    signal aluResultRtype : mips32_data_type;
    signal shifterResult : mips32_data_type;
    signal bitManip_result : mips32_data_type;
    signal overrideProgramCounter_buf : boolean;

    signal regWrite_override_branch : boolean;
    signal regWrite_override_movz : boolean;
begin

    overrideProgramCounter <= overrideProgramCounter_buf;
    regWrite_override_branch <= executeControlWord.regWrite_override_on_branch and overrideProgramCounter_buf;
    regWrite_override_movz <= executeControlWord.regWrite_override_on_rt_zero and unsigned(rtData) = 0;

    regWrite_override <= regWrite_override_branch or regWrite_override_movz;

    determineExecResult : process(executeControlWord, shifterResult, aluResultRtype, aluResultImmidiate, programCounterPlusFour, bitManip_result)
    begin
        case executeControlWord.exec_directive is
            when mips32_exec_alu =>
                if executeControlWord.use_immidiate then
                    execResult <= aluResultImmidiate;
                else
                    execResult <= aluResultRtype;
                end if;
            when mips32_exec_shift =>
                execResult <= shifterResult;
            when mips32_exec_calcReturn =>
                execResult <= std_logic_vector(unsigned(programCounterPlusFour) + 4);
            when mips32_exec_bitManip =>
                execResult <= bitManip_result;
        end case;
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
        overrideProgramCounter_buf <= false;
        if executeControlWord.is_branch_op then
            case executeControlWord.branch_cmd is
                when cmd_branch_eq =>
                    overrideProgramCounter_buf <= rsData = rtData;
                when cmd_branch_ne =>
                    overrideProgramCounter_buf <= rsData /= rtData;
                when cmd_branch_bgez =>
                    overrideProgramCounter_buf <= signed(rsData) >= 0;
                when cmd_branch_blez =>
                    overrideProgramCounter_buf <= signed(rsData) <= 0;
                when cmd_branch_bgtz =>
                    overrideProgramCounter_buf <= signed(rsData) > 0;
                when cmd_branch_bltz =>
                    overrideProgramCounter_buf <= signed(rsData) < 0;
                when cmd_branch_jumpreg =>
                    overrideProgramCounter_buf <= true;
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

    bit_manipulator : entity work.mips32_bit_manipulator
    port map (
        rs => rsData,
        rt => rtData,
        msb => rdAddress,
        lsb => shamt,
        cmd => executeControlWord.bitManip_cmd,
        output => bitManip_result
    );
end architecture;
