library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

architecture behaviourial of depp_slave_controller is
    signal usb_astb_delayed : std_logic;
    signal usb_dstb_delayed : std_logic;
    signal mst2slv_out : bus_mst2slv_type := BUS_MST2SLV_IDLE;
begin

    sequential : process(clk)
        variable wait_dstb_finish : boolean := false;
        variable address : natural range 0 to 2**8 - 1;
        variable address_tmp : natural range 0 to 2**8 - 1;
        variable read_latch : depp_data_type := (others => '0');

        variable bus_active : boolean := false;
        variable reread : boolean := false;
        variable write_mask_reg : std_logic_vector(depp2bus_write_mask_length_ceil*8 - 1 downto 0) := (others => '0');
        variable slv2mst_cpy : bus_slv2mst_type := BUS_SLV2MST_IDLE;

        variable depp_mode : depp_data_type := (others => '0');

        variable next_bus_address : bus_address_type := (others => '0');
    begin
        if rising_edge(clk) then

            -- We are crossing clock domains. Therefore, if either of these is high, other signals might still be settling.
            -- Therefore, delay these by one cycle so that by the time interpretation starts, everything has settled.
            usb_astb_delayed <= USB_ASTB;
            usb_dstb_delayed <= USB_DSTB;

            USB_WAIT <= '0';
            USB_DB <= (others => 'Z');
            if rst = '1' then
                USB_WAIT <= '1';
                wait_dstb_finish := false;
                mst2slv_out <= BUS_MST2SLV_IDLE;
                slv2mst_cpy := BUS_SLV2MST_IDLE;
                write_mask_reg := (others => '0');
                bus_active := false;
                address := 0;
            else
                if bus_active then
                    if bus_slave_finished(slv2mst) = '1' then
                        bus_active := false;
                        mst2slv_out.writeEnable <= '0';
                        mst2slv_out.readEnable <= '0';
                        mst2slv_out.address <= next_bus_address;
                        wait_dstb_finish := true;
                        slv2mst_cpy := slv2mst;
                        if reread then
                            read_latch := slv2mst_cpy.readData(7 downto 0);
                            reread := false;
                        end if;
                    end if;
                elsif usb_astb_delayed = '0' then
                    USB_WAIT <= '1';
                    if USB_WRITE = '0' then
                        address := to_integer(unsigned(USB_DB));
                    elsif USB_WRITE = '1' then
                        USB_DB <= std_logic_vector(to_unsigned(address, usb_db'length));
                    end if;
                elsif usb_dstb_delayed = '0' and wait_dstb_finish = false then
                    wait_dstb_finish := true;

                    if USB_WRITE = '0' then
                        if address <= depp2bus_addr_reg_end then
                            address_tmp := address - depp2bus_addr_reg_start;
                            mst2slv_out.address(8*(address_tmp + 1) - 1 downto 8*address_tmp) <= usb_db;
                        elsif address <= depp2bus_writeData_reg_end then
                            address_tmp := address - depp2bus_writeData_reg_start;
                            mst2slv_out.writeData(8*(address_tmp + 1) - 1 downto 8*address_tmp) <= usb_db;
                            if depp_mode_fast_write_active(depp_mode) then
                                address := address + 1;
                                if address > depp2bus_writeData_reg_end then
                                    next_bus_address := std_logic_vector(to_unsigned(
                                                        to_integer(unsigned(mst2slv_out.address)) + depp2bus_addr_reg_len,
                                                        next_bus_address'length));
                                    address := depp2bus_writeData_reg_start;
                                    mst2slv_out.writeEnable <= '1';
                                    bus_active := true;
                                    wait_dstb_finish := false;
                                end if;
                            end if;
                        elsif address <= depp2bus_write_mask_reg_end then
                            address_tmp := address - depp2bus_write_mask_reg_start;
                            write_mask_reg(8*(address_tmp + 1) - 1 downto 8*address_tmp) := usb_db;
                            mst2slv_out.writeMask <= write_mask_reg(mst2slv_out.writeMask'range);
                        elsif address <= depp2bus_mode_register_end then
                            depp_mode := usb_db;
                        elsif address <= depp2bus_activation_register_end then
                            next_bus_address := mst2slv_out.address;
                            mst2slv_out.writeEnable <= '1';
                            for i in 0 to usb_db'high loop
                                if usb_db(i) = '1' then
                                    mst2slv_out.writeEnable <= '0';
                                    mst2slv_out.readEnable <= '1';
                                end if;
                            end loop;
                            bus_active := true;
                            wait_dstb_finish := false;
                        end if;
                    elsif USB_WRITE = '1' then
                        read_latch := (others => '0');
                        if address <= depp2bus_addr_reg_end then
                            address_tmp := address - depp2bus_addr_reg_start;
                            read_latch := mst2slv_out.address(8*address_tmp + 7 downto 8*address_tmp);
                        elsif address <= depp2bus_writeData_reg_end then
                            address_tmp := address - depp2bus_writeData_reg_start;
                            read_latch := mst2slv_out.writeData(8*address_tmp + 7 downto 8*address_tmp);
                        elsif address <= depp2bus_readData_reg_end then
                            address_tmp := address - depp2bus_readData_reg_start;
                            if depp_mode_fast_read_active(depp_mode) then
                                if address = depp2bus_readData_reg_start then
                                    next_bus_address := std_logic_vector(to_unsigned(
                                                        to_integer(unsigned(mst2slv_out.address)) + depp2bus_addr_reg_len,
                                                        next_bus_address'length));
                                    mst2slv_out.readEnable <= '1';
                                    bus_active := true;
                                    wait_dstb_finish := false;
                                    reread := true;
                                end if;
                                address := address + 1;
                                if address > depp2bus_readData_reg_end then
                                    address := depp2bus_readData_reg_start;
                                end if;
                            end if;
                            read_latch := slv2mst_cpy.readData(8*address_tmp + 7 downto 8*address_tmp);
                        elsif address <= depp2bus_write_mask_reg_end then
                            address_tmp := address - depp2bus_write_mask_reg_start;
                            read_latch := write_mask_reg(8*(address_tmp + 1) - 1 downto 8*address_tmp);
                        elsif address <= depp2bus_mode_register_end then
                            read_latch := depp_mode;
                        elsif address <= depp2bus_fault_register_end then
                            read_latch := (others => '0');
                            read_latch(0) := slv2mst_cpy.fault;
                        end if;
                    end if;
                end if;

                if usb_dstb_delayed = '0' and usb_write = '1' then
                    usb_db <= read_latch;
                end if;

                if wait_dstb_finish then
                    if usb_dstb_delayed = '1' then
                        wait_dstb_finish := false;
                    else
                        USB_WAIT <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;


    concurrent : process(mst2slv_out)
    begin
        mst2slv <= mst2slv_out;
    end process;

end behaviourial;
