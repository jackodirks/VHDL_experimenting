library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package mips32_pkg is
    constant mips32_address_width_log2b : natural := 5;
    constant mips32_data_width_log2b : natural := 5;
    constant mips32_instruction_width_log2b : natural := 5;
    constant mips32_byte_width_log2b : natural := 3;

    constant mips32_bytes_per_data_word : natural := 2**(mips32_data_width_log2b - mips32_byte_width_log2b);

    constant mips32_byte_width : natural := 2**mips32_byte_width_log2b;

    subtype mips32_address_type is std_logic_vector(2**mips32_address_width_log2b - 1 downto  0);
    subtype mips32_data_type is std_logic_vector(2**mips32_data_width_log2b -1 downto 0);
    subtype mips32_instruction_type is std_logic_vector(2**mips32_instruction_width_log2b - 1 downto 0);
    subtype mips32_byte_type is std_logic_vector(2**mips32_byte_width_log2b - 1 downto 0);
    subtype mips32_opcode_type is natural range 0 to 63;
    subtype mips32_registerFileAddress_type is natural range 0 to 31;
    subtype mips32_function_type is natural range 0 to 63;
    subtype mips32_shamt_type is natural range 0 to 31;
    subtype mips32_mf_type is natural range 0 to 31;
    subtype mips32_regimm_type is natural range 0 to 31;
    subtype mips32_byte_mask_type is std_logic_vector(mips32_bytes_per_data_word - 1 downto 0);

    type mips32_data_array is array (natural range <>) of mips32_data_type;
    type mips32_instruction_array is array (natural range <>) of mips32_instruction_type;
    type mips32_byte_array is array (natural range <>) of mips32_byte_type;
    type mips32_load_store_size is (ls_word, ls_halfword, ls_byte);

    type mips32_exec_type is (mips32_exec_alu, mips32_exec_shift, mips32_exec_calcReturn);
    type mips32_alu_cmd is (cmd_alu_add, cmd_alu_sub, cmd_alu_and, cmd_alu_or, cmd_alu_nor, cmd_alu_lui, cmd_alu_sltu, cmd_alu_slt);
    type mips32_shift_cmd is (cmd_shift_sll, cmd_shift_srl, cmd_shift_sra);
    type mips32_branch_cmd is (cmd_branch_ne, cmd_branch_eq, cmd_branch_bgez, cmd_branch_jumpreg, cmd_branch_blez, cmd_branch_bgtz,
                               cmd_branch_bltz);

    type mips32_InstructionDecodeControlWord_type is record
        jump : boolean;
        PCSrc : boolean;
        regDstIsRd : boolean;
        regDstIsRetReg : boolean;
    end record;

    type mips32_ExecuteControlWord_type is record
        exec_directive : mips32_exec_type;
        is_branch_op : boolean;
        alu_cmd : mips32_alu_cmd;
        shift_cmd : mips32_shift_cmd;
        branch_cmd : mips32_branch_cmd;
        use_immidiate : boolean;
    end record;

    type mips32_MemoryControlWord_type is record
        MemOp : boolean;
        MemOpIsWrite : boolean;
        cop0Write : boolean;
        memReadSignExtend : boolean;
        loadStoreSize : mips32_load_store_size;
        wordLeft : boolean;
        wordRight : boolean;
    end record;

    type mips32_WriteBackControlWord_type is record
        regWrite : boolean;
        MemtoReg : boolean;
        write_on_branch : boolean;
    end record;

    constant mips32_instructionDecodeControlWordAllFalse : mips32_InstructionDecodeControlWord_type := (
        jump => false,
        PCSrc => false,
        regDstIsRd => false,
        regDstIsRetReg => false
    );

    constant mips32_executeControlWordAllFalse : mips32_ExecuteControlWord_type := (
        exec_directive => mips32_exec_alu,
        is_branch_op => false,
        alu_cmd => cmd_alu_add,
        shift_cmd => cmd_shift_sll,
        branch_cmd => cmd_branch_ne,
        use_immidiate => false
    );

    constant mips32_memoryControlWordAllFalse : mips32_MemoryControlWord_type := (
        MemOp => false,
        MemOpIsWrite => false,
        cop0Write => false,
        memReadSignExtend => false,
        loadStoreSize => ls_word,
        wordLeft => false,
        wordRight => false
    );

    constant mips32_writeBackControlWordAllFalse : mips32_WriteBackControlWord_type := (
        regWrite => false,
        MemtoReg => false,
        write_on_branch => false
    );

    -- To begin, this processor will support the following instructions:
    -- lw, sw, beq, add, sub, and, or, slt, j
    -- The nop is sll $0,$0,$0
    constant mips32_instructionNop : mips32_instruction_type := X"00000000";

    constant mips32_opcode_Special : mips32_opcode_type := 16#0#;
    constant mips32_opcode_regimm : mips32_opcode_type := 16#1#;
    constant mips32_opcode_J : mips32_opcode_type := 16#2#;
    constant mips32_opcode_Jal : mips32_opcode_type := 16#3#;
    constant mips32_opcode_Beq : mips32_opcode_type := 16#4#;
    constant mips32_opcode_Bne : mips32_opcode_type := 16#5#;
    constant mips32_opcode_blez : mips32_opcode_type := 16#6#;
    constant mips32_opcode_bgtz : mips32_opcode_type := 16#7#;
    constant mips32_opcode_Addi : mips32_opcode_type := 16#8#;
    constant mips32_opcode_Addiu : mips32_opcode_type := 16#9#;
    constant mips32_opcode_Andi : mips32_opcode_type := 16#c#;
    constant mips32_opcode_Lui : mips32_opcode_type := 16#f#;
    constant mips32_opcode_COP0 : mips32_opcode_type := 16#10#;
    constant mips32_opcode_Beql : mips32_opcode_type := 16#14#;
    constant mips32_opcode_blezl : mips32_opcode_type := 16#16#;
    constant mips32_opcode_bgtzl : mips32_opcode_type := 16#17#;
    constant mips32_opcode_Lb : mips32_opcode_type := 16#20#;
    constant mips32_opcode_Lh : mips32_opcode_type := 16#21#;
    constant mips32_opcode_Lwl : mips32_opcode_type := 16#22#;
    constant mips32_opcode_Lw : mips32_opcode_type := 16#23#;
    constant mips32_opcode_Lbu : mips32_opcode_type := 16#24#;
    constant mips32_opcode_Lhu : mips32_opcode_type := 16#25#;
    constant mips32_opcode_Lwr : mips32_opcode_type := 16#26#;
    constant mips32_opcode_Sb : mips32_opcode_type := 16#28#;
    constant mips32_opcode_Sh : mips32_opcode_type := 16#29#;
    constant mips32_opcode_Swl : mips32_opcode_type := 16#2a#;
    constant mips32_opcode_Sw : mips32_opcode_type := 16#2b#;
    constant mips32_opcode_Swr : mips32_opcode_type := 16#2e#;

    constant mips32_function_Sll : mips32_function_type := 16#00#;
    constant mips32_function_Srl : mips32_function_type := 16#02#;
    constant mips32_function_Sra : mips32_function_type := 16#03#;
    constant mips32_function_JumpReg : mips32_function_type := 16#08#;
    constant mips32_function_Add : mips32_function_type := 16#20#;
    constant mips32_function_AddUnsigned : mips32_function_type := 16#21#;
    constant mips32_function_Subtract : mips32_function_type := 16#22#;
    constant mips32_function_SubtractUnsigned : mips32_function_type := 16#23#;
    constant mips32_function_And : mips32_function_type := 16#24#;
    constant mips32_function_Or : mips32_function_type := 16#25#;
    constant mips32_function_Nor : mips32_function_type := 16#27#;
    constant mips32_function_SetLessThan : mips32_function_type := 16#2a#;
    constant mips32_function_SetLessThanUnsigned : mips32_function_type := 16#2b#;

    constant mips32_mf_mfc0 : mips32_mf_type := 16#0#;
    constant mips32_mf_mtc0 : mips32_mf_type := 16#4#;

    constant mips32_regimm_bltz : mips32_regimm_type := 16#0#;
    constant mips32_regimm_bgez : mips32_regimm_type := 16#1#;
    constant mips32_regimm_bgezl : mips32_regimm_type := 16#3#;
    constant mips32_regimm_bgezal : mips32_regimm_type := 16#11#;
    constant mips32_regimm_bgezall : mips32_regimm_type := 16#13#;
end package;
