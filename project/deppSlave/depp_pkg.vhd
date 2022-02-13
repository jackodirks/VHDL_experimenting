library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.bus_pkg.all;

package depp_pkg is
    constant depp2bus_write_mask_length_ceil : natural := natural(ceil(real(bus_write_mask'length)/real(8)));
    -- All registers are defined as inclusive start, inclusive end.
    -- First the common registers, addr and data are available to both read and write
    constant depp2bus_addr_reg_start : natural := 0;
    constant depp2bus_addr_reg_len : natural := bus_address_type'length/8;
    constant depp2bus_addr_reg_end : natural := depp2bus_addr_reg_start + depp2bus_addr_reg_len - 1;
    constant depp2bus_data_reg_start : natural := depp2bus_addr_reg_start + depp2bus_addr_reg_len;
    constant depp2bus_data_reg_len : natural := bus_data_type'length/8;
    constant depp2bus_data_reg_end : natural := depp2bus_data_reg_start + depp2bus_data_reg_len - 1;
    constant depp2bus_write_mask_reg_start : natural := depp2bus_data_reg_start + depp2bus_data_reg_len;
    constant depp2bus_write_mask_reg_len : natural := depp2bus_write_mask_length_ceil;
    constant depp2bus_write_mask_reg_end : natural := depp2bus_write_mask_reg_start + depp2bus_write_mask_reg_len - 1;
    -- Fault register only exists from the perspective of the reader and shares its address with the activation register
    -- The fault register has a length of 1 byte.
    constant depp2bus_fault_register_start : natural := depp2bus_write_mask_reg_start + depp2bus_write_mask_length_ceil;
    constant depp2bus_fault_register_end : natural := depp2bus_fault_register_start;
    -- The activation register only exists from the perspective of the writer. It is always exactly one byte.
    constant depp2bus_activation_register_start : natural := depp2bus_write_mask_reg_start + depp2bus_write_mask_length_ceil;
    constant depp2bus_activation_register_end : natural := depp2bus_activation_register_start;
    -- The mode register only exists from the perspective of the writer. It is always exactly one byte
    constant depp2bus_mode_register_start : natural := depp2bus_activation_register_end + 1;
    constant depp2bus_mode_register_end : natural := depp2bus_mode_register_start;

    -- The possible modes of the depp2bus device. This is about depp address increment rules
    constant depp_mode_fast_write_bit : natural := 1;
end depp_pkg;
