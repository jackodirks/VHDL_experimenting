library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_pipeline_branchHelper_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_pipeline_branchHelper_tb is
    signal executeControlWord : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;
    signal aluFunction : mips32_aluFunction_type := mips32_aluFunctionSll;
    signal injectBubble : boolean;

    signal opcode : mips32_opcode_type := mips32_opcodeRType;
begin
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("On bne, bubble is true") then
                opcode <= mips32_opcodeBne;
                wait for 10 ns;
                check(injectBubble);
            elsif run("On j, bubble is false") then
                opcode <= mips32_opcodeJ;
                wait for 10 ns;
                check(not injectBubble);
            elsif run("On beq, bubble is true") then
                opcode <= mips32_opcodeBeq;
                wait for 10 ns;
                check(injectBubble);
            elsif run("On jr, bubble is true") then
                opcode <= mips32_opcodeRType;
                aluFunction <= mips32_aluFunctionJumpReg;
                wait for 10 ns;
                check(injectBubble);
            elsif run("If aluFunctionJumpReg, but not r-type, bubble is false") then
                opcode <= mips32_opcodeAddiu;
                aluFunction <= mips32_aluFunctionJumpReg;
                wait for 10 ns;
                check(not injectBubble);
            end if;
        end loop;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner, 100 ns);

    branchHelper : entity src.mips32_pipeline_branchHelper
    port map (
        executeControlWord => executeControlWord,
        aluFunction => aluFunction,
        injectBubble => injectBubble
    );

    controlDecode : entity src.mips32_control
    port map (
        opcode => opcode,
        mf => 0,
        executeControlWord => executeControlWord
    );
end architecture;
