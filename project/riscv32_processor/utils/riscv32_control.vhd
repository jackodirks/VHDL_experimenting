library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.riscv32_pkg.all;

entity riscv32_control is
    port (
        instruction : in riscv32_instruction_type;

        instructionDecodeControlWord : out riscv32_InstructionDecodeControlWord_type;
        executeControlWord : out riscv32_ExecuteControlWord_type;
        memoryControlWord : out riscv32_MemoryControlWord_type;
        writeBackControlWord : out riscv32_WriteBackControlWord_type;

        illegal_instruction : out boolean

    );
end entity;

architecture behaviourial of riscv32_control is
begin
    decodeOpcode : process(instruction)
        variable instructionDecodeControlWord_buf : riscv32_InstructionDecodeControlWord_type;
        variable executeControlWord_buf : riscv32_ExecuteControlWord_type;
        variable memoryControlWord_buf : riscv32_MemoryControlWord_type;
        variable writeBackControlWord_buf : riscv32_WriteBackControlWord_type;

        variable opcode : riscv32_opcode_type;
    begin
        instructionDecodeControlWord_buf := riscv32_instructionDecodeControlWordAllFalse;
        executeControlWord_buf := riscv32_executeControlWordAllFalse;
        memoryControlWord_buf := riscv32_memoryControlWordAllFalse;
        writeBackControlWord_buf := riscv32_writeBackControlWordAllFalse;

        opcode := to_integer(unsigned(instruction(6 downto 0)));
        illegal_instruction <= false;

        case opcode is
            when riscv32_opcode_jal =>
                instructionDecodeControlWord_buf.jump := true;
                writeBackControlWord_buf.regWrite := true;
                executeControlWord_buf.exec_directive := riscv32_exec_calcReturn;
            when riscv32_opcode_opimm =>
                instructionDecodeControlWord_buf.immidiate_type := riscv32_i_immidiate;
            when riscv32_opcode_lui | riscv32_opcode_auipc =>
                instructionDecodeControlWord_buf.immidiate_type := riscv32_u_immidiate;
            when riscv32_opcode_branch =>
                instructionDecodeControlWord_buf.immidiate_type := riscv32_b_immidiate;
            when riscv32_opcode_load =>
                instructionDecodeControlWord_buf.immidiate_type := riscv32_i_immidiate;
            when riscv32_opcode_store =>
                instructionDecodeControlWord_buf.immidiate_type := riscv32_s_immidiate;
            when others =>
                illegal_instruction <= true;
        end case;

        instructionDecodeControlWord <= instructionDecodeControlWord_buf;
        executeControlWord <= executeControlWord_buf;
        memoryControlWord <= memoryControlWord_buf;
        writeBackControlWord <= writeBackControlWord_buf;

    end process;


end behaviourial;
