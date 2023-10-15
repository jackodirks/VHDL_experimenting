library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_alu_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_alu_tb is
    constant clk_period : time := 20 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal inputA : mips32_data_type;
    signal inputB : mips32_data_type;
    signal cmd : mips32_alu_cmd;
    signal output : mips32_data_type;
    signal overflow : boolean;

begin

    clk <= not clk after (clk_period/2);

    main : process
        variable expectedOutput : std_logic_vector(output'range);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Addition works") then
                inputA <= std_logic_vector(to_signed(-4, inputA'length));
                inputB <= std_logic_vector(to_signed(-6, inputB'length));
                cmd <= cmd_alu_add;
                expectedOutput := std_logic_vector(to_signed(-10, expectedOutput'length));
                wait for clk_period;
                check_equal(output, expectedOutput);
            elsif run("Addition can overflow") then
                inputA <= std_logic_vector(to_signed(-2147483648, inputA'length));
                inputB <= std_logic_vector(to_signed(-1, inputB'length));
                cmd <= cmd_alu_add;
                expectedOutput := std_logic_vector(to_signed(2147483647, expectedOutput'length));
                wait for clk_period;
                check_equal(output, expectedOutput);
                check(overflow);
            elsif run("Subtraction works") then
                inputA <= std_logic_vector(to_signed(-2147483648, inputA'length));
                inputB <= std_logic_vector(to_signed(1, inputB'length));
                cmd <= cmd_alu_sub;
                expectedOutput := std_logic_vector(to_signed(2147483647, expectedOutput'length));
                wait for clk_period;
                check_equal(output, expectedOutput);
            elsif run("Subtraction overflows") then
                inputA <= std_logic_vector(to_signed(-2147483648, inputA'length));
                inputB <= std_logic_vector(to_signed(1, inputB'length));
                cmd <= cmd_alu_sub;
                expectedOutput := std_logic_vector(to_signed(2147483647, expectedOutput'length));
                wait for clk_period;
                check(overflow);
            elsif run("And function works") then
                inputA <= X"F0F0FFFF";
                inputB <= X"0A0ABCDE";
                cmd <= cmd_alu_and;
                expectedOutput := X"0000BCDE";
                wait for clk_period;
                check_equal(output, expectedOutput);
            elsif run("Or function works") then
                inputA <= X"A0B0C0D0";
                inputB <= X"0E0F0102";
                cmd <= cmd_alu_or;
                expectedOutput := X"AEBFC1D2";
                wait for clk_period;
                check_equal(output, expectedOutput);
            elsif run("Nor function works") then
                inputA <= X"F0F0F0F0";
                inputB <= X"0F0F0F00";
                cmd <= cmd_alu_nor;
                expectedOutput := X"0000000F";
                wait for clk_period;
                check_equal(output, expectedOutput);
            elsif run("set less than function works") then
                inputA <= std_logic_vector(to_signed(1, inputA'length));
                inputB <= std_logic_vector(to_signed(-1, inputA'length));
                cmd <= cmd_alu_slt;
                expectedOutput := (others => '0');
                wait for clk_period;
                check_equal(output, expectedOutput);
                inputA <= std_logic_vector(to_signed(-1, inputA'length));
                inputB <= std_logic_vector(to_signed(1, inputA'length));
                cmd <= cmd_alu_slt;
                expectedOutput := (others => '0');
                expectedOutput(0) := '1';
                wait for clk_period;
                check_equal(output, expectedOutput);
            elsif run("set less than unsigned function works") then
                inputA <= std_logic_vector(to_signed(2, inputA'length));
                inputB <= std_logic_vector(to_signed(-1, inputA'length));
                cmd <= cmd_alu_sltu;
                expectedOutput := (others => '0');
                expectedOutput(0) := '1';
                wait for clk_period;
                check_equal(output, expectedOutput);
                inputA <= std_logic_vector(to_signed(-1, inputA'length));
                inputB <= std_logic_vector(to_signed(1, inputA'length));
                expectedOutput := (others => '0');
                wait for clk_period;
                check_equal(output, expectedOutput);
            end if;
        end loop;
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  1 us);

    alu : entity src.mips32_alu
    port map (
        inputA,
        inputB,
        cmd,
        output,
        overflow
    );
end architecture;
