library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.sync_pkg.all;

library src;
use src.mips32_pkg.all;

package mips32_pipeline_simulated_memory_pkg is
    constant read_reply_msg : msg_type_t := new_msg_type("read reply");
    constant read_fromAddress_msg : msg_type_t := new_msg_type("read from address");
    constant write_toAddress_msg : msg_type_t := new_msg_type("write to address");


    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              variable data : out mips32_data_type);

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              constant data : in mips32_data_type);

    procedure write_file_to_address (
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              constant fileName : in string);
end package;

package body mips32_pipeline_simulated_memory_pkg is
    procedure read_from_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              variable data : out mips32_data_type) is
        variable msg : msg_t := new_msg(read_fromaddress_msg);
        variable reply_msg : msg_t;
    begin
        push(msg, addr);
        request(net, actor, msg, reply_msg);
        data := pop(reply_msg);
    end;

    procedure write_to_address(
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              constant data : in mips32_data_type) is
        variable msg : msg_t := new_msg(write_toAddress_msg);
    begin
        push(msg, addr);
        push(msg, data);
        send(net, actor, msg);
    end;

    procedure write_file_to_address (
              signal net : inout network_t;
              constant actor : in actor_t;
              constant addr : in natural;
              constant fileName : in string) is
        file read_file : text;
        variable line_v : line;
        variable data : mips32_data_type;
        variable address : natural := addr;
    begin
        file_open(read_file, fileName, read_mode);
        while not endfile(read_file) loop
            readline(read_file, line_v);
            hread(line_v, data);
            write_to_address(net, actor, address, data);
            address := address + 4;
        end loop;
        file_close(read_file);
    end;

end package body;
