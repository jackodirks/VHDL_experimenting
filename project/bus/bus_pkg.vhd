library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package bus_pkg is

    -- General information on the bus:
    -- The master initiates all communication. When readEnable or writeEnable become high (they must never be high at the same time) address and possibly writeData must be valid.
    -- The master must now wait until ack becomes high. Ack has to remain high until readData/writeData is zero.
    -- On read, the slave must keep readData valid until readEnable is low again.
    -- This finishes the transaction.
    -- A fault sets a faultcode on the WriteData bus and is handled similarly to an ack otherwise.

    subtype bus_address_type     is std_logic_vector(7 downto  0); -- Any bus address.
    subtype bus_data_type        is std_logic_vector(7 downto  0); -- Any data word.

    -- The remapping logic.
    -- Any range of input can be placed at any range of output. Moreover, parts of the output can be set to 0 or 1.
    -- As an example, take a device which has registers on address 0 to 3, but in reality lives on address 1 to 4.
    -- A correct remapping would now be: bus_map_constant(1, '0') & bus_map_range(bus_address_type'high - 1, 0)
    type bitMapping_array is array (natural range <>) of integer;
    -- Using this type makes sure that the bitmapping aray is always exactly long enough.
    subtype addrMapping_type is bitMapping_array(bus_address_type'range);

    type bus_mst2slv_type is record
        address         : bus_address_type;
        writeData       : bus_data_type;
        readEnable      : std_logic;
        writeEnable     : std_logic;
    end record;

    type bus_mst2slv_array is array (natural range <>) of bus_mst2slv_type;

    type bus_slv2mst_type is record
        readData        : bus_data_type;
        ack             : std_logic;
        fault           : std_logic;
    end record;

    type bus_slv2mst_array is array (natural range <>) of bus_slv2mst_type;

    type addr_range_type is record
        low       : bus_address_type;
        high      : bus_address_type;
    end record;

    type addr_range_and_mapping_type is record
        addr_range  : addr_range_type;
        mapping     : addrMapping_type;
    end record;

    type addr_range_and_mapping_array is array (natural range <>) of addr_range_and_mapping_type;

    constant BUS_MST2SLV_IDLE : bus_mst2slv_type := (
        address => (others => '0'),
        writeData => (others => '0'),
        readEnable => '0',
        writeEnable => '0'
    );

    constant BUS_SLV2MST_IDLE : bus_slv2mst_type := (
        readData => (others => '0'),
        ack => '0',
        fault => '0'
    );

    -- Returns true when the specified master is requesting something.
    function bus_requesting(
        b     : bus_mst2slv_type
    ) return std_logic;

    function bus_slave_finished(
        b     : bus_slv2mst_type
    ) return std_logic;

    function bus_addr_in_range(
        addr        : bus_address_type;
        addr_range  : addr_range_type
    ) return boolean;

    -- Mapping functions
    function bus_map_range(
        high      : natural;
        low       : natural
    ) return bitMapping_array;

    function bus_map_constant(
        count     : natural;
        value     : std_logic
    ) return bitMapping_array;

    function address_range_and_map (
        low     : bus_address_type := (others => '0');
        high    : bus_address_type := (others => '1');
        mapping : addrMapping_type := bus_map_range(bus_address_type'high, 0)
    ) return addr_range_and_mapping_type;

    function bus_apply_addr_map(
        addr      : bus_address_type;
        addrMap   : addrMapping_type
    ) return bus_address_type;

end bus_pkg;

package body bus_pkg is

    function bus_requesting(
        b   : bus_mst2slv_type
    ) return std_logic is
    begin
        return b.readEnable or b.writeEnable;
    end bus_requesting;

    function bus_slave_finished(
        b : bus_slv2mst_type
    ) return std_logic is
    begin
        return b.ack or b.fault;
    end bus_slave_finished;

    function bus_addr_in_range (
        addr        : bus_address_type;
        addr_range  : addr_range_type
    ) return boolean is
    begin
        return unsigned(addr) >= unsigned(addr_range.low) and unsigned(addr) <= unsigned(addr_range.high);
    end bus_addr_in_range;

    function bus_map_range(
        high      : natural;
        low       : natural
    ) return bitMapping_array is
        variable res : bitMapping_array(high-low downto 0);
    begin
        for i in res'range loop
            res(i) := i + low;
        end loop;
        return res;
    end bus_map_range;

    function bus_map_constant(
        count     : natural;
        value     : std_logic
    ) return bitMapping_array is
        variable res : bitMapping_array(count-1 downto 0);
    begin
        if value = '1' then
            res := (others => -2); -- Code for '1'.
        else
            res := (others => -1); -- Code for '0'.
        end if;
        return res;
    end bus_map_constant;

    function address_range_and_map (
        low     : bus_address_type := (others => '0');
        high    : bus_address_type := (others => '1');
        mapping : addrMapping_type := bus_map_range(bus_address_type'high, 0)
    ) return addr_range_and_mapping_type is
        variable retval   : addr_range_and_mapping_type;
    begin
        retval.addr_range := (
            low   => low,
            high  => high
        );
        retval.mapping := mapping;
        return retval;
    end address_range_and_map;

    function bus_apply_addr_map(
        addr      : bus_address_type;
        addrMap   : addrMapping_type
    ) return bus_address_type is
        variable res : bus_address_type;
    begin
        for i in res'range loop
            if addrMap(i) = -2 then -- Code for '1'.
                res(i) := '1';
            elsif addrMap(i) = -1 then -- Code for '0'.
                res(i) := '0';
            else
                res(i) := addr(addrMap(i));
            end if;
        end loop;
        return res;
    end bus_apply_addr_map;
end bus_pkg;
