library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

entity two_brams is
    Port (
        clk_50mhz : in  STD_LOGIC;

        usb_db : inout std_logic_vector(7 downto 0);
        usb_write : in std_logic;
        usb_astb : in std_logic;
        usb_dstb : in std_logic;
        usb_wait : out std_logic
    );
end two_brams;

architecture Behavioral of two_brams is

        constant address_map : addr_range_and_mapping_array := (
            address_range_and_map(
                low => std_logic_vector(to_unsigned(0, bus_address_type'length)),
                high => std_logic_vector(to_unsigned(2047, bus_address_type'length))
            ),
            address_range_and_map(
                low => std_logic_vector(to_unsigned(2048, bus_address_type'length)),
                high => std_logic_vector(to_unsigned(4095, bus_address_type'length))
            ));

        signal rst          : STD_LOGIC := '0';

        signal depp2demux : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal demux2depp : bus_slv2mst_type := BUS_SLV2MST_IDLE;

        signal demux2bramA   : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal bramA2demux   : bus_slv2mst_type := BUS_SLV2MST_IDLE;

        signal demux2bramB  : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal bramB2demux  : bus_slv2mst_type := BUS_SLV2MST_IDLE;
begin
    
    depp_slave_controller : entity work.depp_slave_controller
    port map (
        rst => rst,
        clk => clk_50mhz,
        mst2slv => depp2demux,
        slv2mst => demux2depp,
        USB_DB => usb_db,
        USB_WRITE => usb_write,
        USB_ASTB => usb_astb,
        USB_DSTB => usb_dstb,
        USB_WAIT => usb_wait
    );

    demux : entity work.bus_demux
    generic map (
        ADDRESS_MAP => address_map
    )
    port map (
        rst => rst,
        mst2demux => depp2demux,
        demux2mst => demux2depp,
        demux2slv(0) => demux2bramA,
        demux2slv(1) => demux2bramB,
        slv2demux(0) => bramA2demux,
        slv2demux(1) => bramB2demux
    );

    bramA : entity work.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 11
    )
    port map (
        rst => rst,
        clk => clk_50mhz,
        mst2mem => demux2bramA,
        mem2mst => bramA2demux
    );

    bramB : entity work.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 11
    )
    port map (
        rst => rst,
        clk => clk_50mhz,
        mst2mem => demux2bramB,
        mem2mst => bramB2demux
    );
end Behavioral;
