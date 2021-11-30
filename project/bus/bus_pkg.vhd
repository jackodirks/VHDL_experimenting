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

    type bus_mst2slv_type is record
        address         : std_logic_vector(7 downto 0);
        writeData       : std_logic_vector(7 downto 0);
        readEnable      : std_logic;
        writeEnable     : std_logic;
    end record;

    type bus_slv2mst_type is record
        readData        : std_logic_vector(7 downto 0);
        ack             : std_logic;
        fault           : std_logic;
    end record;

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
      b       : bus_slv2mst_type
    ) return std_logic;

end bus_pkg;

package body bus_pkg is

  function bus_requesting(
    b     : bus_mst2slv_type
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

end bus_pkg;
