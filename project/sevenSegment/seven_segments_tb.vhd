library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;

entity seven_segments_tb is
    generic (
        clock_period : time
    );
    port (
        clk : in STD_LOGIC;
        done : out boolean;
        success : out boolean
    );
end seven_segments_tb;

architecture Behavioral of seven_segments_tb is

    function eightBitsIncorrect(exp, got: STD_LOGIC_VECTOR(7 DOWNTO 0)) return boolean is
    begin
        if exp = got then
            return false;
        else
            report "Seven segments misbehaves: data output error. Expected " & hstr(exp) & " got " & hstr(got) severity error;
            return true;
        end if;
    end eightBitsIncorrect;

    function fourBitsIncorrect(exp, got: STD_LOGIC_VECTOR(3 DOWNTO 0)) return boolean is
    begin
        if exp = got then
            return false;
        else
            report "Seven segments misbehaves: display select error. Expected " & hstr(exp) & " got " & hstr(got);
            return true;
        end if;
    end fourBitsIncorrect;

    component seven_segments_driver is
        generic (
            ticks_per_hold         : natural
        );
        Port (
            clk                 : in  STD_LOGIC;
            ss_1                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_2                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_3                : in  STD_LOGIC_VECTOR (3 downto 0);
            ss_4                : in  STD_LOGIC_VECTOR (3 downto 0);
            seven_seg_kath      : out  STD_LOGIC_VECTOR (7 downto 0);
            seven_seg_an        : out  STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    -- Signals
    signal ss_kathode                       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal ss_anode                         : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal ss_1                             : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal ss_2                             : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal ss_3                             : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal ss_4                             : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal test_done                        : boolean := false;
    -- Constants
    constant ticks_per_hold                 : natural := 2;
begin
    ss_driver : seven_segments_driver
    generic map (
        ticks_per_hold => ticks_per_hold
    )
    port map (
        clk => clk,
        ss_1 => ss_1,
        ss_2 => ss_2,
        ss_3 => ss_3,
        ss_4 => ss_4,
        seven_seg_kath => ss_kathode,
        seven_seg_an => ss_anode
    );

    done <= test_done;

    test_process : process
        variable fail : boolean := false;
    begin
        ss_1 <= "0000";
        ss_2 <= "0001";
        ss_3 <= "0010";
        ss_4 <= "0011";
        -- Wait two more rising edges, because the driver needs two ticks to get started
        -- Well the multishot timer does not report done on t=0, which is correct but a bit counterintuitive.
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        -- Check if the correct display is chosen
        -- Check if the output is correct
        fail := fail or eightBitsIncorrect("11000000", ss_kathode);
        fail := fail or fourBitsIncorrect("1110", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("11111001", ss_kathode);
        fail := fail or fourBitsIncorrect("1101", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10100100", ss_kathode);
        fail := fail or fourBitsIncorrect("1011", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10110000", ss_kathode);
        fail := fail or fourBitsIncorrect("0111", ss_anode);
        ss_1 <= "0100";
        ss_2 <= "0101";
        ss_3 <= "0110";
        ss_4 <= "0111";
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10011001", ss_kathode);
        fail := fail or fourBitsIncorrect("1110", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10010010", ss_kathode);
        fail := fail or fourBitsIncorrect("1101", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10000010", ss_kathode);
        fail := fail or fourBitsIncorrect("1011", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("11111000", ss_kathode);
        fail := fail or fourBitsIncorrect("0111", ss_anode);
        ss_1 <= "1000";
        ss_2 <= "1001";
        ss_3 <= "1010";
        ss_4 <= "1011";
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10000000", ss_kathode);
        fail := fail or fourBitsIncorrect("1110", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10010000", ss_kathode);
        fail := fail or fourBitsIncorrect("1101", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10001000", ss_kathode);
        fail := fail or fourBitsIncorrect("1011", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10000011", ss_kathode);
        fail := fail or fourBitsIncorrect("0111", ss_anode);
        ss_1 <= "1100";
        ss_2 <= "1101";
        ss_3 <= "1110";
        ss_4 <= "1111";
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("11000110", ss_kathode);
        fail := fail or fourBitsIncorrect("1110", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10100001", ss_kathode);
        fail := fail or fourBitsIncorrect("1101", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10000110", ss_kathode);
        fail := fail or fourBitsIncorrect("1011", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        fail := fail or eightBitsIncorrect("10001110", ss_kathode);
        fail := fail or fourBitsIncorrect("0111", ss_anode);
        success <= not fail;
        test_done <= true;
        report "Seven segments test done" severity note;
        wait;
    end process;
end Behavioral;


