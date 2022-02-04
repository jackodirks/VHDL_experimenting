library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

entity bus_singleport_ram is
    generic (
        DEPTH_LOG2B         : natural range bus_bytes_per_word_log2b to 11
    );
    port (
        rst                 : in std_logic;
        clk                 : in std_logic;
        mst2mem             : in bus_mst2slv_type;
        mem2mst             : out bus_slv2mst_type
    );
end bus_singleport_ram;

architecture Behavioral of bus_singleport_ram is

    constant word_count : natural := 2**(DEPTH_LOG2B - bus_bytes_per_word_log2b);
    constant byte_count : natural := 2**DEPTH_LOG2B;

    signal ram : bus_byte_array(0 to byte_count - 1);
    signal mem2mst_out : bus_slv2mst_type := BUS_SLV2MST_IDLE;
begin

    sequential: process(clk, rst, mst2mem) is
        variable b : natural range 0 to bus_bytes_per_word - 1 := 0;
        variable wait_for_completion : boolean := false;
        variable active : boolean := false;
        variable ramb_addr : std_logic_vector(DEPTH_LOG2B - 1 downto 0) := (others => '0');
        variable ramb_data_out : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wait_for_completion := false;
                b := 0;
                mem2mst_out <= BUS_SLV2MST_IDLE;
            elsif wait_for_completion then
                if bus_requesting(mst2mem) = '0' then
                    b := 0;
                    mem2mst_out.ack <= '0';
                    mem2mst_out.fault <= '0';
                    wait_for_completion := false;
                end if;
            elsif active then
                mem2mst_out.readData((b+1)*bus_byte_size - 1 downto b*bus_byte_size) <= ramb_data_out;
                if b = bus_bytes_per_word - 1 then
                    mem2mst_out.ack <= '1';
                    wait_for_completion := true;
                    active := false;
                else
                    b := b + 1;
                end if;
            elsif bus_requesting(mst2mem) = '1' then
                if unsigned(mst2mem.address(bus_bytes_per_word_log2b - 1 downto 0)) /= 0 then
                    mem2mst_out.fault <= '1';
                    wait_for_completion := true;
                else
                    active := true;
                end if;
            end if;
            ramb_addr(bus_bytes_per_word_log2b - 1 downto 0) := std_logic_vector(to_unsigned(b, bus_bytes_per_word_log2b));
            ramb_addr(DEPTH_LOG2B - 1 downto bus_bytes_per_word_log2b) := mst2mem.address(DEPTH_LOG2B - 1 downto bus_bytes_per_word_log2b);

            if active then
                if (mst2mem.writeEnable and mst2mem.writeMask(b)) = '1' then
                    ram(to_integer(unsigned(ramb_addr))) <= mst2mem.writeData(b*bus_byte_size + (bus_byte_size - 1) downto b*bus_byte_size);
                end if;
                ramb_data_out := ram(to_integer(unsigned(ramb_addr)));
            end if;
        end if;
    end process;

    concurrent: process(mem2mst_out) is
    begin
        mem2mst <= mem2mst_out;
    end process;

end Behavioral;
