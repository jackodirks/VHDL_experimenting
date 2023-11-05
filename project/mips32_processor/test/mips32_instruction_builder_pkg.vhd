library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src;
use src.mips32_pkg.all;

package mips32_instruction_builder_pkg is

    pure function construct_rtype_instruction (
        opcode : mips32_opcode_type := mips32_opcode_special;
        rs : mips32_registerFileAddress_type := 0;
        rt : mips32_registerFileAddress_type := 0;
        rd : mips32_registerFileAddress_type := 0;
        shamt : mips32_shamt_type := 0;
        funct : mips32_function_type := mips32_function_Sll
    ) return mips32_instruction_type;

    pure function construct_itype_instruction (
        opcode : mips32_opcode_type := mips32_opcode_special;
        rs : mips32_registerFileAddress_type := 0;
        rt : mips32_registerFileAddress_type := 0;
        imm : std_logic_vector(15 downto 0) := (others => '0')
    ) return mips32_instruction_type;

    pure function construct_jtype_instruction (
        opcode : mips32_opcode_type := mips32_opcode_special;
        address : std_logic_vector(25 downto 0) := (others => '0')
    ) return mips32_instruction_type;

end package;

package body mips32_instruction_builder_pkg is

    pure function construct_rtype_instruction (
        opcode : mips32_opcode_type := mips32_opcode_special;
        rs : mips32_registerFileAddress_type := 0;
        rt : mips32_registerFileAddress_type := 0;
        rd : mips32_registerFileAddress_type := 0;
        shamt : mips32_shamt_type := 0;
        funct : mips32_function_type := mips32_function_Sll
    ) return mips32_instruction_type is
        variable instruction : mips32_instruction_type;
    begin
        instruction(31 downto 26) := std_logic_vector(to_unsigned(opcode, 6));
        instruction(25 downto 21) := std_logic_vector(to_unsigned(rs, 5));
        instruction(20 downto 16) := std_logic_vector(to_unsigned(rt, 5));
        instruction(15 downto 11) := std_logic_vector(to_unsigned(rd, 5));
        instruction(10 downto 6) := std_logic_vector(to_unsigned(shamt, 5));
        instruction(5 downto 0) := std_logic_vector(to_unsigned(funct, 6));
        return instruction;
    end function;

    pure function construct_itype_instruction (
        opcode : mips32_opcode_type := mips32_opcode_special;
        rs : mips32_registerFileAddress_type := 0;
        rt : mips32_registerFileAddress_type := 0;
        imm : std_logic_vector(15 downto 0) := (others => '0')
    ) return mips32_instruction_type is
        variable instruction : mips32_instruction_type;
    begin
        instruction(31 downto 26) := std_logic_vector(to_unsigned(opcode, 6));
        instruction(25 downto 21) := std_logic_vector(to_unsigned(rs, 5));
        instruction(20 downto 16) := std_logic_vector(to_unsigned(rt, 5));
        instruction(15 downto 0) := imm;
        return instruction;
    end function;

    pure function construct_jtype_instruction (
        opcode : mips32_opcode_type := mips32_opcode_special;
        address : std_logic_vector(25 downto 0) := (others => '0')
    ) return mips32_instruction_type is
        variable instruction : mips32_instruction_type;
    begin
        instruction(31 downto 26) := std_logic_vector(to_unsigned(opcode, 6));
        instruction(25 downto 0) := address;
        return instruction;
    end function;


end package body;
