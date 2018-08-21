library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;
use IEEE.numeric_std.ALL;
use IEEE.math_real.ALL;

entity spi_tb is
    generic (
        clock_period : time;
        randVal : natural
    );
    port (
        clk : in STD_LOGIC;
        done : out boolean;
        success : out boolean
    );
end spi_tb;

architecture Behavioral of spi_tb is

    constant sclk_period      : time := clock_period * 2;        -- Run eight times slower than the system clock
    constant FRAME_SIZE_L2    : natural := 5;
    constant FRAME_SIZE       : natural := 2**FRAME_SIZE_L2;

    -- inout signals slave 1
    signal slave_1_rst        : STD_LOGIC;
    signal slave_1_sclk       : STD_LOGIC;
    signal slave_1_mosi       : STD_LOGIC;
    signal slave_1_miso       : STD_LOGIC;
    signal slave_1_ss         : STD_LOGIC;
    signal slave_1_data_in    : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_1_data_out   : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_1_done       : boolean;
    -- meta signals slave 1
    signal spi_slave_1_done   : boolean;
    signal spi_slave_1_suc    : boolean := true;

    -- inout signals slave 2
    signal slave_2_rst        : STD_LOGIC;
    signal slave_2_sclk       : STD_LOGIC;
    signal slave_2_mosi       : STD_LOGIC;
    signal slave_2_miso       : STD_LOGIC;
    signal slave_2_ss         : STD_LOGIC;
    signal slave_2_data_in    : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_2_data_out   : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_2_done       : boolean;
    -- meta signals slave 2
    signal spi_slave_2_done   : boolean;
    signal spi_slave_2_suc    : boolean := true;

    -- inout signals slave 3
    signal slave_3_rst        : STD_LOGIC;
    signal slave_3_sclk       : STD_LOGIC;
    signal slave_3_mosi       : STD_LOGIC;
    signal slave_3_miso       : STD_LOGIC;
    signal slave_3_ss         : STD_LOGIC;
    signal slave_3_data_in    : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_3_data_out   : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_3_done       : boolean;
    -- meta signals slave 3
    signal spi_slave_3_done   : boolean;
    signal spi_slave_3_suc    : boolean := true;

    -- inout signals slave 4
    signal slave_4_rst        : STD_LOGIC;
    signal slave_4_sclk       : STD_LOGIC;
    signal slave_4_mosi       : STD_LOGIC;
    signal slave_4_miso       : STD_LOGIC;
    signal slave_4_ss         : STD_LOGIC;
    signal slave_4_data_in    : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_4_data_out   : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    signal slave_4_done       : boolean;
    -- meta signals slave 4
    signal spi_slave_4_done   : boolean;
    signal spi_slave_4_suc    : boolean := true;

begin

    success <= spi_slave_1_suc and spi_slave_2_suc and spi_slave_3_suc and spi_slave_4_suc;
    done <= spi_slave_1_done and spi_slave_2_done and spi_slave_3_done and spi_slave_4_done;

    -- Frame size 16 bit
    -- SPO = SPH = 0
    spi_slave_1 : entity work.spi_slave
    generic map (
      FRAME_SIZE_BIT_L2 => FRAME_SIZE_L2
    )
    port map (
        rst => slave_1_rst,
        clk => clk,
        sclk => slave_1_sclk,
        mosi => slave_1_mosi,
        miso => slave_1_miso,
        ss => slave_1_ss,
        trans_data => slave_1_data_in,
        receiv_data => slave_1_data_out,
        done => slave_1_done
    );

    -- Frame size 16 bit
    spi_slave_2 : entity work.spi_slave
    generic map (
      FRAME_SIZE_BIT_L2 => FRAME_SIZE_L2,
      POLARITY => '1',
      PHASE => '0'
    )
    port map (
        rst => slave_2_rst,
        clk => clk,
        sclk => slave_2_sclk,
        mosi => slave_2_mosi,
        miso => slave_2_miso,
        ss => slave_2_ss,
        trans_data => slave_2_data_in,
        receiv_data => slave_2_data_out,
        done => slave_2_done
    );

    -- Frame size 16 bit
    spi_slave_3 : entity work.spi_slave
    generic map (
      FRAME_SIZE_BIT_L2 => FRAME_SIZE_L2,
      POLARITY => '0',
      PHASE => '1'
    )
    port map (
        rst => slave_3_rst,
        clk => clk,
        sclk => slave_3_sclk,
        mosi => slave_3_mosi,
        miso => slave_3_miso,
        ss => slave_3_ss,
        trans_data => slave_3_data_in,
        receiv_data => slave_3_data_out,
        done => slave_3_done
    );

    -- Frame size 16 bit
    spi_slave_4 : entity work.spi_slave
    generic map (
      FRAME_SIZE_BIT_L2 => FRAME_SIZE_L2,
      POLARITY => '1',
      PHASE => '1'
    )
    port map (
        rst => slave_4_rst,
        clk => clk,
        sclk => slave_4_sclk,
        mosi => slave_4_mosi,
        miso => slave_4_miso,
        ss => slave_4_ss,
        trans_data => slave_4_data_in,
        receiv_data => slave_4_data_out,
        done => slave_4_done
    );

    slave_1_test : process
        variable cur_data_out : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    begin
        slave_1_rst <= '1';
        slave_1_ss <= '0';
        slave_1_sclk <= '0';
        slave_1_data_in <= (others => '0');
        slave_1_mosi <= '0';
        wait for clock_period/2;
        -- Easy opener, run the values 0-15 trough both in- and output and see if it works as expected. 0 is selected already
        -- Wait for 2 cycles
        wait for 2*clock_period;
        -- Drop the reset
        slave_1_rst <= '0';
        -- Wait for 2 cycles
        wait for 2*clock_period;
        for D in 1 to 3 loop
            cur_data_out := STD_LOGIC_VECTOR(to_unsigned(D, cur_data_out'length));
            -- The system should be waiting for the first sclk, after which it tries to read data
            slave_1_data_in <= cur_data_out;
            -- Pre set
            slave_1_mosi <= cur_data_out(FRAME_SIZE - 1);
            for B in FRAME_SIZE - 2 downto 0 loop
                -- Get/read
                wait for sclk_period/2;
                slave_1_sclk <= not slave_1_sclk;
                assert(slave_1_miso = cur_data_out(B + 1));
                -- Set/write
                wait for sclk_period/2;
                slave_1_sclk <= not slave_1_sclk;
                slave_1_mosi <= cur_data_out(B);
            end loop;
            -- End the loop prematurely, since the last set is not actually a set, since we are already out of data
            -- Get/read
            wait for sclk_period/2;
            slave_1_sclk <= not slave_1_sclk;
            assert(slave_1_miso = cur_data_out(0));
            -- Finishing edge
            wait for sclk_period/2;
            slave_1_sclk <= not slave_1_sclk;
            slave_1_mosi <= '0';
            wait for (1.5)*clock_period;
            assert slave_1_done = true;
            assert(slave_1_data_out = std_logic_vector(to_unsigned(D, slave_1_data_out'LENGTH)));
            wait for sclk_period - (1.5)*clock_period;
            wait for sclk_period;
        end loop;
        slave_1_sclk <= '0';
        spi_slave_1_done <= true;
        report "SPI slave 1 tests done" severity note;
        wait;
    end process;

    slave_2_test : process
        variable cur_data_out : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    begin
        slave_2_rst <= '1';
        slave_2_ss <= '0';
        slave_2_sclk <= '1';
        slave_2_data_in <= (others => '0');
        slave_2_mosi <= '0';
        wait for clock_period/2;
        -- Easy opener, run the values 0-15 trough both in- and output and see if it works as expected. 0 is selected already
        -- Wait for 2 cycles
        wait for 2*clock_period;
        -- Drop the reset
        slave_2_rst <= '0';
        -- Wait for 2 cycles
        wait for 2*clock_period;
        for D in 1 to 3 loop
            cur_data_out := STD_LOGIC_VECTOR(to_unsigned(D, cur_data_out'length));
            -- The system should be waiting for the first sclk, after which it tries to read data
            slave_2_data_in <= cur_data_out;
            -- Pre set
            slave_2_mosi <= cur_data_out(FRAME_SIZE - 1);
            for B in FRAME_SIZE - 1 downto 0 loop
                -- Set/write
                wait for sclk_period/2;
                slave_2_sclk <= not slave_2_sclk;
                slave_2_mosi <= cur_data_out(B);
                -- Get/read
                wait for sclk_period/2;
                slave_2_sclk <= not slave_2_sclk;
                assert(slave_2_miso = cur_data_out(B));
            end loop;
            wait for (1.5)*clock_period;
            assert slave_2_done = true;
            assert(slave_2_data_out = std_logic_vector(to_unsigned(D, slave_1_data_out'LENGTH)));
            wait for sclk_period - (1.5)*clock_period;
            wait for sclk_period;
        end loop;
        slave_2_sclk <= '0';
        spi_slave_2_done <= true;
        report "SPI slave 2 tests done" severity note;
        wait;
    end process;

    slave_3_test : process
        variable cur_data_out : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    begin
        slave_3_rst <= '1';
        slave_3_ss <= '0';
        slave_3_sclk <= '0';
        slave_3_data_in <= (others => '0');
        slave_3_mosi <= '0';
        wait for clock_period/2;
        -- Easy opener, run the values 0-15 trough both in- and output and see if it works as expected. 0 is selected already
        -- Wait for 2 cycles
        wait for 2*clock_period;
        -- Drop the reset
        slave_3_rst <= '0';
        -- Wait for 2 cycles
        wait for 2*clock_period;
        for D in 1 to 3 loop
            cur_data_out := STD_LOGIC_VECTOR(to_unsigned(D, cur_data_out'length));
            -- The system should be waiting for the first sclk, after which it tries to read data
            slave_3_data_in <= cur_data_out;
            -- Pre set
            slave_3_mosi <= cur_data_out(FRAME_SIZE - 1);
            for B in FRAME_SIZE - 1 downto 0 loop
                -- Set/write
                wait for sclk_period/2;
                slave_3_sclk <= not slave_3_sclk;
                slave_3_mosi <= cur_data_out(B);
                -- Get/read
                wait for sclk_period/2;
                slave_3_sclk <= not slave_3_sclk;
                assert(slave_3_miso = cur_data_out(B));
            end loop;
            slave_3_sclk <= not slave_3_sclk;
            wait for (1.5)*clock_period;
            assert slave_3_done = true;
            assert(slave_3_data_out = std_logic_vector(to_unsigned(D, slave_1_data_out'LENGTH)));
            wait for sclk_period - (1.5)*clock_period;
            wait for sclk_period;
        end loop;
        slave_3_sclk <= '0';
        spi_slave_3_done <= true;
        report "SPI slave 3 tests done" severity note;
        wait;
    end process;

    slave_4_test : process
        variable cur_data_out : STD_LOGIC_VECTOR(FRAME_SIZE - 1 downto 0);
    begin
        slave_4_rst <= '1';
        slave_4_ss <= '0';
        slave_4_sclk <= '1';
        slave_4_data_in <= (others => '0');
        slave_4_mosi <= '0';
        wait for clock_period/2;
        -- Easy opener, run the values 0-15 trough both in- and output and see if it works as expected. 0 is selected already
        -- Wait for 2 cycles
        wait for 2*clock_period;
        -- Drop the reset
        slave_4_rst <= '0';
        -- Wait for 2 cycles
        wait for 2*clock_period;
        for D in 1 to 3 loop
            cur_data_out := STD_LOGIC_VECTOR(to_unsigned(D, cur_data_out'length));
            -- The system should be waiting for the first sclk, after which it tries to read data
            slave_4_data_in <= cur_data_out;
            -- Pre set
            slave_4_mosi <= cur_data_out(FRAME_SIZE - 1);
            for B in FRAME_SIZE - 2 downto 0 loop
                -- Get/read
                wait for sclk_period/2;
                slave_4_sclk <= not slave_4_sclk;
                assert(slave_4_miso = cur_data_out(B + 1));
                -- Set/write
                wait for sclk_period/2;
                slave_4_sclk <= not slave_4_sclk;
                slave_4_mosi <= cur_data_out(B);
            end loop;
            -- End the loop prematurely, since the last set is not actually a set, since we are already out of data
            -- Get/read
            wait for sclk_period/2;
            slave_4_sclk <= not slave_4_sclk;
            assert(slave_4_miso = cur_data_out(0));
            -- Finishing edge
            wait for sclk_period/2;
            slave_4_sclk <= not slave_4_sclk;
            slave_4_mosi <= '0';
            wait for (1.5)*clock_period;
            assert slave_4_done = true;
            assert(slave_4_data_out = std_logic_vector(to_unsigned(D, slave_1_data_out'LENGTH)));
            wait for sclk_period - (1.5)*clock_period;
            wait for sclk_period;
        end loop;
        slave_4_sclk <= '0';
        spi_slave_4_done <= true;
        report "SPI slave 4 tests done" severity note;
        wait;
    end process;

end Behavioral;
