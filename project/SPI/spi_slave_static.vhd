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
    FRAME_SIZE_BIT          : natural   := 16;
    POLARITY                : std_logic := '0';
    PHASE                   : std_logic := '0';
    AUTOCLEAR_FRAMES        : boolean   := true
  );
  port (
    rst                     : in  STD_LOGIC;
    clk                     : in  STD_LOGIC;
    sclk                    : in  STD_LOGIC;                                    -- Serial clock
    mosi                    : in  STD_LOGIC;                                    -- Master output slave input
    miso                    : out STD_LOGIC;                                    -- Master input slave output
    ss                      : in  STD_LOGIC;                                    -- Slave Select
    trans_data              : in  std_logic_vector(FRAME_SIZE_BIT - 1 downto 0);
    receiv_data             : out std_logic_vector(FRAME_SIZE_BIT - 1 downto 0);
    done                    : out boolean;
  );
end spi_slave;


architecture Behavioral of spi_slave is
  type state_type is (reset, wait_for_slave_select, wait_for_idle, transaction, finished);
  -- The state of the FSM
  signal state                : state_type := reset;
  signal

begin


  -- The miso (slave output) controller, handles the MISO and data_in signals
  miso_controller : process(clk, read_data_in, next_output, ss)
      variable cursor         :   CURSOR_RANGE_SUBTYPE;
  begin
      if rising_edge(clk) then
          if read_data_in then
              data_in_buffer := data_in;
              cursor := cur_block_size-1;
          elsif next_output then
              if cursor > 0 then
                  cursor := cursor-1;
              end if;
          end if;
      end if;
      if ss = '1' then
          miso <= 'Z';
      else
          miso <= data_in_buffer(cursor);
      end if;
  end process;

  -- State behaviour
  state_behaviour: process(state)
  begin
      case state is
          when reset =>
              lock_safe       <= false;
              switch_buffer   <= false;
              next_output     <= false;
              next_input      <= false;
              read_data_in    <= true;
          when wait_for_slave_select|wait_for_idle =>
              lock_safe       <= true;
              switch_buffer   <= false;
              next_output     <= false;
              next_input      <= false;
              read_data_in    <= true;
          when data_get_wait|data_set_wait =>
              lock_safe       <= true;
              switch_buffer   <= false;
              next_output     <= false;
              next_input      <= false;
              read_data_in    <= false;
          when data_get =>
              lock_safe       <= true;
              switch_buffer   <= false;
              next_output     <= false;
              next_input      <= true;
              read_data_in    <= false;
          when data_set =>
              lock_safe       <= true;
              switch_buffer   <= false;
              next_output     <= true;
              next_input      <= false;
              read_data_in    <= false;
          when block_finished =>
              lock_safe       <= true;
              switch_buffer   <= true;
              next_output     <= false;
              next_input      <= false;
              read_data_in    <= true;
      end case;
  end process;

  -- State transition
  state_transition: process(clk, rst, mosi, sclk, ss)
      variable prev_sclk  : STD_LOGIC;
      variable cur_sclk   : STD_LOGIC;
      variable cur_bit    : BIT_RANGE_SUBTYPE;
  begin
      if rst = '1' then
          state <= reset;
          cur_bit := 0;
      elsif rising_edge(clk) then
          prev_sclk := cur_sclk;
          cur_sclk := sclk_debounced;
          case state is
              when reset|wait_for_slave_select =>
                  if ss = '1' then
                      state <= wait_for_slave_select;
                  else
                      state <= wait_for_idle;
                  end if;
              when wait_for_idle =>
                  -- possible situations:
                  -- Polarity = 0, sclk = 0, phase = 0: go to data_get
                  -- Polarity = 0, sclk = 0, phase = 1: go to data_set
                  -- Polarity = 1, sclk = 1, phase = 0: go to data_set
                  -- Polarity = 1, sclk = 1, phase = 1: go to data_get
                  -- Polarity != sclk: stay in wait_for_idle
                  if cur_polarity /= cur_sclk then
                      state <= wait_for_idle;
                  elsif cur_polarity = '0' then
                      if cur_phase = '0' then
                          state <= data_get_wait;
                      else
                          state <= data_set_wait;
                      end if;
                  else
                      if cur_phase = '1' then
                          state <= data_get_wait;
                      else
                          state <= data_set_wait;
                      end if;
                  end if;
              when data_get_wait =>
                  -- Wait for the next edge
                  if prev_sclk /= cur_sclk then
                      state <= data_get;
                  else
                      state <= data_get_wait;
                  end if;
              when data_get =>
                  if cur_phase /= cur_polarity then
                      if cur_bit+1 = cur_block_size then
                          state <= block_finished;
                      else
                          state <= data_set_wait;
                          cur_bit := cur_bit + 1;
                      end if;
                  else
                      state <= data_set_wait;
                  end if;
              when data_set_wait =>
                  if prev_sclk /= cur_sclk then
                      state <= data_set;
                  else
                      state <= data_set_wait;
                  end if;
              when data_set =>
                  if cur_phase = cur_polarity then
                      if cur_bit+1 >= cur_block_size then
                          state <= block_finished;
                      else
                          cur_bit := cur_bit + 1;
                          state <= data_get_wait;
                      end if;
                  else
                      state <= data_get_wait;
                  end if;
              when block_finished =>
                  cur_bit := 0;
                  if ss = '1' then
                      state <= wait_for_slave_select;
                  elsif cur_phase = cur_polarity then
                      state <= data_get_wait;
                  else
                      state <= data_set_wait;
                  end if;
          end case;
      end if;
  end process;
end Behavioral;
