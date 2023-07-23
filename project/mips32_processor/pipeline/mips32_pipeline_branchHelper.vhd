library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_branchHelper is
    port (
        executeControlWord : in mips32_ExecuteControlWord_type;
        aluFunction : in mips32_aluFunction_type;

        injectBubble : out boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_branchHelper is
    signal jrBubble : boolean;
    signal branchBubble : boolean;
begin
    branchBubble <= executeControlWord.branchNe or executeControlWord.branchEq;
    jrBubble <= aluFunction = mips32_aluFunctionJumpReg and executeControlWord.isRtype;
    injectBubble <= branchBubble or jrBubble;
end architecture;
