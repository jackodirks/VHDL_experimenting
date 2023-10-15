library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.mips32_pkg.all;

entity mips32_shifter_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_shifter_tb is
    signal input : mips32_data_type := (others => '0');
    signal cmd : mips32_shift_cmd := cmd_shift_sll;
    signal shamt : mips32_shamt_type := 0;
    signal output : mips32_data_type;
begin
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("sll works") then
                input <= X"0000000f";
                shamt <= 4;
                cmd <= cmd_shift_sll;
                wait for 1 ns;
                check(X"000000f0" = output);
            elsif run("srl works") then
                input <= X"000000f0";
                shamt <= 4;
                cmd <= cmd_shift_srl;
                wait for 1 ns;
                check(X"0000000f" = output);
            elsif run("Sra works") then
                input <= X"F0F0F0F0";
                shamt <= 4;
                cmd <= cmd_shift_sra;
                wait for 1 ns;
                check(X"FF0F0F0F" = output);
            end if;
        end loop;
        test_runner_cleanup(runner);
        wait;
    end process;

    shifter : entity src.mips32_shifter
    port map (
        input => input,
        cmd => cmd,
        shamt => shamt,
        output => output
    );
end architecture;
