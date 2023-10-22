library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

library src;
use src.bus_pkg.all;
use src.mips32_pkg.all;

entity mips32_bit_manipulator_tb is
    generic (
        runner_cfg : string);
end entity;

architecture tb of mips32_bit_manipulator_tb is
    signal rs : mips32_data_type := (others => '0');
    signal rt : mips32_data_type := (others => '0');
    signal msb : natural range 0 to 31 := 0;
    signal lsb : natural range 0 to 31 := 0;
    signal cmd : mips32_bit_manipulator_cmd := cmd_bit_manip_ext;

    signal output : mips32_data_type;

begin

    main : process
        variable expectedOutput : std_logic_vector(output'range);
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("Extracts msb") then
                rs <= X"f0000000";
                msb <= 0;
                lsb <= 31;
                cmd <= cmd_bit_manip_ext;
                wait for 1 fs;
                check_equal(output, std_logic_vector'(X"00000001"));
            elsif run("Extracts 4 msb") then
                rs <= X"abcdef12";
                msb <= 3;
                lsb <= 28;
                cmd <= cmd_bit_manip_ext;
                wait for 1 fs;
                check_equal(output, std_logic_vector'(X"0000000a"));
            elsif run("Extracts bits 28 downto 24") then
                rs <= X"abcdef12";
                msb <= 4;
                lsb <= 24;
                cmd <= cmd_bit_manip_ext;
                wait for 1 fs;
                expectedOutput := (others => '0');
                expectedOutput(4 downto 0) := rs(28 downto 24);
                check_equal(output, expectedOutput);
            elsif run("Extracts lsb of rs into msb of rt") then
                rs <= X"ffffffff";
                rt <= X"00000000";
                msb <= 31;
                lsb <= 31;
                cmd <= cmd_bit_manip_ins;
                wait for 1 fs;
                check_equal(output, std_logic_vector'(X"80000000"));
            elsif run("Extracts 5 lsb of rs into 5 msb of rt") then
                rs <= X"ffffffff";
                rt <= X"00000000";
                msb <= 31;
                lsb <= 27;
                cmd <= cmd_bit_manip_ins;
                wait for 1 fs;
                check_equal(output, std_logic_vector'(X"f8000000"));
            elsif run("Extracts 7 lsb of rs into 27 downto 21 of rt") then
                rs <= X"ffffffff";
                rt <= X"00000000";
                msb <= 27;
                lsb <= 21;
                cmd <= cmd_bit_manip_ins;
                wait for 1 fs;
                expectedOutput := rt;
                expectedOutput(27 downto 21) := rs(6 downto 0);
                check_equal(output, expectedOutput);
            elsif run("Extract overrun check") then
                rs <= X"f0000000";
                msb <= 31;
                lsb <= 31;
                cmd <= cmd_bit_manip_ext;
                wait for 1 fs;
            elsif run("Insert overrun check") then
                rs <= X"f0000000";
                msb <= 0;
                lsb <= 31;
                cmd <= cmd_bit_manip_ins;
                wait for 1 fs;
            end if;
        end loop;
        test_runner_cleanup(runner);
        wait;
    end process;

    test_runner_watchdog(runner,  10 ns);

    bit_manipulator : entity src.mips32_bit_manipulator
    port map (
        rs => rs,
        rt => rt,
        msb => msb,
        lsb => lsb,
        cmd => cmd,
        output => output

    );
end architecture;
