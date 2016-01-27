library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity tb_main is
    end tb_main;

architecture tb of tb_main is
    component main_file is
    Port (
             slide_switch : in  STD_LOGIC_VECTOR (7 downto 0);
             led : out  STD_LOGIC_VECTOR (7 downto 0)
         );
    end component;

signal led : STD_LOGIC_VECTOR (7 DOWNTO 0);
signal slide_switch : STD_LOGIC_VECTOR(7 DOWNTO 0);
begin
    main : main_file
    port map (
                 slide_switch => slide_switch,
                 led => led
             );
    process
    begin
        for I in 0 to 255 loop
            slide_switch <= std_logic_vector(to_unsigned(I, slide_switch'length));
            wait for 5 ns;
            assert led = std_logic_vector(to_unsigned(I, slide_switch'length)) report "The LED output is unexpected" severity ERROR;
        end loop;
        assert false report "Test done" severity note;
        wait;
    end process;
end tb;
