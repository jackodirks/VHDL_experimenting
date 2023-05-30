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
        funct : in mips32_aluFunction_type;

        output : out mips32_data_type;
        overflow : out boolean
    );
end entity;

architecture behaviourial of mips32_alu is
begin
    process(inputA, inputB, funct)
        variable additionResult : mips32_data_type;
        variable additionOverflow : boolean;
        variable subtractionResult : mips32_data_type;
        variable subtractionOverflow : boolean;
        variable andResult : mips32_data_type;
        variable orResult : mips32_data_type;
        variable setLessThanResult : std_logic;
    begin
        additionResult := std_logic_vector(signed(inputA) + signed(inputB));
        additionOverflow := inputA(inputA'high) = inputB(inputB'high) and inputA(inputA'high) /= additionResult(additionResult'high);
        subtractionResult := std_logic_vector(signed(inputA) - signed(inputB));
        subtractionOverflow := inputA(inputA'high) /= inputB(inputB'high) and inputB(inputB'high) = subtractionResult(subtractionResult'high);
        andResult := inputA and inputB;
        orResult := inputA or inputB;
        if signed(inputA) < signed(inputB) then
            setLessThanResult := '1';
        else
            setLessThanResult := '0';
        end if;

        case funct is
            when mips32_aluFunctionAdd =>
                output <= additionResult;
                overflow <= additionOverflow;
            when mips32_aluFunctionAddUnsigned =>
                output <= additionResult;
                overflow <= false;
            when mips32_aluFunctionSubtract =>
                output <= subtractionResult;
                overflow <= subtractionOverflow;
            when mips32_aluFunctionAnd =>
                output <= andResult;
                overflow <= false;
            when mips32_aluFunctionOr =>
                output <= orResult;
                overflow <= false;
            when mips32_aluFunctionSetLessThan =>
                output(output'high downto 1) <= (others => '0');
                output(0) <= setLessThanResult;
                overflow <= false;
            when others =>
                output <= inputA;
                overflow <= false;
        end case;
    end process;

end architecture;
