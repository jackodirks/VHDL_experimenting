library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src;
use src.bus_pkg;
use src.depp_pkg;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.sync_pkg.all;

library tb;
use tb.simulated_depp_master_pkg;

entity simulated_depp_master is
    generic (
        constant actor : actor_t;
        constant logger : logger_t := get_logger("simulated_depp_master");
        constant checker : checker_t := new_checker("simulated_depp_master checker")
    );
    port (
        usb_db : inout std_logic_vector(7 DOWNTO 0);
        usb_write : out std_logic;
        usb_astb : out std_logic;
        usb_dstb : out std_logic;
        usb_wait : in std_logic
    );
end simulated_depp_master;

architecture behavioral of simulated_depp_master is

    constant wait_low_to_astb_dstb_active : time := 40 ns;
    constant astb_dstb_active_to_db_valid : time := 20 ns;
    constant astb_dstb_inactive_to_db_invalid : time := 20 ns;

    constant depp_words_per_bus_word : natural := bus_pkg.bus_data_type'length / depp_pkg.depp_data_type'length;
    constant depp_words_per_bus_address : natural := bus_pkg.bus_address_type'length / depp_pkg.depp_data_type'length;

begin

    msg_handler : process is
        variable request_msg, reply_msg : msg_t;
        variable msg_type : msg_type_t;
        variable first_run : boolean := false;
        variable writeAddress : bus_pkg.bus_address_type;
        variable writeData : bus_pkg.bus_data_type;
        variable writeMask : bus_pkg.bus_write_mask;
        variable readAddress : bus_pkg.bus_address_type;
        variable readData : bus_pkg.bus_data_type;
        procedure write_depp_address (
            constant address : depp_pkg.depp_address_type
        ) is
        begin
            wait until usb_wait = '0';
            wait for wait_low_to_astb_dstb_active;
            usb_astb <= '0';
            wait for astb_dstb_active_to_db_valid;
            usb_db <= address;
            usb_write <= '0';
            wait until usb_wait = '1';
            usb_astb <= '1';
            wait for astb_dstb_inactive_to_db_invalid;
            usb_db <= (others => 'Z');
            usb_write <= '1';
        end procedure;

        procedure write_depp_data (
            constant data : depp_pkg.depp_data_type
        ) is
        begin
            wait until usb_wait = '0';
            wait for wait_low_to_astb_dstb_active;
            usb_dstb <= '0';
            wait for astb_dstb_active_to_db_valid;
            usb_db <= data;
            usb_write <= '0';
            wait until usb_wait = '1';
            usb_dstb <= '1';
            wait for astb_dstb_inactive_to_db_invalid;
            usb_db <= (others => 'Z');
            usb_write <= '1';
        end procedure;

        procedure read_depp_data (
            variable data : out depp_pkg.depp_data_type
        ) is
        begin
            wait until usb_wait = '0';
            wait for wait_low_to_astb_dstb_active;
            usb_dstb <= '0';
            wait until usb_wait = '1';
            data := usb_db;
            usb_dstb <= '1';
        end procedure;

        procedure setup_fast_rw is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_mode_register_start, address'length));
            data := (others => '0');
            data(depp_pkg.depp_mode_fast_write_bit) := '1';
            data(depp_pkg.depp_mode_fast_read_bit) := '1';
            write_depp_address(address);
            write_depp_data(data);
        end procedure;

        procedure write_bus_address (
            bus_address : bus_pkg.bus_address_type
        ) is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
        begin
            for i in 0 to depp_words_per_bus_address - 1 loop
                address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_addr_reg_start + i, address'length));
                data := bus_address(((i+1)*depp_pkg.depp_data_type'length) - 1 downto (i)*depp_pkg.depp_data_type'length);
                write_depp_address(address);
                write_depp_data(data);
            end loop;
        end procedure;

        procedure write_bus_mask (
            bus_mask : bus_pkg.bus_write_mask
        ) is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_write_mask_reg_start, address'length));
            data := (others => '0');
            data(bus_mask'high downto 0) := bus_mask;
            write_depp_address(address);
            write_depp_data(data);
        end procedure;

        procedure write_bus_data (
            bus_data : bus_pkg.bus_data_type
        ) is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_writeData_reg_start, address'length));
            write_depp_address(address);
            for i in 0 to depp_words_per_bus_word - 1 loop
                data := bus_data(((i+1)*depp_pkg.depp_data_type'length) - 1 downto (i)*depp_pkg.depp_data_type'length);
                write_depp_data(data);
            end loop;
        end procedure;

        procedure read_bus_data (
            variable bus_data : out bus_pkg.bus_data_type
        ) is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_readData_reg_start, address'length));
            write_depp_address(address);
            for i in 0 to depp_words_per_bus_word - 1 loop
                read_depp_data(data);
                bus_data(((i+1)*depp_pkg.depp_data_type'length) - 1 downto (i)*depp_pkg.depp_data_type'length) := data;
            end loop;
        end procedure;

    begin
        usb_db <= (others => 'Z');
        usb_write <= '1';
        usb_astb <= '1';
        usb_dstb <= '1';
        if not first_run then
            first_run := true;
            setup_fast_rw;
        end if;
        receive(net, actor, request_msg);
        msg_type := message_type(request_msg);
        handle_sync_message(net, msg_type, request_msg);

        if msg_type = simulated_depp_master_pkg.write_toAddress_msg then
            writeAddress := pop(request_msg);
            writeData := pop(request_msg);
            writeMask := pop(request_msg);
            write_bus_address(writeAddress);
            write_bus_mask(writeMask);
            write_bus_data(writeData);
            acknowledge(net, request_msg, true);
        elsif msg_type = simulated_depp_master_pkg.read_fromAddress_msg then
            readAddress := pop(request_msg);
            write_bus_address(readAddress);
            read_bus_data(readData);
            reply_msg := new_msg(simulated_depp_master_pkg.read_reply_msg);
            push(reply_msg, readData);
            reply(net, request_msg, reply_msg);
        else
            unexpected_msg_type(msg_type);
        end if;
    end process;
end architecture;
