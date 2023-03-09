library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.mips32_pkg;

entity mips32_control is
    port (
        opcode : in mips32_pkg.opcode_type;

        instructionDecodeControlWord : out mips32_pkg.InstructionDecodeControlWord_type;
        executeControlWord : out mips32_pkg.ExecuteControlWord_type;
        memoryControlWord : out mips32_pkg.MemoryControlWord_type;
        writeBackControlWord : out mips32_pkg.WriteBackControlWord_type;
        invalidOpcode : out boolean
    );
end entity;

architecture behaviourial of mips32_control is
begin

    decodeOpcode : process(opcode)
        variable instructionDecodeControlWord_buf : mips32_pkg.InstructionDecodeControlWord_type;
        variable executeControlWord_buf : mips32_pkg.ExecuteControlWord_type;
        variable memoryControlWord_buf : mips32_pkg.MemoryControlWord_type;
        variable writeBackControlWord_buf : mips32_pkg.WriteBackControlWord_type;
    begin
        instructionDecodeControlWord_buf := mips32_pkg.instructionDecodeControlWordAllFalse;
        executeControlWord_buf := mips32_pkg.executeControlWordAllFalse;
        memoryControlWord_buf := mips32_pkg.memoryControlWordAllFalse;
        writeBackControlWord_buf := mips32_pkg.writeBackControlWordAllFalse;
        invalidOpcode <= false;
        case opcode is
            when mips32_pkg.opcodeRType =>
                instructionDecodeControlWord_buf.regDst := true;
                writeBackControlWord_buf.regWrite := true;
            when mips32_pkg.opcodeLw =>
                executeControlWord_buf.ALUOpIsAdd := true;
                executeControlWord_buf.ALUSrc := true;
                writeBackControlWord_buf.MemtoReg := true;
                writeBackControlWord_buf.regWrite := true;
                memoryControlWord_buf.memOp := true;
            when mips32_pkg.opcodeBeq =>
                instructionDecodeControlWord_buf.branch := true;
            when mips32_pkg.opcodeSw =>
                executeControlWord_buf.ALUOpIsAdd := true;
                executeControlWord_buf.ALUSrc := true;
                memoryControlWord_buf.MemOp := true;
                memoryControlWord_buf.MemOpIsWrite := true;
            when mips32_pkg.opcodeJ =>
                instructionDecodeControlWord_buf.jump := true;
            when others =>
                invalidOpcode <= true;
        end case;
        instructionDecodeControlWord <= instructionDecodeControlWord_buf;
        executeControlWord <= executeControlWord_buf;
        memoryControlWord <= memoryControlWord_buf;
        writeBackControlWord <= writeBackControlWord_buf;
    end process;


end behaviourial;
