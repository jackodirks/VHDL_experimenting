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
            match_val : integer
        );
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            done        : out STD_LOGIC
        );
    end component;

    component seven_segments_driver is
        generic (
            switch_freq         : natural;
            clockspeed          : natural
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

    component data_safe_8_bit is
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            read        : in STD_LOGIC;
            data_in     : in STD_LOGIC_VECTOR(7 DOWNTO 0);
            data_out    : out STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    end component;

    -- Constant declaration --
    constant clock_period_ns                : natural := 40;

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

    signal uart_data_2_rst                  : STD_LOGIC := '1';
    signal uart_data_2_rx                   : STD_LOGIC := '1';
    signal uart_data_2                      : STD_LOGIC_VECTOR(8 DOWNTO 0);
    signal uart_data_2_ready                : STD_LOGIC;
    signal uart_data_2_par_err              : STD_LOGIC;
    signal uart_data_2_dat_err              : STD_LOGIC;

    signal data_safe_8_bit_rst              : STD_LOGIC := '1';
    signal data_safe_8_bit_read             : STD_LOGIC := '0';
    signal data_safe_8_bit_data_in          : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    signal data_safe_8_bit_data_out         : STD_LOGIC_VECTOR(7 DOWNTO 0);

    signal tests                            : STD_LOGIC_VECTOR(2 DOWNTO 0) := (others => '0');
begin

    simple_multishot_timer_500 : simple_multishot_timer
    generic map (
        match_val => 500
    )
    port map (
        clk => clk,
        rst => simple_multishot_timer_rst,
        done => simple_multishot_timer_done
    );

    ss_driver : seven_segments_driver
    generic map (
        switch_freq => 2000000,
        clockspeed => 50000000
    )
    port map (
        clk => clk,
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

    uart_2 : uart_receiv
    generic map (
        baudrate => 236400,
        clockspeed => 50000000,
        parity_bit_in => true,
        parity_bit_in_type => 0,
        bit_count_in => 8,
        stop_bits_in => 2
    )
    port map (
        rst => uart_data_2_rst,
        clk => clk,
        uart_rx => uart_data_2_rx,
        received_data => uart_data_2,
        data_ready => uart_data_2_ready,
        parity_error => uart_data_2_par_err,
        data_error => uart_data_2_dat_err
    );

    data_safe : data_safe_8_bit
    port map (
        clk => clk,
        rst => data_safe_8_bit_rst,
        read => data_safe_8_bit_read,
        data_in => data_safe_8_bit_data_in,
        data_out => data_safe_8_bit_data_out
    );

    process
        variable test_data : STD_LOGIC_VECTOR(7 DOWNTO 0 ) := "01100010";
    begin
        data_safe_8_bit_data_in <= test_data;
        data_safe_8_bit_rst <= '0';
        wait for 100 ns;
        assert data_safe_8_bit_data_out = "00000000" report "data_safe_8_bit_data_out has changed to early" severity error;
        data_safe_8_bit_read <= '1';
        wait for 100 ns;
        assert data_safe_8_bit_data_out = test_data report "data_safe_8_bit_data_out has not changed while this was expected" severity error;
        data_safe_8_bit_read <= '0';
        data_safe_8_bit_data_in <= "01010101";
        wait for 100 ns;
        assert data_safe_8_bit_data_out = test_data report "data_safe_8_bit_data_out has changed unexpected" severity error;
        tests(2) <= '1';
        assert false report "data_safe_8_bit tests done" severity note;
        wait;
    end process;

    clock_gen : process
    begin
        if tests /= "111" then
            clk <= not clk;
            wait for 10 ns;
        else
            wait;
        end if;
    end process;

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

    process
        variable data_buffer    : STD_LOGIC_VECTOR(7 DOWNTO 0);
        variable odd            : STD_LOGIC := '0';
    begin
        uart_data_2_rst <= '0';
        wait for 4230 ns;
        for D in 0 to 255 loop
            data_buffer := STD_LOGIC_VECTOR(to_unsigned(D, data_buffer'length));
            uart_data_2_rx <= '0';
            for I in 7 DOWNTO 0 loop
                wait for 4230 ns;
                uart_data_2_rx <= data_buffer(I);
                if data_buffer(I) = '1' then
                    odd := not odd;
                end if;
            end loop;
            wait for 4230 ns;
            -- Send the parity bit
            uart_data_2_rx <= odd;
            wait for 4230 ns;
            uart_data_2_rx <= '1';
            wait until uart_data_2_ready = '1';
            wait for 4230 ns;
            assert uart_data_2(7 DOWNTO 0) = data_buffer report "uart_data_2 unexpected value" severity error;
            assert uart_data_2_dat_err = '0' report "uart_data_2_dat_err unexpected value" severity error;
            assert uart_data_2_par_err = '0' report "uart_data_2_par_err unexpected value" severity error;
            wait for 2115 ns;
        end loop;
        uart_data_2_rst <= '1';
        assert false report "UART_data_2 test done" severity note;
        tests(2) <= '1';
        wait;
    end process;
end tb;
