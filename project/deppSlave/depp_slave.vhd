library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bus_pkg.all;
use work.depp_pkg.all;

entity depp_slave is
    port (
        ----------------------------------------------------
        -- Interaction with the rest of the system (internal)
        ----------------------------------------------------
        rst           : in STD_LOGIC;                         -- Reset the FSM
        clk           : in STD_LOGIC;                         -- Clock
        depp2bus      : out depp2bus_type;
        bus2depp      : in bus2depp_type;

        ----------------------------------------------------
        -- Interaction with the outside world (external). All control signals are active low.
        ----------------------------------------------------
        USB_DB        : inout STD_LOGIC_VECTOR(7 DOWNTO 0);
        USB_WRITE     : in STD_LOGIC;
        USB_ASTB      : in STD_LOGIC;
        USB_DSTB      : in STD_LOGIC;
        USB_WAIT      : out STD_LOGIC
         );

end depp_slave;

architecture behaviourial of depp_slave is
    signal usb_astb_delayed : std_logic;
    signal usb_dstb_delayed : std_logic;
begin

    sequential : process(clk)
        variable wait_dstb_finish : boolean := false;
        variable address : std_logic_vector(7 downto 0) := (others => '0');
        variable read_latch : std_logic_vector(7 downto 0) := (others => '0');
        variable usb_dstb_act : std_logic := '0';
        variable usb_astb_act : std_logic := '0';
    begin
        if rising_edge(clk) then

            -- We are crossing clock domains. Therefore, if either of these is high, other signals might still be settling.
            -- Therefore, delay these by one cycle so that by the time interpretation starts, everything has settled.
            usb_astb_delayed <= USB_ASTB;
            usb_dstb_delayed <= USB_DSTB;

            USB_WAIT <= '0';
            USB_DB <= (others => 'Z');
            depp2bus <= DEPP2BUS_IDLE;
            if rst = '1' then
                USB_WAIT <= '1';
                wait_dstb_finish := false;
                usb_dstb_act := '1';
                usb_astb_act := '1';
            else

                if usb_dstb_delayed = '0' and usb_dstb = '0' then
                    usb_dstb_act := '0';
                else
                    usb_dstb_act := '1';
                end if;

                if usb_astb_delayed = '0' and usb_astb = '0' then
                    usb_astb_act := '0';
                else
                    usb_astb_act := '1';
                end if;

                if usb_astb_act = '0' then
                    USB_WAIT <= '1';
                    if USB_WRITE = '0' then
                        address := USB_DB;
                    elsif USB_WRITE = '1' then
                        USB_DB <= address;
                    end if;
                elsif usb_dstb_act = '0' then

                    if bus2depp.done = true and wait_dstb_finish = false then
                        wait_dstb_finish := true;
                        read_latch := bus2depp.readData;
                    end if;

                    if USB_WRITE = '0' then
                        depp2bus.writeData <= USB_DB;
                        depp2bus.writeEnable <= true;
                    elsif USB_WRITE = '1' then
                        USB_DB <= read_latch;
                        depp2bus.readEnable <= true;
                    end if;
                end if;

                depp2bus.address <= address;

                if wait_dstb_finish then
                    if usb_dstb_act = '1' then
                        wait_dstb_finish := false;
                    else
                        USB_WAIT <= '1';
                    end if;
                    depp2bus.writeEnable <= false;
                    depp2bus.readEnable <= false;
                end if;

            end if;
        end if;
    end process;

end behaviourial;
