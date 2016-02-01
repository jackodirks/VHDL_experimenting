library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity tb_main is
    end tb_main;

architecture tb of tb_main is
    -- Component declaration --
    component counter is
        generic ( match_val   : integer );
        port (
            clk_50Mhz   : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;

    component seven_segments_driver is
        generic ( switch_freq : integer );
        Port (
            clk_50Mhz           : in  STD_LOGIC;
            ss_1                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_2                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_3                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_4                : in  STD_LOGIC_VECTOR (3 downto 0);
            seven_seg_kath      : out  STD_LOGIC_VECTOR (7 downto 0);
            seven_seg_an        : out  STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;
    -- Signal declaration --
    signal clk              : STD_LOGIC := '1';
    signal led              : STD_LOGIC_VECTOR (7 DOWNTO 0);
    signal slide_switch     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal counter_rst      : STD_LOGIC := '1';
    signal counter_done     : STD_LOGIC;
    signal counter_cur_val  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    signal ss_kathode       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal ss_anode         : STD_LOGIC_VECTOR(3 DOWNTO 0);
begin
    counter_50 : counter
    generic map (
        match_val => 50
    )
    port map (
        clk_50MHZ => clk,
        rst => counter_rst,
        done => counter_done
    );

    ss_driver : seven_segments_driver
    generic map (
        switch_freq => 2000000
    )
    port map (
        clk_50Mhz => clk,
        ss_1 => "0001",
        ss_2 => "0010",
        ss_3 => "0100",
        ss_4 => "1000",
        seven_seg_kath => ss_kathode,
        seven_seg_an => ss_anode
    );

    clk <= not clk after 10 ns;
    process
    begin
        counter_rst <= '0';
        wait until counter_done = '1';
        counter_rst <= '1';
        assert false report "counter test done" severity note;
        wait;
    end process;
end tb;
