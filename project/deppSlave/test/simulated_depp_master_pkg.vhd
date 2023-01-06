library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

library src;
use src.bus_pkg;

package simulated_depp_master_pkg is
    constant read_reply_msg : msg_type_t := new_msg_type("read reply");

    constant read_fromAddress_msg : msg_type_t := new_msg_type("read from address");
    constant write_toAddress_msg : msg_type_t := new_msg_type("write to address");

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_type;
              constant mask : in bus_pkg.bus_write_mask);

    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_type);
end package;

package body simulated_depp_master_pkg is
    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_type) is
        variable msg : msg_t := new_msg(read_fromAddress_msg);
        variable reply_msg : msg_t;
    begin
        push(msg, addr);
        request(net, actor, msg, reply_msg);
        data := pop(reply_msg);
    end;

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in bus_pkg.bus_address_type;
              constant data : in bus_pkg.bus_data_type;
              constant mask : in bus_pkg.bus_write_mask) is
        variable msg : msg_t := new_msg(write_toAddress_msg);
        variable positive_ack : boolean;
    begin
        push(msg, addr);
        push(msg, data);
        push(msg, mask);
        request(net, actor, msg, positive_ack);
        check(positive_ack, "write_to_address failed");
    end;
end package body;
