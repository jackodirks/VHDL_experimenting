library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seven_segments_driver is
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
end seven_segments_driver;

architecture Behavioral of seven_segments_driver is
    component bits_to_seven_segement_translation
        Port (
            bit_input : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_out : out  STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;
    component simple_multishot_timer is
        generic ( match_val   : integer );
        port (
            clk_50Mhz   : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;
    type state_type is (first, second, third, fourth);
    signal state : state_type := first;
    signal simple_multishot_timer_done : STD_LOGIC;
    signal ss_curVal_out : STD_LOGIC_VECTOR(3 DOWNTO 0);

begin

    simple_multishot_timer_wait_time : simple_multishot_timer
    generic map (
        match_val => 50000000 / switch_freq
    )
    port map (
        clk_50MHZ => clk_50Mhz,
        rst => '0',
        done => simple_multishot_timer_done
    );

    translator : bits_to_seven_segement_translation
    port map (
        bit_input => ss_curVal_out,
        ss_out => seven_seg_kath
    );
    process (clk_50Mhz, ss_1, ss_2, ss_3, ss_4)
    begin
        if rising_edge(clk_50MHZ) then
            case state is
                when first =>
                    if simple_multishot_timer_done = '1' then
                        state <= second;
                    end if;
                    ss_curVal_out <= ss_1;
                    seven_seg_an <= "1110";
                when second =>
                    if simple_multishot_timer_done = '1' then
                        state <= third;
                    end if;
                    ss_curVal_out <= ss_2;
                    seven_seg_an <= "1101";
                when third =>
                    if simple_multishot_timer_done = '1' then
                        state <= fourth;
                    end if;
                    ss_curVal_out <= ss_3;
                    seven_seg_an <= "1011";
                when fourth =>
                    if simple_multishot_timer_done = '1' then
                        state <= first;
                    end if;
                    ss_curVal_out <= ss_4;
                    seven_seg_an <= "0111";
            end case;
        end if;
    end process;
end Behavioral;
