library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity main_file is
    Port (
             --rst : in STD_LOGIC;
             --JA_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
             --JB_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
             --JC_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
             --JD_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
             slide_switch : in  STD_LOGIC_VECTOR (7 downto 0);
             --push_button : in  STD_LOGIC_VECTOR (3 downto 0);
             led : out  STD_LOGIC_VECTOR (7 downto 0);
             seven_seg_kath : out  STD_LOGIC_VECTOR (7 downto 0);
             seven_seg_an : out  STD_LOGIC_VECTOR (3 downto 0);
             clk : in  STD_LOGIC
         );
end main_file;

architecture Behavioral of main_file is
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

begin

    ss_driver : seven_segments_driver
    generic map (
        switch_freq => 200
    )
    port map (
        clk_50Mhz => clk,
        ss_1 => "0001",
        ss_2 => "0010",
        ss_3 => "0100",
        ss_4 => "1000",
        seven_seg_kath => seven_seg_kath,
        seven_seg_an => seven_seg_an
    );
    led <= slide_switch;

end Behavioral;

