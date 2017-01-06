library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity seven_segments_tb is
    port (
        clk : in STD_LOGIC;
        done : out boolean
    );
end seven_segments_tb;

architecture Behavioral of seven_segments_tb is

    function hstr(slv: std_logic_vector) return string is
    variable hexlen: integer;
    variable longslv : std_logic_vector(67 downto 0) := (others => '0');
    variable hex : string(1 to 16);
    variable fourbit : std_logic_vector(3 downto 0);
    begin
        hexlen := (slv'left+1)/4;
        if (slv'left+1) mod 4 /= 0 then
            hexlen := hexlen + 1;
        end if;
        longslv(slv'left downto 0) := slv;
        for i in (hexlen -1) downto 0 loop
            fourbit := longslv(((i*4)+3) downto (i*4));
            case fourbit is
                when "0000" => hex(hexlen -I) := '0';
                when "0001" => hex(hexlen -I) := '1';
                when "0010" => hex(hexlen -I) := '2';
                when "0011" => hex(hexlen -I) := '3';
                when "0100" => hex(hexlen -I) := '4';
                when "0101" => hex(hexlen -I) := '5';
                when "0110" => hex(hexlen -I) := '6';
                when "0111" => hex(hexlen -I) := '7';
                when "1000" => hex(hexlen -I) := '8';
                when "1001" => hex(hexlen -I) := '9';
                when "1010" => hex(hexlen -I) := 'A';
                when "1011" => hex(hexlen -I) := 'B';
                when "1100" => hex(hexlen -I) := 'C';
                when "1101" => hex(hexlen -I) := 'D';
                when "1110" => hex(hexlen -I) := 'E';
                when "1111" => hex(hexlen -I) := 'F';
                when "ZZZZ" => hex(hexlen -I) := 'z';
                when "UUUU" => hex(hexlen -I) := 'u';
                when "XXXX" => hex(hexlen -I) := 'x';
                when others => hex(hexlen -I) := '?';
            end case;
        end loop;
        return hex(1 to hexlen);
    end hstr;

    procedure checkCorr(exp, got: STD_LOGIC_VECTOR) is
    begin
        assert exp = got report "Seven segments misbehaves: data output error. Expected "; --& STD_LOGIC_VECTOR'to_string(exp) & " got " & STD_LOGIC_VECTOR'image(got) severity error;
    end checkCorr;

    procedure checkCorrOutput(exp, got: STD_LOGIC_VECTOR) is
    begin
        assert exp = got report "Seven segments misbehaves: display output error. Expected "; --& STD_LOGIC_VECTOR'to_string(exp) & " got " & STD_LOGIC_VECTOR'image(got) severity error;
    end checkCorrOutput;

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
        checkCorr("11000000", ss_kathode);
        checkCorrOutput("1110", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        checkCorr("11111001", ss_kathode);
        checkCorrOutput("1101", ss_anode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        checkCorr("10100100", ss_kathode);
        checkCorrOutput("1011", ss_anode);
        test_done <= true;
        report "Seven segments test done" severity note;
        wait;
    end process;
end Behavioral;


