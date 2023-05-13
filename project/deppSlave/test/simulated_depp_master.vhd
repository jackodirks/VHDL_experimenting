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
        variable first_run : boolean := true;
        variable writeAddress : bus_pkg.bus_address_type;
        variable writeData : bus_pkg.bus_data_type;
        variable writeMask : bus_pkg.bus_write_mask;
        variable readAddress : bus_pkg.bus_address_type;
        variable readData : bus_pkg.bus_data_type;
        variable faultData : bus_pkg.bus_fault_type;
        variable faultAddress : bus_pkg.bus_address_type;
        variable requestSize : natural;
        procedure write_depp_address (
            constant address : depp_pkg.depp_address_type
        ) is
        begin
            if usb_wait /= '0' then
                wait until usb_wait = '0';
            end if;
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
            if usb_wait /= '0' then
                wait until usb_wait = '0';
            end if;
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
            if usb_wait /= '0' then
                wait until usb_wait = '0';
            end if;
            wait for wait_low_to_astb_dstb_active;
            usb_dstb <= '0';
            wait until usb_wait = '1';
            data := usb_db;
            usb_dstb <= '1';
        end procedure;

        procedure prepare_first_run is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
            variable expData : depp_pkg.depp_data_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_faultData_reg_start, address'length));
            write_depp_address(address);
            data := (others => '0');
            write_depp_data(data);
            for i in 0 to depp_words_per_bus_address - 1 loop
                write_depp_data(data);
            end loop;
        end procedure;

        procedure set_depp_addres_to_writeMask_start is
            variable address : depp_pkg.depp_address_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_writeMask_reg_start, address'length));
            write_depp_address(address);
        end procedure;

        procedure prepare_bus_transaction (
            constant bus_mask : bus_pkg.bus_write_mask;
            constant bus_address : bus_pkg.bus_address_type;
            constant burstLength : natural range 0 to 255
        ) is
            variable data : depp_pkg.depp_data_type := (others => '0');
        begin
            data := (others => '0');
            data(bus_mask'high downto 0) := bus_mask;
            write_depp_data(data);
            data := std_logic_vector(to_unsigned(burstLength, data'length));
            write_depp_data(data);
            for i in 0 to depp_words_per_bus_address - 1 loop
                data := bus_address(((i+1)*depp_pkg.depp_data_type'length) - 1 downto (i)*depp_pkg.depp_data_type'length);
                write_depp_data(data);
            end loop;
        end procedure;

        procedure update_burstLength_move_to_rw (
            constant burstLength : natural range 0 to 255
        ) is
            variable address : depp_pkg.depp_address_type;
            variable data : depp_pkg.depp_data_type;
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_burstLength_reg_start, address'length));
            write_depp_address(address);
            data := std_logic_vector(to_unsigned(0, data'length));
            write_depp_data(data);
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_readWrite_reg_start, address'length));
            write_depp_address(address);
        end procedure;

        procedure transaction_epilogue (
            variable bus_faultData : out bus_pkg.bus_fault_type;
            variable bus_faultAddress : out bus_pkg.bus_address_type
        ) is
            variable faultData_internal : bus_pkg.bus_fault_type := (others => '0');
            variable data : depp_pkg.depp_data_type := (others => '0');
            variable address : depp_pkg.depp_address_type := (others => '0');
        begin
            address := std_logic_vector(to_unsigned(depp_pkg.depp2bus_faultData_reg_start, address'length));
            write_depp_address(address);
            read_depp_data(data);
            faultData_internal := data(faultData_internal'range);
            bus_faultData := faultData_internal;
            for i in 0 to depp_words_per_bus_address - 1 loop
                read_depp_data(data);
                bus_faultAddress(((i+1)*depp_pkg.depp_data_type'length) - 1 downto (i)*depp_pkg.depp_data_type'length) := data;
            end loop;
            if faultData_internal /= bus_pkg.bus_fault_no_fault then
                prepare_first_run;
            end if;
        end procedure;

        procedure write_bus_data (
            constant bus_data : bus_pkg.bus_data_type
        ) is
            variable data : depp_pkg.depp_data_type;
        begin
            for i in 0 to depp_words_per_bus_word - 1 loop
                data := bus_data(((i+1)*depp_pkg.depp_data_type'length) - 1 downto (i)*depp_pkg.depp_data_type'length);
                write_depp_data(data);
            end loop;
        end procedure;

        procedure read_bus_data (
            variable bus_data : out bus_pkg.bus_data_type
        ) is
            variable data : depp_pkg.depp_data_type;
        begin
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
        if first_run then
            first_run := false;
            prepare_first_run;
        end if;
        receive(net, actor, request_msg);
        msg_type := message_type(request_msg);
        handle_sync_message(net, msg_type, request_msg);

        if msg_type = simulated_depp_master_pkg.write_toAddress_msg then
            writeAddress := pop(request_msg);
            writeData := pop(request_msg);
            writeMask := pop(request_msg);
            prepare_bus_transaction (
                bus_mask => writeMask,
                bus_address => writeAddress,
                burstLength => 0);
            write_bus_data(writeData);
            transaction_epilogue(bus_faultData => faultData,
                                 bus_faultAddress => faultAddress);
            if faultData = bus_pkg.bus_fault_no_fault then
                reply_msg := new_msg(simulated_depp_master_pkg.write_reply_msg);
                reply(net, request_msg, reply_msg);
            else
                reply_msg := new_msg(simulated_depp_master_pkg.fault_reply_msg);
                push(reply_msg, faultData);
                push(reply_msg, faultAddress);
                reply(net, request_msg, reply_msg);
            end if;
        elsif msg_type = simulated_depp_master_pkg.write_multipleToAddress_msg then
            writeMask := pop(request_msg);
            writeAddress := pop(request_msg);
            requestSize := pop(request_msg);
            prepare_bus_transaction (
                bus_mask => writeMask,
                bus_address => writeAddress,
                burstLength => 0);
            while requestSize > 256 loop
                update_burstLength_move_to_rw(burstLength => 255);
                for i in 0 to 255 loop
                    writeData := pop(request_msg);
                    write_bus_data(writeData);
                end loop;
                requestSize := requestSize - 256;
            end loop;
            update_burstLength_move_to_rw(burstLength => requestSize - 1);
            for i in 0 to requestSize - 1 loop
                writeData := pop(request_msg);
                write_bus_data(writeData);
            end loop;
            transaction_epilogue(bus_faultData => faultData,
                                 bus_faultAddress => faultAddress);
            if faultData = bus_pkg.bus_fault_no_fault then
                reply_msg := new_msg(simulated_depp_master_pkg.write_reply_msg);
                reply(net, request_msg, reply_msg);
            else
                reply_msg := new_msg(simulated_depp_master_pkg.fault_reply_msg);
                push(reply_msg, faultData);
                push(reply_msg, faultAddress);
                reply(net, request_msg, reply_msg);
            end if;
        elsif msg_type = simulated_depp_master_pkg.read_fromAddress_msg then
            readAddress := pop(request_msg);
            writeMask := (others => '1');
            prepare_bus_transaction (
                bus_mask => writeMask,
                bus_address => readAddress,
                burstLength => 0);
            read_bus_data(readData);
            transaction_epilogue(bus_faultData => faultData,
                                 bus_faultAddress => faultAddress);
            if faultData = bus_pkg.bus_fault_no_fault then
                reply_msg := new_msg(simulated_depp_master_pkg.read_reply_msg);
                push(reply_msg, readData);
                reply(net, request_msg, reply_msg);
            else
                reply_msg := new_msg(simulated_depp_master_pkg.fault_reply_msg);
                push(reply_msg, faultData);
                push(reply_msg, faultAddress);
                reply(net, request_msg, reply_msg);
            end if;
        elsif msg_type = simulated_depp_master_pkg.read_multipleFromAddress_msg then
            readAddress := pop(request_msg);
            requestSize := pop(request_msg);
            writeMask := (others => '1');
            reply_msg := new_msg(simulated_depp_master_pkg.read_reply_msg);
            prepare_bus_transaction (
                bus_mask => writeMask,
                bus_address => readAddress,
                burstLength => 0);
            while requestSize > 256 loop
                update_burstLength_move_to_rw(burstLength => 255);
                for i in 0 to 255 loop
                    read_bus_data(readData);
                    push(reply_msg, readData);
                end loop;
                requestSize := requestSize - 256;
            end loop;
            update_burstLength_move_to_rw(burstLength => requestSize - 1);
            for i in 0 to requestSize - 1 loop
                read_bus_data(readData);
                push(reply_msg, readData);
            end loop;
            transaction_epilogue(bus_faultData => faultData,
                                 bus_faultAddress => faultAddress);
            if faultData = bus_pkg.bus_fault_no_fault then
                reply(net, request_msg, reply_msg);
            else
                reply_msg := new_msg(simulated_depp_master_pkg.fault_reply_msg);
                push(reply_msg, faultData);
                push(reply_msg, faultAddress);
                reply(net, request_msg, reply_msg);
            end if;
        else
            unexpected_msg_type(msg_type);
        end if;
    end process;
end architecture;
