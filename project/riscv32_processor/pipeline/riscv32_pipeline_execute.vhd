library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.riscv32_pkg.all;

entity riscv32_pipeline_execute is
    port (
        -- From decode stage: control signals
        executeControlWord : in riscv32_ExecuteControlWord_type;

        -- From decode stage: data
        rs1Data : in riscv32_data_type;
        rs2Data : in riscv32_data_type;
        immidiate : in riscv32_data_type;
        programCounter : in riscv32_address_type;

        -- To Memory stage: data
        execResult : out riscv32_data_type;

        -- To instruction fetch: branch
        overrideProgramCounter : out boolean;
        newProgramCounter : out riscv32_address_type
    );
end entity;

architecture behaviourial of riscv32_pipeline_execute is
    signal aluResultImmidiate : riscv32_data_type;
    signal aluResultRtype : riscv32_data_type;
    signal bitManip_result : riscv32_data_type;
begin
    determineExecResult : process(executeControlWord, aluResultRtype, aluResultImmidiate, programCounter)
    begin
        case executeControlWord.exec_directive is
            when riscv32_exec_alu_rtype =>
                execResult <= aluResultRtype;
            when riscv32_exec_alu_imm =>
                execResult <= aluResultImmidiate;
            when riscv32_exec_calcReturn =>
                execResult <= std_logic_vector(unsigned(programCounter) + 4);
            when riscv32_exec_lui =>
                execResult <= immidiate;
            when riscv32_exec_auipc =>
                execResult <= std_logic_vector(signed(immidiate) + signed(programCounter));
        end case;
    end process;

    determineBranchTarget : process(programCounter, immidiate, rs1Data, executeControlWord)
    begin
        if executeControlWord.branch_cmd = cmd_branch_jalr then
            newProgramCounter <= std_logic_vector(signed(rs1Data) + signed(immidiate));
        else
            newProgramCounter <= std_logic_vector(signed(programCounter) + signed(immidiate));
        end if;
    end process;

    determineOverridePC : process(executeControlWord, rs1Data, rs2Data)
    begin
        overrideProgramCounter <= false;
        if executeControlWord.is_branch_op then
            case executeControlWord.branch_cmd is
                when cmd_branch_eq =>
                    overrideProgramCounter <= rs1Data = rs2Data;
                when cmd_branch_ne =>
                    overrideProgramCounter <= rs1Data /= rs2Data;
                when cmd_branch_lt =>
                    overrideProgramCounter <= signed(rs1Data) < signed(rs2Data);
                when cmd_branch_ltu =>
                    overrideProgramCounter <= unsigned(rs1Data) < unsigned(rs2Data);
                when cmd_branch_ge =>
                    overrideProgramCounter <= signed(rs1Data) >= signed(rs2Data);
                when cmd_branch_geu =>
                    overrideProgramCounter <= unsigned(rs1Data) >= unsigned(rs2Data);
                when cmd_branch_jalr =>
                    overrideProgramCounter <= true;
            end case;
        end if;
    end process;

    alu_immidiate : entity work.riscv32_alu
    port map (
        inputA => rs1Data,
        inputB => immidiate,
        shamt => to_integer(unsigned(immidiate(4 downto 0))),
        cmd => executeControlWord.alu_cmd,
        output => aluResultImmidiate
    );

    alu_rtype : entity work.riscv32_alu
    port map (
        inputA => rs1Data,
        inputB => rs2Data,
        shamt => to_integer(unsigned(rs2Data(4 downto 0))),
        cmd => executeControlWord.alu_cmd,
        output => aluResultRtype
    );

end architecture;
