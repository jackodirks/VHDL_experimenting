library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

entity bus_singleport_ram is
    generic (
        DEPTH_LOG2B         : natural range 1 to 8
    );
    port (
        rst                 : in std_logic;
        clk                 : in std_logic;
        mst2mem             : in bus_mst2slv_type;
        mem2mst             : out bus_slv2mst_type
    );
end bus_singleport_ram;

architecture Behavioral of bus_singleport_ram is
    subtype ram_element is std_logic_vector(7 downto 0);
    type ram_element_array is array (natural range <>) of ram_element;

    signal ram  : ram_element_array(0 to 2**(DEPTH_LOG2B) - 1);
begin

    sequential: process(clk, rst, mst2mem) is
        variable addr : natural range 0 to 2**DEPTH_LOG2B - 1;
    begin
        if rising_edge(clk) then
            -- Decode address
            addr := to_integer(unsigned(mst2mem.address(DEPTH_LOG2B-1 downto 0)));
            -- Handle writes
            if mst2mem.writeEnable = '1' then
                ram(addr) <= mst2mem.writeData;
            end if;
            -- Handle reads
            mem2mst.readData <= ram(addr);
            -- Generate ack signal
            if rst = '1' then
                mem2mst.ack <= '0';
            else
                mem2mst.ack <= bus_requesting(mst2mem);
            end if;
        end if;
    end process;
end Behavioral;
