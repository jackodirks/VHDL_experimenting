library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use std.textio.ALL;

entity tb_main is
    end tb_main;

architecture tb of tb_main is

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
    -- Component declaration --
    component simple_multishot_timer is
        generic (
            match_val   : integer
        );
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
    component uart_receiv is
        generic (
            baudrate                : Natural;
            clockspeed              : Natural;
            parity_bit_in           : boolean;
            parity_bit_in_type      : Natural range 0 to 3;
            bit_count_in            : Natural range 5 to 9;
            stop_bits_in            : Natural range 1 to 2
        );
        port (
            rst                     : in    STD_LOGIC;
            clk                     : in    STD_LOGIC;
            uart_rx                 : in    STD_LOGIC;
            received_data           : out   STD_LOGIC_VECTOR(8 DOWNTO 0);
            data_ready              : out   STD_LOGIC;                    -- Signals that data has been received.
            parity_error            : out   STD_LOGIC;                    -- Signals that the parity check has failed, is zero if there was none
            data_error              : out   STD_LOGIC                     -- Signals that data receiving has encoutered errors
        );
    end component;

    constant baud_118200_ns                 : natural := 4230;          -- 1/118200 seconds
    constant baud_9600_ns                   : natural := 104167;        -- 1/9600 seconds

    -- Signal declaration --
    signal clk                              : STD_LOGIC := '1';
    signal led                              : STD_LOGIC_VECTOR (7 DOWNTO 0);
    signal slide_switch                     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal simple_multishot_timer_rst       : STD_LOGIC := '1';
    signal simple_multishot_timer_done      : STD_LOGIC;
    signal simple_multishot_timer_cur_val   : STD_LOGIC_VECTOR(6 DOWNTO 0);
    signal ss_kathode                       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal ss_anode                         : STD_LOGIC_VECTOR(3 DOWNTO 0);

    signal uart_data_1_rst                  : STD_LOGIC := '1';
    signal uart_data_1_rx                   : STD_LOGIC := '1';
    signal uart_data_1                      : STD_LOGIC_VECTOR(8 DOWNTO 0);
    signal uart_data_1_ready                : STD_LOGIC;
    signal uart_data_1_par_err              : STD_LOGIC;
    signal uart_data_1_dat_err              : STD_LOGIC;

    signal tests                            : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
begin
    simple_multishot_timer_50 : simple_multishot_timer
    generic map (
        match_val => 50
    )
    port map (
        clk_50MHZ => clk,
        rst => simple_multishot_timer_rst,
        done => simple_multishot_timer_done
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

    uart_1 : uart_receiv
    generic map (
        baudrate => 236400,
        clockspeed => 50000000,
        parity_bit_in => false,
        parity_bit_in_type => 0,
        bit_count_in => 8,
        stop_bits_in => 1
    )
    port map (
        rst => uart_data_1_rst,
        clk => clk,
        uart_rx => uart_data_1_rx,
        received_data => uart_data_1,
        data_ready => uart_data_1_ready,
        parity_error => uart_data_1_par_err,
        data_error => uart_data_1_dat_err
    );

    clock_gen : process
    begin
        if tests /= "11" then
            clk <= not clk;
            wait for 10 ns;
        else
            wait;
        end if;
    end process;

    --clk <= not clk after 10 ns;
    process
    begin
        simple_multishot_timer_rst <= '0';
        wait until simple_multishot_timer_done = '1';
        simple_multishot_timer_rst <= '1';
        assert false report "simple_multishot_timer test done" severity note;
        tests(0) <= '1';
        wait;
    end process;

    process
        variable data_buffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
    begin
        uart_data_1_rst <= '0';
        wait for 4230 ns;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_data_1_rx <= '0';
            for I in 7 DOWNTO 0 loop
                wait for 4230 ns;
                uart_data_1_rx <= data_buffer(I);
            end loop;
            wait for 4230 ns;
            uart_data_1_rx <= '1';
            wait until uart_data_1_ready = '1';
            assert uart_data_1(7 DOWNTO 0) = data_buffer report "uart_data_1 unexpected value" severity error;
            assert uart_data_1_dat_err = '0' report "uart_data_1_dat_err unexpected value" severity error;
            assert uart_data_1_par_err = '0' report "uart_data_1_par_err unexpected value" severity error;
            wait for 2115 ns;
        end loop;
        uart_data_1_rst <= '1';
        assert false report "UART_data_1 test done" severity note;
        tests(1) <= '1';
        wait;
    end process;
end tb;
