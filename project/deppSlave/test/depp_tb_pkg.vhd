library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src;
use src.depp_pkg.all;

package depp_tb_pkg is

    function depp_tb_depp2bus (
        address : natural range 0 to 2**8 - 1 := 0;
        writeData : natural range 0 to 2**8 - 1 := 0;
        writeEnable : boolean := false;
        readEnable : boolean := false
    ) return depp2bus_type;


end depp_tb_pkg;

package body depp_tb_pkg is

    function depp_tb_depp2bus (
        address : natural range 0 to 2**8 - 1 := 0;
        writeData : natural range 0 to 2**8 - 1 := 0;
        writeEnable : boolean := false;
        readEnable : boolean := false
    ) return depp2bus_type is
        variable retval : depp2bus_type;
    begin
        retval.address := std_logic_vector(to_unsigned(address, 8));
        retval.writeData := std_logic_vector(to_unsigned(writeData, 8));
        retval.writeEnable := writeEnable;
        retval.readEnable := readEnable;
        return retval;
    end depp_tb_depp2bus;

end depp_tb_pkg;
