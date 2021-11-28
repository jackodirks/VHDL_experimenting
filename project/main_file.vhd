library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bus_pkg.all;

entity main_file is
    Port (
        --JA_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JB_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JC_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        --JD_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        slide_switch : in  STD_LOGIC_VECTOR (7 downto 0);
        push_button : in  STD_LOGIC_VECTOR (3 downto 0);
        led : out  STD_LOGIC_VECTOR (7 downto 0);
        --seven_seg_kath : out  STD_LOGIC_VECTOR (7 downto 0);
        --seven_seg_an : out  STD_LOGIC_VECTOR (3 downto 0);
        clk : in  STD_LOGIC;

        usb_db : inout std_logic_vector(7 downto 0);
        usb_write : in std_logic;
        usb_astb : in std_logic;
		  usb_dstb : in std_logic;
        usb_wait : out std_logic
    );
end main_file;

architecture Behavioral of main_file is
        signal rst          : STD_LOGIC;
        signal depp2mem : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        signal mem2depp : bus_slv2mst_type := BUS_SLV2MST_IDLE;
begin

    rst <= '0';

    concurrent : process(slide_switch, push_button)
    begin
        led <= slide_switch;
    end process;

    depp_slave : entity work.depp_slave
    port map (
        rst => rst,
        clk => clk,
        mst2slv => depp2mem,
        slv2mst => mem2depp,
        USB_DB => usb_db,
        USB_WRITE => usb_write,
        USB_ASTB => usb_astb,
        USB_DSTB => usb_dstb,
        USB_WAIT => usb_wait
    );

    mem : entity work.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 8
    )
    port map (
        rst => rst,
        clk => clk,
        mst2mem => depp2mem,
        mem2mst => mem2depp
    );

end Behavioral;
