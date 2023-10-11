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

        instructionDecodeControlWord : out mips32_InstructionDecodeControlWord_type;
        executeControlWord : out mips32_ExecuteControlWord_type;
        memoryControlWord : out mips32_MemoryControlWord_type;
        writeBackControlWord : out mips32_WriteBackControlWord_type;
        invalidOpcode : out boolean
    );
end entity;

architecture behaviourial of mips32_control is
begin

    decodeOpcode : process(opcode, mf)
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
        case opcode is
            when mips32_opcodeRType =>
                instructionDecodeControlWord_buf.regDstIsRd := true;
                writeBackControlWord_buf.regWrite := true;
                executeControlWord_buf.isRtype := true;
            when mips32_opcodeJ =>
                instructionDecodeControlWord_buf.jump := true;
            when mips32_opcodeJal =>
                instructionDecodeControlWord_buf.jump := true;
                writeBackControlWord_buf.regWrite := true;
                executeControlWord_buf.ALUOpDirective := exec_add;
            when mips32_opcodeBeq =>
                executeControlWord_buf.branchEq := true;
            when mips32_opcodeBne =>
                executeControlWord_buf.branchNe := true;
            when mips32_opcodeAddiu =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcodeLui =>
                executeControlWord_buf.isLui := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcodeCOP0 =>
                if mf = mips32_mf_mfc0 then
                    writeBackControlWord_buf.regWrite := true;
                    writeBackControlWord_buf.MemtoReg := true;
                elsif mf = mips32_mf_mtc0 then
                    memoryControlWord_buf.cop0Write := true;
                else
                    invalidOpcode <= true;
                end if;
            when mips32_opcodeLb =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.memReadSignExtend := true;
                memoryControlWord_buf.loadStoreSize := ls_byte;
            when mips32_opcodeLh =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.memReadSignExtend := true;
                memoryControlWord_buf.loadStoreSize := ls_halfword;
            when mips32_opcodeLwl =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.wordLeft := true;
            when mips32_opcodeLw =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
            when mips32_opcodeLhu =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.loadStoreSize := ls_halfword;
            when mips32_opcodeLwr =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.wordRight := true;
            when mips32_opcodeLbu =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
                memoryControlWord_buf.loadStoreSize := ls_byte;
            when mips32_opcodeSb =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.loadStoreSize := ls_byte;
            when mips32_opcodeSh =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.loadStoreSize := ls_halfword;
            when mips32_opcodeSwl =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
                memoryControlWord_buf.wordLeft := true;
            when mips32_opcodeSw =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
            when mips32_opcodeSwr =>
                executeControlWord_buf.ALUOpDirective := exec_add;
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
