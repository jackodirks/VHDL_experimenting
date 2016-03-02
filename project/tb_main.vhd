library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity tb_main is
    end tb_main;

architecture tb of tb_main is
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


    -- Signal declaration --
    signal clk                              : STD_LOGIC := '1';
    signal led                              : STD_LOGIC_VECTOR (7 DOWNTO 0);
    signal slide_switch                     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal simple_multishot_timer_rst       : STD_LOGIC := '1';
    signal simple_multishot_timer_done      : STD_LOGIC;
    signal simple_multishot_timer_cur_val   : STD_LOGIC_VECTOR(6 DOWNTO 0);
    signal ss_kathode                       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal ss_anode                         : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal uart_data_1_rst                  : STD_LOGIC;
    signal uart_data_1_rx                   : STD_LOGIC;
    signal uart_data_1                      : STD_LOGIC_VECTOR(8 DOWNTO 0);
    signal uart_data_1_ready                : STD_LOGIC;
    signal uart_data_1_par_err              : STD_LOGIC;
    signal uart_data_1_dat_err              : STD_LOGIC;
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
        baudrate => 115200,
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

    clk <= not clk after 10 ns;
    process
    begin
        simple_multishot_timer_rst <= '0';
        wait until simple_multishot_timer_done = '1';
        simple_multishot_timer_rst <= '1';
        assert false report "simple_multishot_timer test done" severity note;
        wait;
    end process;
end tb;
