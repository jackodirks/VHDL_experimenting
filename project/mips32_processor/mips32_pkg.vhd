library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package mips32_pkg is
    constant address_width_log2b : natural := 5;
    constant data_width_log2b : natural := 5;
    constant instruction_width_log2b : natural := 5;
    constant byte_width_log2b : natural := 3;

    constant bytes_per_data_word : natural := 2**(data_width_log2b - byte_width_log2b);

    subtype address_type is std_logic_vector(2**address_width_log2b - 1 downto  0);
    subtype data_type is std_logic_vector(2**data_width_log2b -1 downto 0);
    subtype instruction_type is std_logic_vector(2**instruction_width_log2b - 1 downto 0);
    subtype byte_type is std_logic_vector(2**byte_width_log2b - 1 downto 0);
    subtype opcode_type is natural range 0 to 63;
    subtype registerFileAddress_type is natural range 0 to 31;
    subtype aluFunction_type is natural range 0 to 63;
    subtype shamt_type is natural range 0 to 31;

    type data_array is array (natural range <>) of data_type;
    type byte_array is array (natural range <>) of byte_type;

    type InstructionDecodeControlWord_type is record
        branch : boolean;
        jump : boolean;
        PCSrc : boolean;
        regDst : boolean;
    end record;

    type ExecuteControlWord_type is record
        ALUSrc : boolean;
        ALUOpIsAdd : boolean;
        lui : boolean;
    end record;

    type MemoryControlWord_type is record
        MemOp : boolean;
        MemOpIsWrite : boolean;
    end record;

    type WriteBackControlWord_type is record
        regWrite : boolean;
        MemtoReg : boolean;
    end record;

    constant instructionDecodeControlWordAllFalse : InstructionDecodeControlWord_type := (
        branch => false,
        jump => false,
        PCSrc => false,
        regDst => false
    );

    constant executeControlWordAllFalse : ExecuteControlWord_type := (
        ALUSrc => false,
        ALUOpIsAdd => false,
        lui => false
    );

    constant memoryControlWordAllFalse : MemoryControlWord_type := (
        MemOp => false,
        MemOpIsWrite => false
    );

    constant writeBackControlWordAllFalse : WriteBackControlWord_type := (
        regWrite => false,
        MemtoReg => false
    );

    -- To begin, this processor will support the following instructions:
    -- lw, sw, beq, add, sub, and, or, slt, j
    -- The nop, for now, will be and $0 $0 $0
    constant instructionNop : instruction_type := X"00000024";

    constant opcodeRType : opcode_type := 16#0#;
    constant opcodeAddiu : opcode_type := 16#9#;
    constant opcodeLw : opcode_type := 16#23#;
    constant opcodeSw : opcode_type := 16#2b#;
    constant opcodeBeq : opcode_type := 16#4#;
    constant opcodeJ : opcode_type := 16#2#;
    constant opcodeLui : opcode_type := 16#f#;

    constant aluFunctionAdd : aluFunction_type := 16#20#;
    constant aluFunctionAddUnsigned : aluFunction_type := 16#21#;
    constant aluFunctionSubtract : aluFunction_type := 16#22#;
    constant aluFunctionAnd : aluFunction_type := 16#24#;
    constant aluFunctionOr : aluFunction_type := 16#25#;
    constant aluFunctionSetLessThan : aluFunction_type := 16#2a#;
end package;
