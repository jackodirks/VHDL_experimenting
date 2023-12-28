library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity toplevel is
    generic (
        clk_freq_mhz : positive
    );
    Port (
        CLK12MHZ : in STD_LOGIC;
        ja : inout std_logic_vector(7 downto 0);
        jb : out std_logic_vector(7 downto 0);
        jc : inout std_logic_vector(7 downto 0);
        uart_rxd_out : out std_logic;
        uart_txd_in : in std_logic
    );
end toplevel;

architecture Behavioral of toplevel is

    signal CLKSYS : std_logic;
    signal clk_gen_locked : std_logic;
    signal global_reset : std_logic := '0';
    constant clk_frequency_hz : real := real(clk_freq_mhz) * real(1000_000);
    constant clk_period : time := (1 sec) / (clk_frequency_hz);

    component main_clock_gen
port
 (-- Clock in ports
  -- Clock out ports
  CLKSYS          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  CLK12MHZ           : in     std_logic
 );
end component;


begin
    ja(3 downto 0) <= (others => 'Z');
    jb(3 downto 0) <= (others => 'Z');
    jc(7 downto 2) <= (others => 'Z');

    main_file : entity work.main_file
    generic map (
        clk_period => clk_period,
        baud_rate => 2000000
    ) port map (
        JA_gpio => ja(7 downto 4),
        JB_gpio => jb(7 downto 4),
        clk => CLKSYS,
        global_reset => '0',
        master_rx => uart_txd_in,
        master_tx => uart_rxd_out,
        slave_rx => jc(0),
        slave_tx => jc(1)
    );


clk_gen : main_clock_gen
port map (
    reset => '0',
    CLK12MHZ => CLK12MHZ,
    CLKSYS => CLKSYS,
    locked => clk_gen_locked
);

end Behavioral;
