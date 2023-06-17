library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_control is
    port (
        opcode : in mips32_opcode_type;

        instructionDecodeControlWord : out mips32_InstructionDecodeControlWord_type;
        executeControlWord : out mips32_ExecuteControlWord_type;
        memoryControlWord : out mips32_MemoryControlWord_type;
        writeBackControlWord : out mips32_WriteBackControlWord_type;
        invalidOpcode : out boolean
    );
end entity;

architecture behaviourial of mips32_control is
begin

    decodeOpcode : process(opcode)
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
                instructionDecodeControlWord_buf.regDst := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcodeAddiu =>
                executeControlWord_buf.ALUOpIsAdd := true;
                executeControlWord_buf.ALUSrc := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_opcodeLw =>
                executeControlWord_buf.ALUOpIsAdd := true;
                executeControlWord_buf.ALUSrc := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
            when mips32_opcodeBeq =>
                -- Pass, unsupported for now
            when mips32_opcodeSw =>
                executeControlWord_buf.ALUOpIsAdd := true;
                executeControlWord_buf.ALUSrc := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
            when mips32_opcodeJ =>
                instructionDecodeControlWord_buf.jump := true;
            when mips32_opcodeLui =>
                executeControlWord_buf.lui := true;
                writeBackControlWord_buf.regWrite := true;
            when others =>
                invalidOpcode <= true;
        end case;
        instructionDecodeControlWord <= instructionDecodeControlWord_buf;
        executeControlWord <= executeControlWord_buf;
        memoryControlWord <= memoryControlWord_buf;
        writeBackControlWord <= writeBackControlWord_buf;
    end process;


end behaviourial;
