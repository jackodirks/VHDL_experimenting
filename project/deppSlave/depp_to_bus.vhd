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
    constant write_mask_length_ceil : natural := natural(ceil(real(bus_write_mask'length)/real(8)));

    -- All registers are defined as inclusive start, inclusive end.
    -- First the common registers, addr and data are available to both read and write
    constant addr_reg_start : natural := 0;
    constant addr_reg_len : natural := bus_address_type'length/8;
    constant addr_reg_end : natural := addr_reg_start + addr_reg_len - 1;
    constant data_reg_start : natural := addr_reg_start + addr_reg_len;
    constant data_reg_len : natural := bus_data_type'length/8;
    constant data_reg_end : natural := data_reg_start + data_reg_len - 1;
    -- Write mask only exists from the perspective of the writer and shares its address with the fault register
    constant write_mask_start : natural := data_reg_start + data_reg_len;
    constant write_mask_len : natural := write_mask_length_ceil;
    constant write_mask_end : natural := write_mask_start + write_mask_len - 1;
    -- Fault register only exists from the perspective of the reader and shares its address with the write mask
    -- The fault register has a length of 1 byte.
    constant fault_register_start : natural := write_mask_start;
    constant fault_register_end : natural := fault_register_start;
    -- The activation register only exists from the perspective of the writer. It is always exactly one byte.
    constant activation_register_start : natural := write_mask_start + write_mask_length_ceil;
    constant activation_register_end : natural := activation_register_start;

    signal bus2depp_out : bus2depp_type := BUS2DEPP_IDLE;
    signal mst2slv_out : bus_mst2slv_type := BUS_MST2SLV_IDLE;

begin

    sequential : process(clk)
        variable bus_active : boolean := false;
        variable wait_for_completion : boolean := false;
        variable address : natural range 0 to 2**8 - 1;
        variable write_mask_reg : std_logic_vector(write_mask_length_ceil*8 - 1 downto 0) := (others => '0');
        variable slv2mst_cpy : bus_slv2mst_type := BUS_SLV2MST_IDLE;
    begin
        if rising_edge(clk) then

            -- Decode address
            address := to_integer(unsigned(depp2bus.address));

            if rst = '1' then
                bus2depp_out <= BUS2DEPP_IDLE;
                mst2slv_out <= BUS_MST2SLV_IDLE;
                slv2mst_cpy := BUS_SLV2MST_IDLE;
                write_mask_reg := (others => '0');
                bus_active := false;
                wait_for_completion := false;
            else
                if bus_active then
                    if bus_slave_finished(slv2mst) = '1' then
                        bus_active := false;
                        mst2slv_out.writeEnable <= '0';
                        mst2slv_out.readEnable <= '0';
                        wait_for_completion := true;
                        slv2mst_cpy := slv2mst;
                    end if;
                elsif wait_for_completion then
                    wait_for_completion := false;
                elsif depp2bus.writeEnable = true then
                    if address <= addr_reg_end then
                        address := address - addr_reg_start;
                        mst2slv_out.address(8*(address + 1) - 1 downto 8*address) <= depp2bus.writeData;
                        wait_for_completion := true;
                    elsif address <= data_reg_end then
                        address := address - data_reg_start;
                        mst2slv_out.writeData(8*(address + 1) - 1 downto 8*address) <= depp2bus.writeData;
                        wait_for_completion := true;
                    elsif address <= write_mask_end then
                        address := address - write_mask_start;
                        write_mask_reg(8*(address + 1) - 1 downto 8*address) := depp2bus.writeData;
                        mst2slv_out.writeMask <= write_mask_reg(mst2slv_out.writeMask'range);
                        wait_for_completion := true;
                    elsif address <= activation_register_end then
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
                    if address <= addr_reg_end then
                        address := address - addr_reg_start;
                        bus2depp_out.readData <= mst2slv_out.address(8*address + 7 downto 8*address);
                        wait_for_completion := true;
                    elsif address <= data_reg_end then
                        address := address - data_reg_start;
                        bus2depp_out.readData <= slv2mst_cpy.readData(8*address + 7 downto 8*address);
                        wait_for_completion := true;
                    elsif address = fault_register_start then
                        bus2depp_out.readData(0) <= slv2mst_cpy.fault;
                        wait_for_completion := true;
                    end if;
                end if;
                bus2depp_out.done <= (depp2bus.writeEnable or depp2bus.readEnable) and wait_for_completion;
            end if;
        end if;
    end process;

    concurrent : process(bus2depp_out, mst2slv_out)
    begin
        mst2slv <= mst2slv_out;
        bus2depp <= bus2depp_out;
    end process;

end behaviourial;
