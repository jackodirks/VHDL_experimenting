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
        usb_db        : inout std_logic_vector(7 downto 0);
        usb_write     : in std_logic;
        usb_astb      : in std_logic;
        usb_dstb      : in std_logic;
        usb_wait      : out std_logic
    );
end depp_slave_controller;

architecture behaviourial of depp_slave_controller is
    signal address_request : boolean := false;
    signal data_request : boolean := false;
begin

    delay_request : process(clk)
    begin
        -- We are crossing clock domains. Therefore, if either of these is high, other signals might still be settling.
        -- Therefore, delay these by one cycle so that by the time interpretation starts, everything has settled.
        if rising_edge(clk) then
            if usb_astb = '0' then
                address_request <= true;
            else
                address_request <= false;
            end if;
            if usb_dstb = '0' then
                data_request <= true;
            else
                data_request <= false;
            end if;
        end if;
    end process;

    process(clk)
        variable usb_wait_internal : std_logic := '1';
        variable usb_db_internal : std_logic_vector(usb_db'range) := (others => 'Z');
        variable mst2slv_internal : bus_mst2slv_type := BUS_MST2SLV_IDLE;

        variable wait_for_deppMaster_completion : boolean := true;
        variable prevent_deppSlave_completion : boolean := false;
        variable depp_write_request : boolean := false;
        variable depp_address : natural range 0 to 255 := 0;
        variable depp_selected_register : selected_request_register_type := reqReg_none;
        variable depp_address_relative : natural range 0 to 255 := 0;

        variable burstActive : boolean := false;
        variable faultData : bus_fault_type := bus_fault_no_fault;
        variable faultAddress : bus_address_type := (others => '0');
        variable readData : bus_data_type := (others => '0');
        variable writeData : bus_data_type := (others => '0');
        variable writeMask : bus_write_mask_type := (others => '0');
        variable burstLength : natural range 0 to 255 := 0;
        variable bus_address : bus_address_type := (others => '0');
    begin
        if rising_edge(clk) then
            if usb_write = '0' then
                depp_write_request := true;
            else
                depp_write_request := false;
            end if;

            if rst = '1' then
                usb_wait_internal := '0';
                usb_db_internal := (others => 'Z');
                mst2slv_internal := BUS_MST2SLV_IDLE;
            elsif bus_requesting(mst2slv_internal) then
                if fault_transaction(mst2slv_internal, slv2mst) then
                    faultData := slv2mst.faultData;
                    faultAddress := mst2slv_internal.address;
                    mst2slv_internal := BUS_MST2SLV_IDLE;
                elsif read_transaction(mst2slv_internal, slv2mst) then
                    readData := slv2mst.readData;
                    mst2slv_internal := BUS_MST2SLV_IDLE;
                    if burstActive then
                        mst2slv_internal.burst := '1';
                    end if;
                elsif write_transaction(mst2slv_internal, slv2mst) then
                    mst2slv_internal := BUS_MST2SLV_IDLE;
                    if burstActive then
                        mst2slv_internal.burst := '1';
                    end if;
                end if;
            elsif wait_for_deppMaster_completion then
                usb_wait_internal := '1';
                if not address_request and not data_request then
                    usb_wait_internal := '0';
                    wait_for_deppMaster_completion := false;
                    usb_db_internal := (others => 'Z');
                end if;
            elsif address_request then
                if depp_write_request then
                    depp_address := to_integer(unsigned(usb_db));
                    decode_request_register(depp_address, depp_selected_register, depp_address_relative);
                else
                    usb_db_internal := std_logic_vector(to_unsigned(depp_address, usb_db_internal'length));
                end if;
                usb_wait_internal := '1';
                wait_for_deppMaster_completion := true;
            elsif data_request then
                if depp_write_request then
                    case depp_selected_register is
                        when reqReg_faultData =>
                            faultData := usb_db(faultData'range);
                        when reqReg_faultAddress =>
                            faultAddress((depp_address_relative + 1)*depp_data_type'length - 1 downto depp_address_relative*depp_data_type'length) := usb_db;
                        when reqReg_writeMask =>
                            writeMask := usb_db(writeMask'range);
                        when reqReg_burstLength =>
                            burstLength := to_integer(unsigned(usb_db));
                        when reqReg_address =>
                            bus_address((depp_address_relative + 1)*depp_data_type'length - 1 downto depp_address_relative*depp_data_type'length) := usb_db;
                        when reqReg_readWrite =>
                            writeData((depp_address_relative + 1)*depp_data_type'length - 1 downto depp_address_relative*depp_data_type'length) := usb_db;
                            if depp_address_relative = depp_words_per_bus_word - 1 then
                                mst2slv_internal := bus_mst2slv_write(address => bus_address,
                                                                      write_data => writeData,
                                                                      write_mask => writeMask);
                                if burstLength > 0 then
                                    burstActive := true;
                                    mst2slv_internal.burst := '1';
                                    burstLength := burstLength - 1;
                                else
                                    burstActive := false;
                                end if;
                               bus_address := incremented_bus_address(bus_address);
                            end if;
                        when reqReg_none =>
                    end case;
                else
                    usb_db_internal := (others => '0');
                    case depp_selected_register is
                        when reqReg_faultData =>
                            usb_db_internal(faultData'range) := faultData;
                        when reqReg_faultAddress =>
                            usb_db_internal := faultAddress(depp_address_relative*depp_data_type'length + (depp_data_type'length - 1) downto depp_address_relative*depp_data_type'length);
                        when reqReg_writeMask =>
                            usb_db_internal(writeMask'range) := writeMask;
                        when reqReg_burstLength =>
                            usb_db_internal := std_logic_vector(to_unsigned(burstLength, usb_db_internal'length));
                        when reqReg_address =>
                            usb_db_internal := bus_address(depp_address_relative*depp_data_type'length + (depp_data_type'length - 1) downto depp_address_relative*depp_data_type'length);
                        when reqReg_readWrite =>
                            if depp_address_relative = 0 and not prevent_deppSlave_completion then
                                mst2slv_internal := bus_mst2slv_read(address => bus_address);
                                if burstLength > 0 then
                                    burstActive := true;
                                    mst2slv_internal.burst := '1';
                                    burstLength := burstLength - 1;
                                else
                                    burstActive := false;
                                end if;
                                prevent_deppSlave_completion := true;
                                bus_address := incremented_bus_address(bus_address);
                            else
                                prevent_deppSlave_completion := false;
                                usb_db_internal := readData(depp_address_relative*depp_data_type'length + (depp_data_type'length - 1) downto depp_address_relative*depp_data_type'length);
                            end if;
                        when reqReg_none =>
                    end case;
                end if;
                if not prevent_deppSlave_completion then
                    usb_wait_internal := '1';
                    wait_for_deppMaster_completion := true;
                    if depp_address = depp2bus_readWrite_reg_end then
                        depp_address := depp2bus_readWrite_reg_start;
                    elsif depp_selected_register /= reqReg_none then
                        depp_address := depp_address + 1;
                    end if;
                    decode_request_register(depp_address, depp_selected_register, depp_address_relative);
                end if;
            end if;
        end if;
        usb_wait <= usb_wait_internal;
        usb_db <= usb_db_internal;
        mst2slv <= mst2slv_internal;
    end process;
end behaviourial;
