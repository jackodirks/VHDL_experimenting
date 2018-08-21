library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- A static SPI slave. It is static in the sense that all settings (frame size, polarity, ..)
-- are set before synthesis and cannot be changed afterwards.
-- The MSB is transmitted and received first, so if the word is 0101 (5), then we receive or send 0-1-0-1.
-- Two important properties are SPO (Clock polarity) and SPH (Phase Control)
-- Polarity is about the default or idle clock.
--  SPO = 0 means that if there is no data transfer, the clock is 0
--  SPO = 1 means that if there is no data transfer, the clock is 1
-- Phase control is about the edge on which data is read and set by both master and slave
--  SPH = 0 means read on rising edge and set on falling edge
--  SPH = 1 means read on falling edge and set on rising edge

entity spi_slave is
  generic (
    FRAME_SIZE_BIT_L2       : natural   := 4;
    POLARITY                : std_logic := '0';
    PHASE                   : std_logic := '0'
  );
  port (
    rst                     : in  STD_LOGIC;
    clk                     : in  STD_LOGIC;
    sclk                    : in  STD_LOGIC;                                    -- Serial clock
    mosi                    : in  STD_LOGIC;                                    -- Master output slave input
    miso                    : out STD_LOGIC;                                    -- Master input slave output
    ss                      : in  STD_LOGIC;                                    -- Slave Select
    trans_data              : in  std_logic_vector(2**FRAME_SIZE_BIT_L2 - 1 downto 0);
    receiv_data             : out std_logic_vector(2**FRAME_SIZE_BIT_L2 - 1 downto 0);
    done                    : out boolean
);
end spi_slave;

architecture Behavioral of spi_slave is
  constant FRAME_SIZE_BIT     : natural := 2**FRAME_SIZE_BIT_L2;
  signal transceiver_active   : boolean;
  signal miso_int             : std_logic;
  signal sclk_int             : std_logic;
  signal cursor_ex            : unsigned(FRAME_SIZE_BIT_L2 - 1 downto 0);
begin
  slave_selected : process(ss, miso_int, sclk)
  begin
    if ss = '1' then
      miso <= 'Z';
      sclk_int <= '0';
    else
      miso <= miso_int;
      sclk_int <= sclk;
    end if;
  end process;

  finish_generator : process(clk, transceiver_active)
    variable lastVal          : boolean := true;
  begin
    if rising_edge(clk) then
      lastVal := not transceiver_active;
    end if;
    done <= not (transceiver_active or lastVal);
  end process;

  transceiver : process(clk, trans_data)
    variable cursor           : unsigned(FRAME_SIZE_BIT_L2 - 1 downto 0) := (others => '0');
    variable data_out         : std_logic_vector(receiv_data'RANGE) := (others => '0');
    variable last_sclk        : std_logic := '0';
  begin
    if rising_edge(clk) then
      if rst = '1' then
        if POLARITY = PHASE then
          cursor := (others => '1');
        else
          cursor := (others => '0');
        end if;
        last_sclk := sclk;
      elsif sclk_int /= last_sclk then
        last_sclk := sclk_int;
        if (PHASE = '0' and sclk_int = '0') or (PHASE = '1' and sclk_int = '1') then
          cursor := cursor - 1;
        end if;
        if (PHASE = '0' and sclk_int = '1') or (PHASE = '1' and sclk_int = '0') then
          data_out(to_integer(cursor)) := mosi;
        end if;
      end if;
    end if;
    if POLARITY = PHASE then
      transceiver_active <= not(cursor = 2**FRAME_SIZE_BIT_L2 - 1);
    else
      transceiver_active <= not(cursor = 0);
    end if;
    receiv_data <= data_out;
    miso_int <= trans_data(to_integer(cursor));
    cursor_ex <= cursor;
  end process;
end Behavioral;
