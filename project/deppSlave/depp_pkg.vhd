library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package depp_pkg is

    type depp2bus_type is record
        address : std_logic_vector(7 downto 0);
        writeData : std_logic_vector(7 downto 0);
        writeEnable : boolean;
        readEnable : boolean;
    end record;

    type bus2depp_type is record
        readData : std_logic_vector(7 downto 0);
        done : boolean;
    end record;

    constant DEPP2BUS_IDLE : depp2bus_type := (
        address => (others => '0'),
        writeData => (others => '0'),
        writeEnable => false,
        readEnable => false
    );

    constant BUS2DEPP_IDLE : bus2depp_type := (
        readData => (others => '0'),
        done => false
    );

end depp_pkg;
