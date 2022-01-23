library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bus_pkg.all;
use work.depp_pkg.all;

entity depp_slave_controller is
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Bus connection
        slv2mst : in bus_slv2mst_type;
        mst2slv : out bus_mst2slv_type;

        -- Physical USB/DEPP connection
        USB_DB        : inout STD_LOGIC_VECTOR(7 DOWNTO 0);
        USB_WRITE     : in STD_LOGIC;
        USB_ASTB      : in STD_LOGIC;
        USB_DSTB      : in STD_LOGIC;
        USB_WAIT      : out STD_LOGIC
    );
end depp_slave_controller;

architecture behavioural of depp_slave_controller is
    signal depp2bus : depp2bus_type;
    signal bus2depp : bus2depp_type;
begin

    depp_slave : entity work.depp_slave
    port map (
        clk => clk,
        rst => rst,
        depp2bus => depp2bus,
        bus2depp => bus2depp,
        USB_DB => USB_DB,
        USB_WRITE => USB_WRITE,
        USB_ASTB => USB_ASTB,
        USB_DSTB => USB_DSTB,
        USB_WAIT => USB_WAIT
    );

    depp_to_bus : entity work.depp_to_bus
    port map (
        clk => clk,
        rst => rst,
        bus2depp => bus2depp,
        depp2bus => depp2bus,
        slv2mst => slv2mst,
        mst2slv => mst2slv
    );
end behavioural;
