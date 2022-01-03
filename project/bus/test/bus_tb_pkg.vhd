library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src;
use src.bus_pkg.all;

package bus_tb_pkg is

    function bus_tb_mst2slv(
        address : natural range 0 to 2**bus_address_type'length - 1 := 0;
        writeData    : natural range 0 to 2**bus_data_type'length - 1 := 0;
        writeMask : natural range 0 to 2**bus_write_mask'length - 1 := 0;
        readEnable : std_logic := '0';
        writeEnable : std_logic := '0'
    ) return bus_mst2slv_type;

end bus_tb_pkg;

package body bus_tb_pkg is

    function bus_tb_mst2slv(
        address : natural range 0 to 2**bus_address_type'length - 1 := 0;
        writeData    : natural range 0 to 2**bus_data_type'length - 1 := 0;
        writeMask : natural range 0 to 2**bus_write_mask'length - 1 := 0;
        readEnable : std_logic := '0';
        writeEnable : std_logic := '0'
    ) return bus_mst2slv_type is
        variable retval : bus_mst2slv_type;
    begin
        retval.address := std_logic_vector(to_unsigned(address, bus_address_type'length));
        retval.writeData := std_logic_vector(to_unsigned(writeData, bus_data_type'length));
        retval.writeMask := std_logic_vector(to_unsigned(writeMask, bus_write_mask'length));
        retval.readEnable := readEnable;
        retval.writeEnable := writeEnable;
        return retval;
    end bus_tb_mst2slv;
end bus_tb_pkg;
