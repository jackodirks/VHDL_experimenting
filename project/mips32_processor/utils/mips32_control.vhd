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
            when mips32_opcodeAddiu =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcodeLw =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
            when mips32_opcodeBeq =>
                executeControlWord_buf.branchEq := true;
            when mips32_opcodeBne =>
                executeControlWord_buf.branchNe := true;
            when mips32_opcodeSw =>
                executeControlWord_buf.ALUOpDirective := exec_add;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
            when mips32_opcodeJ =>
                instructionDecodeControlWord_buf.jump := true;
            when mips32_opcodeJal =>
                instructionDecodeControlWord_buf.jump := true;
                writeBackControlWord_buf.regWrite := true;
                executeControlWord_buf.ALUOpDirective := exec_add;
            when mips32_opcodeLui =>
                executeControlWord_buf.isLui := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcodeCOP0 =>
                if mf = 0 then
                    -- mfc0, move from system control processor
                    writeBackControlWord_buf.regWrite := true;
                    writeBackControlWord_buf.cop0ToReg := true;
                elsif mf = 4 then
                    -- mtc0, move to system control processor
                    memoryControlWord_buf.cop0Write := true;
                else
                    invalidOpcode <= true;
                end if;
            when others =>
                invalidOpcode <= true;
        end case;
        instructionDecodeControlWord <= instructionDecodeControlWord_buf;
        executeControlWord <= executeControlWord_buf;
        memoryControlWord <= memoryControlWord_buf;
        writeBackControlWord <= writeBackControlWord_buf;
    end process;


end behaviourial;
