library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.bus_pkg.all;

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

    constant depp2bus_write_mask_length_ceil : natural := natural(ceil(real(bus_write_mask'length)/real(8)));
    -- All registers are defined as inclusive start, inclusive end.
    -- First the common registers, addr and data are available to both read and write
    constant depp2bus_addr_reg_start : natural := 0;
    constant depp2bus_addr_reg_len : natural := bus_address_type'length/8;
    constant depp2bus_addr_reg_end : natural := depp2bus_addr_reg_start + depp2bus_addr_reg_len - 1;
    constant depp2bus_data_reg_start : natural := depp2bus_addr_reg_start + depp2bus_addr_reg_len;
    constant depp2bus_data_reg_len : natural := bus_data_type'length/8;
    constant depp2bus_data_reg_end : natural := depp2bus_data_reg_start + depp2bus_data_reg_len - 1;
    -- Write mask only exists from the perspective of the writer and shares its address with the fault register
    constant depp2bus_write_mask_start : natural := depp2bus_data_reg_start + depp2bus_data_reg_len;
    constant depp2bus_write_mask_len : natural := depp2bus_write_mask_length_ceil;
    constant depp2bus_write_mask_end : natural := depp2bus_write_mask_start + depp2bus_write_mask_len - 1;
    -- Fault register only exists from the perspective of the reader and shares its address with the write mask
    -- The fault register has a length of 1 byte.
    constant depp2bus_fault_register_start : natural := depp2bus_write_mask_start;
    constant depp2bus_fault_register_end : natural := depp2bus_fault_register_start;
    -- The activation register only exists from the perspective of the writer. It is always exactly one byte.
    constant depp2bus_activation_register_start : natural := depp2bus_write_mask_start + depp2bus_write_mask_length_ceil;
    constant depp2bus_activation_register_end : natural := depp2bus_activation_register_start;

end depp_pkg;
