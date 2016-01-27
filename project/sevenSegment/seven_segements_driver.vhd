library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seven_segments_driver is
    Port (
            clk_50Mhz           : in  STD_LOGIC;
            rst                 : in  STD_LOGIC;
            ss_1                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_2                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_3                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_4                : in  STD_LOGIC_VECTOR (3 downto 0);
            seven_seg_kath      : in  STD_LOGIC_VECTOR (7 downto 0);
            seven_seg_an        : in  STD_LOGIC_VECTOR (3 downto 0)
       );
end seven_segments_driver;

architecture Behavioral of seven_segments_driver is
    component bits_to_seven_segement_translation
        Port (
                bit_input : in  STD_LOGIC_VECTOR (3 downto 0);
                ss_out : out  STD_LOGIC_VECTOR (7 downto 0)
           );
    end component;
    type state_type is (first, second, third, fourth);
    signal state : state_type;
begin


end Behavioral;

