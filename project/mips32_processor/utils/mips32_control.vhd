library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_control is
    port (
        opcode : in mips32_opcode_type;
        mf : in mips32_mf_type;
        func : in mips32_function_type;
        regimm : in mips32_regimm_type;

        instructionDecodeControlWord : out mips32_InstructionDecodeControlWord_type;
        executeControlWord : out mips32_ExecuteControlWord_type;
        memoryControlWord : out mips32_MemoryControlWord_type;
        writeBackControlWord : out mips32_WriteBackControlWord_type;
        invalidOpcode : out boolean;
        invalidFunction : out boolean;
        invalidRegimm : out boolean
    );
end entity;

architecture behaviourial of mips32_control is
begin

    decodeOpcode : process(opcode, mf, func, regimm)
        variable instructionDecodeControlWord_buf : mips32_InstructionDecodeControlWord_type;
        variable executeControlWord_buf : mips32_ExecuteControlWord_type;
        variable memoryControlWord_buf : mips32_MemoryControlWord_type;
        variable writeBackControlWord_buf : mips32_WriteBackControlWord_type;
    begin
        instructionDecodeControlWord_buf := mips32_instructionDecodeControlWordAllFalse;
        executeControlWord_buf := mips32_executeControlWordAllFalse;
        memoryControlWord_buf := mips32_memoryControlWordAllFalse;
        writeBackControlWord_buf := mips32_writeBackControlWordAllFalse;
        invalidOpcode <= false;
        invalidFunction <= false;
        invalidRegimm <= false;
        case opcode is
            when mips32_opcode_special =>
                instructionDecodeControlWord_buf.regDstIsRd := true;
                writeBackControlWord_buf.regWrite := true;
                case func is
                    when mips32_function_sll =>
                        executeControlWord_buf.exec_directive := mips32_exec_shift;
                        executeControlWord_buf.shift_cmd := cmd_shift_sll;
                    when mips32_function_srl =>
                        executeControlWord_buf.exec_directive := mips32_exec_shift;
                        executeControlWord_buf.shift_cmd := cmd_shift_srl;
                    when mips32_function_sra =>
                        executeControlWord_buf.exec_directive := mips32_exec_shift;
                        executeControlWord_buf.shift_cmd := cmd_shift_sra;
                    when mips32_function_JumpReg =>
                        executeControlWord_buf.is_branch_op := true;
                        executeControlWord_buf.branch_cmd := cmd_branch_jumpreg;
                    when mips32_function_add | mips32_function_AddUnsigned =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_add;
                    when mips32_function_Subtract | mips32_function_SubtractUnsigned =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_sub;
                    when mips32_function_And =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_and;
                    when mips32_function_Or =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_or;
                    when mips32_function_Nor =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_nor;
                    when mips32_function_SetLessThan =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_slt;
                    when mips32_function_SetLessThanUnsigned =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_sltu;
                    when others =>
                        invalidFunction <= true;
                end case;
            when mips32_opcode_regimm =>
                case regimm is
                    when mips32_regimm_bltz|mips32_regimm_bltzl =>
                        executeControlWord_buf.is_branch_op := true;
                        executeControlWord_buf.branch_cmd := cmd_branch_bltz;
                    when mips32_regimm_bgez|mips32_regimm_bgezl =>
                        executeControlWord_buf.is_branch_op := true;
                        executeControlWord_buf.branch_cmd := cmd_branch_bgez;
                    when mips32_regimm_bgezal|mips32_regimm_bgezall =>
                        instructionDecodeControlWord_buf.regDstIsRetReg := true;
                        executeControlWord_buf.is_branch_op := true;
                        executeControlWord_buf.branch_cmd := cmd_branch_bgez;
                        executeControlWord_buf.exec_directive := mips32_exec_calcReturn;
                        executeControlWord_buf.regWrite_override_on_branch := true;
                    when mips32_regimm_bltzal|mips32_regimm_bltzall =>
                        instructionDecodeControlWord_buf.regDstIsRetReg := true;
                        executeControlWord_buf.is_branch_op := true;
                        executeControlWord_buf.branch_cmd := cmd_branch_bltz;
                        executeControlWord_buf.exec_directive := mips32_exec_calcReturn;
                        executeControlWord_buf.regWrite_override_on_branch := true;
                    when others =>
                        invalidRegimm <= true;
                end case;
            when mips32_opcode_J =>
                instructionDecodeControlWord_buf.jump := true;
            when mips32_opcode_Jal =>
                instructionDecodeControlWord_buf.jump := true;
                instructionDecodeControlWord_buf.regDstIsRetReg := true;
                writeBackControlWord_buf.regWrite := true;
                executeControlWord_buf.exec_directive := mips32_exec_calcReturn;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcode_Beq | mips32_opcode_Beql =>
                executeControlWord_buf.is_branch_op := true;
                executeControlWord_buf.branch_cmd := cmd_branch_eq;
            when mips32_opcode_Bne | mips32_opcode_bnel =>
                executeControlWord_buf.is_branch_op := true;
                executeControlWord_buf.branch_cmd := cmd_branch_ne;
            when mips32_opcode_blez|mips32_opcode_blezl =>
                executeControlWord_buf.is_branch_op := true;
                executeControlWord_buf.branch_cmd := cmd_branch_blez;
            when mips32_opcode_bgtz | mips32_opcode_bgtzl =>
                executeControlWord_buf.is_branch_op := true;
                executeControlWord_buf.branch_cmd := cmd_branch_bgtz;
            when mips32_opcode_Addiu | mips32_opcode_Addi =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcode_Andi =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_and;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcode_Lui =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_lui;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcode_COP0 =>
                if mf = mips32_mf_mfc0 then
                    writeBackControlWord_buf.regWrite := true;
                    writeBackControlWord_buf.MemtoReg := true;
                elsif mf = mips32_mf_mtc0 then
                    memoryControlWord_buf.cop0Write := true;
                else
                    invalidOpcode <= true;
                end if;
            when mips32_opcode_specialTwo =>
                instructionDecodeControlWord_buf.regDstIsRd := true;
                writeBackControlWord_buf.regWrite := true;
                case func is
                    when mips32_specialTwo_clo =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_clo;
                    when mips32_specialTwo_clz =>
                        executeControlWord_buf.exec_directive := mips32_exec_alu;
                        executeControlWord_buf.alu_cmd := cmd_alu_clz;
                    when others =>
                        invalidFunction <= true;
                end case;
            when mips32_opcode_Lb =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.memReadSignExtend := true;
                memoryControlWord_buf.loadStoreSize := ls_byte;
            when mips32_opcode_Lh =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.memReadSignExtend := true;
                memoryControlWord_buf.loadStoreSize := ls_halfword;
            when mips32_opcode_Lwl =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.wordLeft := true;
            when mips32_opcode_Lw =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
            when mips32_opcode_Lhu =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.loadStoreSize := ls_halfword;
            when mips32_opcode_Lwr =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.wordRight := true;
            when mips32_opcode_Lbu =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.loadStoreSize := ls_byte;
            when mips32_opcode_Sb =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.loadStoreSize := ls_byte;
            when mips32_opcode_Sh =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.loadStoreSize := ls_halfword;
            when mips32_opcode_Swl =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.wordLeft := true;
            when mips32_opcode_Sw =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
            when mips32_opcode_Swr =>
                executeControlWord_buf.exec_directive := mips32_exec_alu;
                executeControlWord_buf.alu_cmd := cmd_alu_add;
                executeControlWord_buf.use_immidiate := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.wordRight := true;
            when others =>
                invalidOpcode <= true;
        end case;
        instructionDecodeControlWord <= instructionDecodeControlWord_buf;
        executeControlWord <= executeControlWord_buf;
        memoryControlWord <= memoryControlWord_buf;
        writeBackControlWord <= writeBackControlWord_buf;
    end process;


end behaviourial;
