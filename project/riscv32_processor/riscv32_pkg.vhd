library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package riscv32_pkg is
    constant riscv32_address_width_log2b : natural := 5;
    constant riscv32_data_width_log2b : natural := 5;
    constant riscv32_instruction_width_log2b : natural := 5;
    constant riscv32_byte_width_log2b : natural := 3;

    constant riscv32_bytes_per_data_word : natural := 2**(riscv32_data_width_log2b - riscv32_byte_width_log2b);

    constant riscv32_byte_width : natural := 2**riscv32_byte_width_log2b;

    subtype riscv32_address_type is std_logic_vector(2**riscv32_address_width_log2b - 1 downto  0);
    subtype riscv32_data_type is std_logic_vector(2**riscv32_data_width_log2b -1 downto 0);
    subtype riscv32_instruction_type is std_logic_vector(2**riscv32_instruction_width_log2b - 1 downto 0);
    subtype riscv32_byte_type is std_logic_vector(2**riscv32_byte_width_log2b - 1 downto 0);
    subtype riscv32_opcode_type is natural range 0 to 127;
    subtype riscv32_funct7_type is natural range 0 to 63;
    subtype riscv32_funct3_type is natural range 0 to 7;
    subtype riscv32_registerFileAddress_type is natural range 0 to 31;
    subtype riscv32_shamt_type is natural range 0 to 31;

    type riscv32_data_array is array (natural range <>) of riscv32_data_type;
    type riscv32_instruction_array is array (natural range <>) of riscv32_instruction_type;
    type riscv32_byte_array is array (natural range <>) of riscv32_byte_type;
    type riscv32_load_store_size is (ls_word, ls_halfword, ls_byte);

    type riscv32_immdiate_type is (riscv32_i_immidiate, riscv32_u_immidiate, riscv32_b_immidiate, riscv32_s_immidiate);
    type riscv32_exec_type is (riscv32_exec_alu_rtype, riscv32_exec_alu_imm, riscv32_exec_shift_rtype, riscv32_exec_shift_immidiate, riscv32_exec_calcReturn, riscv32_exec_lui, riscv32_exec_auipc);
    type riscv32_alu_cmd is (cmd_alu_add, cmd_alu_slt, cmd_alu_sltu, cmd_alu_and, cmd_alu_or, cmd_alu_xor, cmd_alu_sub);
    type riscv32_shift_cmd is (cmd_shift_sll, cmd_shift_srl, cmd_shift_sra);
    type riscv32_branch_cmd is (cmd_branch_eq, cmd_branch_ne, cmd_branch_lt, cmd_branch_ltu, cmd_branch_ge, cmd_branch_geu);

    type riscv32_InstructionDecodeControlWord_type is record
        jump : boolean;
        PCSrc : boolean;
        immidiate_type : riscv32_immdiate_type;
    end record;

    type riscv32_ExecuteControlWord_type is record
        exec_directive : riscv32_exec_type;
        is_branch_op : boolean;
        alu_cmd : riscv32_alu_cmd;
        shift_cmd : riscv32_shift_cmd;
        branch_cmd : riscv32_branch_cmd;
        regWrite_override_on_branch : boolean;
        regWrite_override_on_rt_zero : boolean;
    end record;

    type riscv32_MemoryControlWord_type is record
        MemOp : boolean;
        MemOpIsWrite : boolean;
        cop0Write : boolean;
        memReadSignExtend : boolean;
        loadStoreSize : riscv32_load_store_size;
        wordLeft : boolean;
        wordRight : boolean;
    end record;

    type riscv32_WriteBackControlWord_type is record
        regWrite : boolean;
        MemtoReg : boolean;
    end record;

    constant riscv32_instructionDecodeControlWordAllFalse : riscv32_InstructionDecodeControlWord_type := (
        jump => false,
        PCSrc => false,
        immidiate_type => riscv32_i_immidiate
    );

    constant riscv32_executeControlWordAllFalse : riscv32_ExecuteControlWord_type := (
        exec_directive => riscv32_exec_alu_rtype,
        is_branch_op => false,
        alu_cmd => cmd_alu_add,
        shift_cmd => cmd_shift_sll,
        branch_cmd => cmd_branch_ne,
        regWrite_override_on_branch => false,
        regWrite_override_on_rt_zero => false
    );

    constant riscv32_memoryControlWordAllFalse : riscv32_MemoryControlWord_type := (
        MemOp => false,
        MemOpIsWrite => false,
        cop0Write => false,
        memReadSignExtend => false,
        loadStoreSize => ls_word,
        wordLeft => false,
        wordRight => false
    );

    constant riscv32_writeBackControlWordAllFalse : riscv32_WriteBackControlWord_type := (
        regWrite => false,
        MemtoReg => false
    );

    -- The nop is addi x0,x0,0
    constant riscv32_instructionNop : riscv32_instruction_type := X"00000013";

    constant riscv32_opcode_load : riscv32_opcode_type := 16#3#;
    constant riscv32_opcode_opimm : riscv32_opcode_type := 16#13#;
    constant riscv32_opcode_auipc : riscv32_opcode_type := 16#17#;
    constant riscv32_opcode_miscmem : riscv32_opcode_type := 16#1f#;
    constant riscv32_opcode_store : riscv32_opcode_type := 16#23#;
    constant riscv32_opcode_op : riscv32_opcode_type := 16#33#;
    constant riscv32_opcode_lui : riscv32_opcode_type := 16#37#;
    constant riscv32_opcode_branch : riscv32_opcode_type := 16#63#;
    constant riscv32_opcode_jalr : riscv32_opcode_type := 16#67#;
    constant riscv32_opcode_jal : riscv32_opcode_type := 16#6f#;
    constant riscv32_opcode_system : riscv32_opcode_type := 16#73#;

    constant riscv32_funct3_add_sub : riscv32_funct3_type := 16#0#;
    constant riscv32_funct3_sll : riscv32_funct3_type := 16#1#;
    constant riscv32_funct3_slt : riscv32_funct3_type := 16#2#;
    constant riscv32_funct3_sltu : riscv32_funct3_type := 16#3#;
    constant riscv32_funct3_xor : riscv32_funct3_type := 16#4#;
    constant riscv32_funct3_srl_sra : riscv32_funct3_type := 16#5#;
    constant riscv32_funct3_or : riscv32_funct3_type := 16#6#;
    constant riscv32_funct3_and : riscv32_funct3_type := 16#7#;

    constant riscv32_funct7_srli : riscv32_funct7_type := 16#0#;
    constant riscv32_funct7_srai : riscv32_funct7_type := 16#20#;

    constant riscv32_funct7_add : riscv32_funct7_type := 16#0#;
    constant riscv32_funct7_sub : riscv32_funct7_type := 16#20#;

    constant riscv32_funct3_beq : riscv32_funct3_type := 16#0#;
    constant riscv32_funct3_bne : riscv32_funct3_type := 16#1#;
    constant riscv32_funct3_blt : riscv32_funct3_type := 16#4#;
    constant riscv32_funct3_bge : riscv32_funct3_type := 16#5#;
    constant riscv32_funct3_bltu : riscv32_funct3_type := 16#6#;
    constant riscv32_funct3_bgeu : riscv32_funct3_type := 16#7#;

    constant riscv32_funct3_lb : riscv32_funct3_type := 16#0#;
    constant riscv32_funct3_lh : riscv32_funct3_type := 16#1#;
    constant riscv32_funct3_lw : riscv32_funct3_type := 16#2#;
    constant riscv32_funct3_lbu : riscv32_funct3_type := 16#4#;
    constant riscv32_funct3_lhu : riscv32_funct3_type := 16#5#;

    constant riscv32_funct3_sb : riscv32_funct3_type := 16#0#;
    constant riscv32_funct3_sh : riscv32_funct3_type := 16#1#;
    constant riscv32_funct3_sw : riscv32_funct3_type := 16#2#;

    constant riscv32_funct3_fence : riscv32_funct3_type := 16#0#;

    constant riscv32_funct7_ecall : riscv32_funct7_type := 16#0#;
    constant riscv32_funct7_ebreak : riscv32_funct7_type := 16#1#;

end package;
