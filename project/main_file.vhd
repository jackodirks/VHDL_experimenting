library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

entity main_file is
    Port (
        --JA_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JB_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JC_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JD_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        slide_switch : in  STD_LOGIC_VECTOR (7 downto 0);
        --push_button : in  STD_LOGIC_VECTOR (3 downto 0);
        led : out  STD_LOGIC_VECTOR (7 downto 0);
        seven_seg_kath : out  STD_LOGIC_VECTOR (7 downto 0);
        seven_seg_an : out  STD_LOGIC_VECTOR (3 downto 0);
        clk : in  STD_LOGIC;

        usb_db : inout std_logic_vector(7 downto 0);
        usb_write : in std_logic;
        usb_astb : in std_logic;
        usb_dstb : in std_logic;
        usb_wait : out std_logic
    );
end main_file;

architecture Behavioral of main_file is

        constant address_map : addr_range_and_mapping_array := (
            address_range_and_map(
                low => std_logic_vector(to_unsigned(0, bus_address_type'length)),
                high => std_logic_vector(to_unsigned(3, bus_address_type'length))
            ),
            address_range_and_map(
                low => std_logic_vector(to_unsigned(4, bus_address_type'length))
            ));

        signal rst          : STD_LOGIC;

        signal depp2demux : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal demux2depp : bus_slv2mst_type := BUS_SLV2MST_IDLE;

        signal demux2ss   : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal ss2demux   : bus_slv2mst_type := BUS_SLV2MST_IDLE;

        signal demux2mem  : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal mem2demux  : bus_slv2mst_type := BUS_SLV2MST_IDLE;

begin

    rst <= '0';

    concurrent : process(slide_switch)
    begin
        led <= slide_switch;
    end process;

    depp_slave_controller : entity work.depp_slave_controller
    port map (
        rst => rst,
        clk => clk,
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
        demux2slv(0) => demux2ss,
        demux2slv(1) => demux2mem,
        slv2demux(0) => ss2demux,
        slv2demux(1) => mem2demux
    );


    ss : entity work.seven_seg_controller
    generic map (
        hold_count => 200000,
        digit_count => 4
    )
    port map (
        clk => clk,
        rst => rst,
        mst2slv => demux2ss,
        slv2mst => ss2demux,
        digit_anodes => seven_seg_an,
        kathode => seven_seg_kath
    );

    mem : entity work.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 11
    )
    port map (
        rst => rst,
        clk => clk,
        mst2mem => demux2mem,
        mem2mst => mem2demux
    );

end Behavioral;
