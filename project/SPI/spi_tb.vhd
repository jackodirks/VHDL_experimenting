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
    constant FRAME_SIZE_L2    : natural := 1;
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
    signal spi_slave_1_suc   : boolean := true;

begin

    success <= spi_slave_1_suc;
    done <= spi_slave_1_done;

    -- Geberics are kept default
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
        wait for sclk_period/2;
        for D in 0 to 3 loop
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
        wait;
    end process;

end Behavioral;
