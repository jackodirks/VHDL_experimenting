library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_branchHelper is
    port (
        executeControlWord : in mips32_ExecuteControlWord_type;

        injectBubble : out boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_branchHelper is
begin
    injectBubble <= executeControlWord.is_branch_op;
end architecture;
