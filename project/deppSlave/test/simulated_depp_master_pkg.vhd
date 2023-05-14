library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

library src;
use src.bus_pkg;

package simulated_depp_master_pkg is
    constant read_reply_msg : msg_type_t := new_msg_type("read reply");
    constant write_reply_msg : msg_type_t := new_msg_type("write reply");
    constant fault_reply_msg : msg_type_t := new_msg_type("fault reply");

    constant read_fromAddress_msg : msg_type_t := new_msg_type("read from address");
    constant read_multipleFromAddress_msg : msg_type_t := new_msg_type("read from address");
    constant write_toAddress_msg : msg_type_t := new_msg_type("write to address");
    constant write_multipleToAddress_msg : msg_type_t := new_msg_type("write multiple to address");

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_type;
              constant mask : in bus_pkg.bus_write_mask_type);

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_array;
              constant mask : in bus_pkg.bus_write_mask_type);

    procedure write_to_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_type;
              constant mask : in bus_pkg.bus_write_mask_type;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type);

    procedure write_to_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_array;
              constant mask : in bus_pkg.bus_write_mask_type;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type);

    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_type);

    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_array);

    procedure read_from_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_type;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type);

    procedure read_from_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_array;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type);

    procedure write_file_to_address (
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              constant fileName : in string);

end package;

package body simulated_depp_master_pkg is
    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_type;
              constant mask : in bus_pkg.bus_write_mask_type) is
        variable msg : msg_t := new_msg(write_toAddress_msg);
        variable msg_type : msg_type_t;
        variable reply_msg : msg_t;
        variable faultData : bus_pkg.bus_fault_type;
        variable faultAddress : bus_pkg.bus_address_type;
    begin
        push(msg, addr);
        push(msg, data);
        push(msg, mask);
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = write_reply_msg then
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
            check(false, "Write returned an error " & to_hstring(faultData) & " at address " & to_hstring(faultAddress));
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_array;
              constant mask : in bus_pkg.bus_write_mask_type) is
        variable msg : msg_t := new_msg(write_multipleToAddress_msg);
        variable msg_type : msg_type_t;
        variable reply_msg : msg_t;
        variable faultData : bus_pkg.bus_fault_type;
        variable faultAddress : bus_pkg.bus_address_type;
    begin
        push(msg, mask);
        push(msg, addr);
        push(msg, data'length);
        for i in 0 to data'length - 1 loop
            push(msg, data(i));
        end loop;
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = write_reply_msg then
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
            check(false, "Write returned an error " & to_hstring(faultData) & " at address " & to_hstring(faultAddress));
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure write_to_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_type;
              constant mask : in bus_pkg.bus_write_mask_type;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type) is
        variable msg : msg_t := new_msg(write_toAddress_msg);
        variable msg_type : msg_type_t;
        variable reply_msg : msg_t;
    begin
        push(msg, addr);
        push(msg, data);
        push(msg, mask);
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = write_reply_msg then
            check(false, "Write was supposed to return an error but did not");
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure write_to_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_array;
              constant mask : in bus_pkg.bus_write_mask_type;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type) is
        variable msg : msg_t := new_msg(write_multipleToAddress_msg);
        variable msg_type : msg_type_t;
        variable reply_msg : msg_t;
    begin
        push(msg, mask);
        push(msg, addr);
        push(msg, data'length);
        for i in 0 to data'length - 1 loop
            push(msg, data(i));
        end loop;
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = write_reply_msg then
            check(false, "Write was supposed to return an error but did not");
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_type) is
        variable msg : msg_t := new_msg(read_fromAddress_msg);
        variable reply_msg : msg_t;
        variable msg_type : msg_type_t;
        variable faultData : bus_pkg.bus_fault_type;
        variable faultAddress : bus_pkg.bus_address_type;
    begin
        push(msg, addr);
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = read_reply_msg then
            data := pop(reply_msg);
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
            check(false, "Read returned an error " & to_hstring(faultData) & " at address " & to_hstring(faultAddress));
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_array) is
        variable msg : msg_t := new_msg(read_multipleFromAddress_msg);
        variable reply_msg : msg_t;
        variable msg_type : msg_type_t;
        variable faultData : bus_pkg.bus_fault_type;
        variable faultAddress : bus_pkg.bus_address_type;
    begin
        push(msg, addr);
        push(msg, data'length);
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = read_reply_msg then
            for i in 0 to data'length - 1 loop
                data(i) := pop(reply_msg);
            end loop;
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
            check(false, "Read returned an error " & to_hstring(faultData) & " at address " & to_hstring(faultAddress));
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure read_from_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_type;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type) is
        variable msg : msg_t := new_msg(read_fromAddress_msg);
        variable reply_msg : msg_t;
        variable msg_type : msg_type_t;
    begin
        push(msg, addr);
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = read_reply_msg then
            check(false, "Read was supposed to return an error but did not");
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure read_from_address_expecting_fault(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_array;
              variable faultData : out bus_pkg.bus_fault_type;
              variable faultAddress : out bus_pkg.bus_address_type) is
        variable msg : msg_t := new_msg(read_multipleFromAddress_msg);
        variable reply_msg : msg_t;
        variable msg_type : msg_type_t;
    begin
        push(msg, addr);
        push(msg, data'length);
        request(net, actor, msg, reply_msg);
        msg_type := message_type(reply_msg);
        if msg_type = read_reply_msg then
            check(false, "Read was supposed to return an error but did not");
        elsif msg_type = fault_reply_msg then
            faultData := pop(reply_msg);
            faultAddress := pop(reply_msg);
        else
            unexpected_msg_type(msg_type);
        end if;
    end;

    procedure write_file_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              constant fileName : in string) is
        file read_file : text;
        variable line_v : line;
        variable data : bus_pkg.bus_data_type;
        variable address : natural := addr;
        variable busAddress : bus_pkg.bus_address_type;
        constant mask : bus_pkg.bus_write_mask_type := (others => '1');
    begin
        file_open(read_file, fileName, read_mode);
        while not endfile(read_file) loop
            readline(read_file, line_v);
            hread(line_v, data);
            busAddress := std_logic_vector(to_unsigned(address, busAddress'length));
            write_to_address(net, actor, busAddress, data, mask);
            address := address + 4;
        end loop;
        file_close(read_file);
    end;
end package body;
