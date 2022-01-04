library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.bus_pkg.all;
use work.depp_pkg.all;

entity depp_to_bus is
    port (
        rst     : in std_logic;
        clk     : in std_logic;

        depp2bus : in depp2bus_type;
        bus2depp : out bus2depp_type;

        slv2mst  : in bus_slv2mst_type;
        mst2slv  : out bus_mst2slv_type
    );
end depp_to_bus;

architecture behaviourial of depp_to_bus is
    subtype reg_type is std_logic_vector(7 downto 0);
    type reg_type_array is array (natural range <>) of reg_type;

    constant data_reg_start : natural := bus_address_type'length/8;
    constant write_mask_start : natural := data_reg_start + bus_data_type'length/8;
    constant fault_register_start : natural := write_mask_start;
    constant activation_register_start : natural := write_mask_start + natural(ceil(real(bus_write_mask'length)/real(8)));

    signal mst2slv_out : bus_mst2slv_type := BUS_MST2SLV_IDLE;
    signal slv2mst_cpy : bus_slv2mst_type := BUS_SLV2MST_IDLE;
    signal bus2depp_out : bus2depp_type := BUS2DEPP_IDLE;
begin

    sequential : process(clk)
        variable bus_active : boolean := false;
        variable address : natural range 0 to 2**8 - 1;
        variable write_endpoint : natural range 0 to 2**8 - 1;
    begin
        if rising_edge(clk) then

            -- Decode address
            address := to_integer(unsigned(depp2bus.address));

            if rst = '1' then
                mst2slv_out <= BUS_MST2SLV_IDLE;
                bus2depp_out <= BUS2DEPP_IDLE;
                slv2mst_cpy <= BUS_SLV2MST_IDLE;
                bus_active := false;
            elsif bus_active then
                if bus_slave_finished(slv2mst) then
                    bus_active := false;
                    mst2slv_out.readEnable <= '0';
                    mst2slv_out.writeEnable <= '0';
                    slv2mst_cpy <= slv2mst;
                end if;
            elsif depp2bus.writeEnable = true then
                if address < data_reg_start then
                    mst2slv_out.address(8*(address + 1) - 1 downto 8*address) <= depp2bus.writeData;
                elsif address < write_mask_start then
                    address := address - data_reg_start;
                    mst2slv_out.writeData(8*(address + 1) - 1 downto 8*address) <= depp2bus.writeData;
                elsif address < activation_register_start then
                    address := address - write_mask_start;
                    write_endpoint := 8*(address + 1) - 1;
                    if write_endpoint > bus_write_mask'high then
                        write_endpoint := bus_write_mask'high;
                    end if;
                    mst2slv_out.writeMask(write_endpoint downto 8*address) <= depp2bus.writeData(write_endpoint - 8*address downto 0);
                elsif address = activation_register_start then
                    mst2slv_out.writeEnable <= '1';
                    for i in 0 to depp2bus.writeData'high loop
                        if depp2bus.writeData(i) = '1' then
                            mst2slv_out.writeEnable <= '0';
                            mst2slv_out.readEnable <= '1';
                        end if;
                    end loop;
                    bus_active := true;
                end if;
            elsif depp2bus.readEnable = true then
                if address < data_reg_start then
                    bus2depp_out.readData <= mst2slv_out.address(8*(address + 1) - 1 downto 8*address);
                elsif address < fault_register_start then
                    address := address - data_reg_start;
                    bus2depp_out.readData <= slv2mst_cpy.readData(8*(address + 1) - 1 downto 8*address);
                elsif address = fault_register_start then
                    bus2depp_out.readData(0) <= slv2mst_cpy.fault;
                end if;
            end if;

            bus2depp_out.done <= not bus_active and (depp2bus.writeEnable = true or depp2bus.readEnable = true) and rst = '0';
        end if;
    end process;

    concurrent : process(mst2slv_out, bus2depp_out)
    begin
        mst2slv <= mst2slv_out;
        bus2depp <= bus2depp_out;
    end process;

end behaviourial;
