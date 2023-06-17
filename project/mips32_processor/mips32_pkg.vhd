library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package mips32_pkg is
    constant mips32_address_width_log2b : natural := 5;
    constant mips32_data_width_log2b : natural := 5;
    constant mips32_instruction_width_log2b : natural := 5;
    constant mips32_byte_width_log2b : natural := 3;

    constant mips32_bytes_per_data_word : natural := 2**(mips32_data_width_log2b - mips32_byte_width_log2b);

    subtype mips32_address_type is std_logic_vector(2**mips32_address_width_log2b - 1 downto  0);
    subtype mips32_data_type is std_logic_vector(2**mips32_data_width_log2b -1 downto 0);
    subtype mips32_instruction_type is std_logic_vector(2**mips32_instruction_width_log2b - 1 downto 0);
    subtype mips32_byte_type is std_logic_vector(2**mips32_byte_width_log2b - 1 downto 0);
    subtype mips32_opcode_type is natural range 0 to 63;
    subtype mips32_registerFileAddress_type is natural range 0 to 31;
    subtype mips32_aluFunction_type is natural range 0 to 63;
    subtype mips32_shamt_type is natural range 0 to 31;

    type mips32_data_array is array (natural range <>) of mips32_data_type;
    type mips32_byte_array is array (natural range <>) of mips32_byte_type;
    type mips32_exec_directive is (exec_rtype, exec_add, exec_sub);

    type mips32_InstructionDecodeControlWord_type is record
        jump : boolean;
        PCSrc : boolean;
        regDst : boolean;
    end record;

    type mips32_ExecuteControlWord_type is record
        ALUSrc : boolean;
        ALUOpDirective : mips32_exec_directive;
        branchEq : boolean;
        lui : boolean;
    end record;

    type mips32_MemoryControlWord_type is record
        MemOp : boolean;
        MemOpIsWrite : boolean;
    end record;

    type mips32_WriteBackControlWord_type is record
        regWrite : boolean;
        MemtoReg : boolean;
    end record;

    constant mips32_instructionDecodeControlWordAllFalse : mips32_InstructionDecodeControlWord_type := (
        jump => false,
        PCSrc => false,
        regDst => false
    );

    constant mips32_executeControlWordAllFalse : mips32_ExecuteControlWord_type := (
        ALUSrc => false,
        ALUOpDirective => exec_rtype,
        lui => false,
        branchEq => false
    );

    constant mips32_memoryControlWordAllFalse : mips32_MemoryControlWord_type := (
        MemOp => false,
        MemOpIsWrite => false
    );

    constant mips32_writeBackControlWordAllFalse : mips32_WriteBackControlWord_type := (
        regWrite => false,
        MemtoReg => false
    );

    -- To begin, this processor will support the following instructions:
    -- lw, sw, beq, add, sub, and, or, slt, j
    -- The nop, for now, will be and $0 $0 $0
    constant mips32_instructionNop : mips32_instruction_type := X"00000024";

    constant mips32_opcodeRType : mips32_opcode_type := 16#0#;
    constant mips32_opcodeAddiu : mips32_opcode_type := 16#9#;
    constant mips32_opcodeLw : mips32_opcode_type := 16#23#;
    constant mips32_opcodeSw : mips32_opcode_type := 16#2b#;
    constant mips32_opcodeBeq : mips32_opcode_type := 16#4#;
    constant mips32_opcodeJ : mips32_opcode_type := 16#2#;
    constant mips32_opcodeLui : mips32_opcode_type := 16#f#;

    constant mips32_aluFunctionAdd : mips32_aluFunction_type := 16#20#;
    constant mips32_aluFunctionAddUnsigned : mips32_aluFunction_type := 16#21#;
    constant mips32_aluFunctionSubtract : mips32_aluFunction_type := 16#22#;
    constant mips32_aluFunctionSubtractUnsigned : mips32_aluFunction_type := 16#23#;
    constant mips32_aluFunctionAnd : mips32_aluFunction_type := 16#24#;
    constant mips32_aluFunctionOr : mips32_aluFunction_type := 16#25#;
    constant mips32_aluFunctionSetLessThan : mips32_aluFunction_type := 16#2a#;
end package;
