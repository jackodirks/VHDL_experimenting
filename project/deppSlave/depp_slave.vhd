library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity depp_slave is
    port (
             ----------------------------------------------------
             -- Interaction with the rest of the system (internal)
             ----------------------------------------------------
             rst           : in STD_LOGIC;                         -- Reset the FSM
             clk           : in STD_LOGIC;                         -- Clock
             addr          : out STD_LOGIC_VECTOR(7 DOWNTO 0);     -- Address
             data          : inout STD_LOGIC_VECTOR(7 DOWNTO 0);   -- Data bus
             read_enable   : out STD_LOGIC;                        -- Request a read from the data bus. Cannot be high if write_enable is high
             write_enable  : out STD_LOGIC;                        -- Request a write to the data bus. Cannot be high if read_enable is high
             ready         : in STD_LOGIC;                         -- Signals to this device that a read/write has been completed.
             ----------------------------------------------------
             -- Interaction with the outside world (external). All control signals are active high.
             ----------------------------------------------------
             USB_DB        : inout STD_LOGIC_VECTOR(7 DOWNTO 0);
             USB_WRITE     : in STD_LOGIC;
             USB_ASTB      : in STD_LOGIC;
             USB_DSTB      : in STD_LOGIC;
             USB_WAIT      : out STD_LOGIC
         );

end depp_slave;

architecture behaviourial of depp_slave is
    type state_type is (idle, data_write_wait_internal_ready, data_read_wait_internal_ready, data_wait_internal_complete, wait_usb_complete);

    -- Control signals
    signal state : state_type := idle;
    signal address_write : boolean := false;
    signal data_read : boolean := false;
    signal data_write : boolean := false;

    -- Data storage
    signal addr_internal : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    signal data_internal : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
begin

    address_write <= true when USB_ASTB = '0' else false;
    data_write <= true when USB_DSTB = '0' and USB_WRITE = '0' else false;
    data_read <= true when USB_DSTB = '0' and USB_WRITE = '1' else false;

    data <= data_internal when data_write else (others => 'Z');
    USB_DB <= data_internal when data_read else (others => 'Z');
    addr <= addr_internal;

    latch_data : process(clk, USB_ASTB, USB_DSTB, USB_WRITE)
    begin
        if rising_edge(clk) then
            if address_write then
                addr_internal <= USB_DB;
            end if;

            if data_write then
                data_internal <= USB_DB;
            end if;

            if data_read and ready = '1' then
                data_internal <= data;
            end if;
        end if;
    end process;

    state_transition : process(rst, clk, ready, USB_WRITE, USB_ASTB, USB_DSTB)
    begin
        if rst = '1' then
            state <= idle;
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    if address_write then
                        state <= wait_usb_complete;
                    elsif data_write then
                        state <= data_write_wait_internal_ready;
                    elsif data_read then
                        state <= data_read_wait_internal_ready;
                    end if;
                when data_write_wait_internal_ready | data_read_wait_internal_ready =>
                    if ready = '1' then
                        state <= data_wait_internal_complete;
                    end if;
                when data_wait_internal_complete =>
                    if ready = '0' then
                        state <= wait_usb_complete;
                    end if;
                when wait_usb_complete =>
                    if not data_write and not data_read and not address_read then
                        state <= idle;
                    end if;
            end case;
        end if;
    end process;

    state_output : process(state)
    begin
        case state is
            when idle =>
                read_enable <= '0';
                write_enable <= '0';
                USB_WAIT <= '0';
            when data_write_wait_internal_ready =>
                read_enable <= '0';
                write_enable <= '1';
                USB_WAIT <= '0';
            when data_read_wait_internal_ready =>
                read_enable <= '1';
                write_enable <= '0';
                USB_WAIT <= '0';
            when data_wait_internal_complete =>
                read_enable <= '0';
                write_enable <= '0';
                USB_WAIT <= '0';
            When wait_usb_complete =>
                read_enable <= '0';
                write_enable <= '0';
                USB_WAIT <= '1';
        end case;
    end process;
end behaviourial;
