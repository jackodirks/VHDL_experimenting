library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bus_pkg.all;

entity depp_slave is
    port (
        ----------------------------------------------------
        -- Interaction with the rest of the system (internal)
        ----------------------------------------------------
        rst           : in STD_LOGIC;                         -- Reset the FSM
        clk           : in STD_LOGIC;                         -- Clock
        mst2slv       : out bus_mst2slv_type;
        slv2mst       : in bus_slv2mst_type;

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

    signal address : std_logic_vector(7 downto 0) := (others => '0');

begin

    sequential : process(clk)
        variable wait_dstb_finish : boolean := false;
        variable mst2slv_internal : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    begin
        if rising_edge(clk) then
            mst2slv_internal.writeEnable := '0';
            mst2slv_internal.readEnable := '0';
            mst2slv_internal.address := address;
            USB_WAIT <= '0';
            USB_DB <= (others => 'Z');
            mst2slv <= BUS_MST2SLV_IDLE;
            if rst = '1' then
                wait_dstb_finish := false;
            else
                if wait_dstb_finish then
                    if slv2mst.ack = '0' and USB_DSTB = '1' then
                        wait_dstb_finish := false;
                    else
                        USB_WAIT <= '1';
                    end if;
                end if;

                if USB_ASTB = '0' then
                    USB_WAIT <= '1';
                    if USB_WRITE = '0' then
                        address <= USB_DB;
                    elsif USB_WRITE = '1' then
                        USB_DB <= address;
                    end if;
                elsif USB_DSTB = '0' then
                    if USB_WRITE = '0' then
                        mst2slv_internal.writeData := USB_DB;
                        mst2slv_internal.writeEnable := '1';
                    elsif USB_WRITE = '1' then
                        USB_DB <= slv2mst.readData;
                        mst2slv_internal.readEnable := '1';
                    end if;

                    if slv2mst.ack = '1' then
                        wait_dstb_finish := true;
                    end if;
                end if;

                if wait_dstb_finish = false then
                    mst2slv <= mst2slv_internal;
                end if;

            end if;
        end if;
    end process;

end behaviourial;
