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

    constant clk_freq                       : natural := (1000 ms / clock_period);
    constant sclk_period                    : time := clock_period * 100;        -- Run ten times slower then the system clock
    constant half_sclk_period               : time := sclk_period / 2;          -- Convinience thing

    -- inout signals slave 1
    signal slave_1_rst          : STD_LOGIC;
    signal slave_1_polarity     : STD_LOGIC;
    signal slave_1_phase        : STD_LOGIC;
    signal slave_1_sclk         : STD_LOGIC;
    signal slave_1_mosi         : STD_LOGIC;
    signal slave_1_miso         : STD_LOGIC;
    signal slave_1_ss           : STD_LOGIC;
    signal slave_1_data_in      : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal slave_1_data_out     : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal slave_1_block_size   : natural range 1 to 32;
    signal slave_1_block_done   : boolean;
    -- meta signals slave 1
    signal spi_slave_1_suc      : boolean := true;
    signal spi_slave_1_done     : boolean := false;

begin

    success <= spi_slave_1_suc;
    done <= spi_slave_1_done;

    spi_slave_1 : entity work.spi_slave
    generic map (
        debounce_ticks => 3
    )
    port map (
        rst => slave_1_rst,
        clk => clk,
        polarity => slave_1_polarity,
        phase => slave_1_phase,
        sclk => slave_1_sclk,
        mosi => slave_1_mosi,
        miso => slave_1_miso,
        ss => slave_1_ss,
        data_in => slave_1_data_in,
        data_out => slave_1_data_out,
        block_size => slave_1_block_size,
        block_done => slave_1_block_done
    );

    slave_1_test : process
        variable cur_data_out : STD_LOGIC_VECTOR(4 DOWNTO 0);
    begin
        slave_1_rst <= '1';
        slave_1_ss <= '0';
        slave_1_polarity <= '0';
        slave_1_phase <= '0';
        slave_1_block_size <= 5;
        slave_1_sclk <= '1';
        slave_1_data_in <= (others => '0');
        slave_1_mosi <= '0';
        -- Easy opener, run the values 0-15 trough both in- and output and see if it works as expected. 0 is selected already
        -- Wait for 2 cycles
        for D in 0 to 1 loop
            wait until rising_edge(clk);
        end loop;
        -- Drop the reset
        slave_1_rst <= '0';
        -- Wait for 2 cycles
        for D in 0 to 1 loop
            wait until rising_edge(clk);
        end loop;
        wait for half_sclk_period;
        slave_1_sclk <= not slave_1_sclk;
        for D in 0 to 31 loop
            cur_data_out := STD_LOGIC_VECTOR(to_unsigned(D, cur_data_out'length));
            -- The system should be waiting for the first sclk, after which it tries to read data
            slave_1_data_in(4 DOWNTO 0) <= cur_data_out;
            for B in 4 downto 0 loop
                -- Set/write
                slave_1_mosi <= cur_data_out(B);
                wait for half_sclk_period;
                slave_1_sclk <= not slave_1_sclk;
                -- Get/read
                if slave_1_miso /= cur_data_out(B) then
                   spi_slave_1_suc <= false;
                   report "slave 1 read error: expected " & STD_LOGIC'image(cur_data_out(B)) & " but got: " & std_logic'image(slave_1_miso) & " B = " & natural'image(B) & " D = " & natural'image(D) severity error;
               end if;
                wait for half_sclk_period;
                slave_1_sclk <= not slave_1_sclk;
            end loop;
        end loop;
        spi_slave_1_done <= true;
        wait;
    end process;

end Behavioral;
