library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

entity bus_singleport_ram is
    generic (
        DEPTH_LOG2B         : natural range 1 to bus_data_type'length
    );
    port (
        rst                 : in std_logic;
        clk                 : in std_logic;
        mst2mem             : in bus_mst2slv_type;
        mem2mst             : out bus_slv2mst_type
    );
end bus_singleport_ram;

architecture Behavioral of bus_singleport_ram is

    constant byte_count : natural := 2**DEPTH_LOG2B;
    signal ram  : bus_byte_array(0 to 2**(DEPTH_LOG2B) - 1);
begin

    mem2mst.fault <= '0';

    sequential: process(clk, rst, mst2mem) is
        variable addr : natural range 0 to 2**bus_data_type'length - 1;
        variable act_addr : natural range 0 to byte_count - 1;
    begin
        if rising_edge(clk) then
            -- Decode address. Note that reads and writes are assumed to be word aligned.
            addr := to_integer(unsigned(mst2mem.address));
            for b in 0 to bus_bytes_per_word - 1 loop
                if (addr + b < byte_count) then
                    act_addr := addr + b;
                    if mst2mem.writeMask(b) = '1' and mst2mem.writeEnable = '1' then
                        ram(act_addr)<= mst2mem.writeData((b + 1)*bus_byte_size - 1 downto b*bus_byte_size);
                    end if;
                    mem2mst.readData((b + 1)*bus_byte_size - 1 downto b*bus_byte_size) <= ram(act_addr);
                end if;
            end loop;
            -- Handle reads
            -- Generate ack signal
            if rst = '1' then
                mem2mst.ack <= '0';
            else
                mem2mst.ack <= bus_requesting(mst2mem);
            end if;
        end if;
    end process;
end Behavioral;
