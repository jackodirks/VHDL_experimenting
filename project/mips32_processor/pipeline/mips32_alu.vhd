library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_alu is
    port (
        inputA : in mips32_data_type;
        inputB : in mips32_data_type;
        cmd : in mips32_alu_cmd;
        shamt : in mips32_shamt_type;

        output : out mips32_data_type;
        overflow : out boolean
    );
end entity;

architecture behaviourial of mips32_alu is
begin
    process(inputA, inputB, cmd, shamt)
        variable additionResult : mips32_data_type;
        variable additionOverflow : boolean;
        variable subtractionResult : mips32_data_type;
        variable subtractionOverflow : boolean;
        variable andResult : mips32_data_type;
        variable orResult : mips32_data_type;
        variable norResult : mips32_data_type;
        variable setLessThanResult : std_logic;
        variable setLessThanUnsignedResult : std_logic;
        variable sllResult : mips32_data_type;
        variable srlResult : mips32_data_type;
        variable sraResult : mips32_data_type;
        variable luiResult : mips32_data_type;
    begin
        additionResult := std_logic_vector(signed(inputA) + signed(inputB));
        additionOverflow := inputA(inputA'high) = inputB(inputB'high) and inputA(inputA'high) /= additionResult(additionResult'high);
        subtractionResult := std_logic_vector(signed(inputA) - signed(inputB));
        subtractionOverflow := inputA(inputA'high) /= inputB(inputB'high) and inputB(inputB'high) = subtractionResult(subtractionResult'high);
        andResult := inputA and inputB;
        orResult := inputA or inputB;
        norResult := inputA nor inputB;
        sllResult := std_logic_vector(shift_left(unsigned(inputB), shamt));
        srlResult := std_logic_vector(shift_right(unsigned(inputB), shamt));
        sraResult := std_logic_vector(shift_right(signed(inputB), shamt));
        luiResult := std_logic_vector(shift_left(unsigned(inputB), 16));
        if signed(inputA) < signed(inputB) then
            setLessThanResult := '1';
        else
            setLessThanResult := '0';
        end if;

        if unsigned(inputA) < unsigned(inputB) then
            setLessThanUnsignedResult := '1';
        else
            setLessThanUnsignedResult := '0';
        end if;

        if cmd = cmd_add then
            overflow <= additionOverflow;
        elsif cmd = cmd_sub then
            overflow <= subtractionOverflow;
        else
            overflow <= false;
        end if;

        case cmd is
            when cmd_sll =>
                output <= sllResult;
            when cmd_srl =>
                output <= srlResult;
            when cmd_sra =>
                output <= sraResult;
            when cmd_add =>
                output <= additionResult;
            when cmd_sub =>
                output <= subtractionResult;
            when cmd_and =>
                output <= andResult;
            when cmd_or =>
                output <= orResult;
            when cmd_nor =>
                output <= norResult;
            when cmd_slt =>
                output(output'high downto 1) <= (others => '0');
                output(0) <= setLessThanResult;
            when cmd_sltu =>
                output(output'high downto 1) <= (others => '0');
                output(0) <= setLessThanUnsignedResult;
            when cmd_lui =>
                output <= luiResult;
            when others =>
                output <= inputA;
        end case;
    end process;

end architecture;
