library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.bus_pkg.all;

package depp_pkg is

    subtype depp_address_type is std_logic_vector(7 downto 0);
    subtype depp_data_type is std_logic_vector(7 downto 0);

    constant depp2bus_write_mask_length_ceil : natural := natural(ceil(real(bus_write_mask'length)/real(8)));
    -- All registers are defined as inclusive start, inclusive end.
    -- First the common registers, addr and data are available to both read and write
    constant depp2bus_addr_reg_start : natural := 0;
    constant depp2bus_addr_reg_len : natural := bus_address_type'length/8;
    constant depp2bus_addr_reg_end : natural := depp2bus_addr_reg_start + depp2bus_addr_reg_len - 1;
    constant depp2bus_writeData_reg_start : natural := depp2bus_addr_reg_start + depp2bus_addr_reg_len;
    constant depp2bus_writeData_reg_len : natural := bus_data_type'length/8;
    constant depp2bus_writeData_reg_end : natural := depp2bus_writeData_reg_start + depp2bus_writeData_reg_len - 1;
    -- Writing to the readData register has no effect
    constant depp2bus_readData_reg_start : natural := depp2bus_writeData_reg_end + 1;
    constant depp2bus_readData_reg_len : natural := bus_data_type'length/8;
    constant depp2bus_readData_reg_end : natural := depp2bus_readData_reg_start + depp2bus_readData_reg_len - 1;
    constant depp2bus_write_mask_reg_start : natural := depp2bus_readData_reg_end + 1;
    constant depp2bus_write_mask_reg_len : natural := depp2bus_write_mask_length_ceil;
    constant depp2bus_write_mask_reg_end : natural := depp2bus_write_mask_reg_start + depp2bus_write_mask_reg_len - 1;
    constant depp2bus_mode_register_start : natural := depp2bus_write_mask_reg_end + 1;
    constant depp2bus_mode_register_end : natural := depp2bus_mode_register_start;
    -- Writing to the fault register has no effect
    constant depp2bus_fault_register_start : natural := depp2bus_mode_register_end + 1;
    constant depp2bus_fault_register_end : natural := depp2bus_fault_register_start;
    -- Reading from this register always returns 0
    constant depp2bus_activation_register_start : natural := depp2bus_fault_register_end + 1;
    constant depp2bus_activation_register_end : natural := depp2bus_activation_register_start;

    -- The possible modes of the depp2bus device. This is about address increment rules (both depp and bus)
    constant depp_mode_fast_write_bit : natural := 0;

    function depp_mode_fast_write_active(
        depp_mode   :   depp_data_type
    ) return boolean;

end depp_pkg;

package body depp_pkg is

    function depp_mode_fast_write_active(
        depp_mode   :   depp_data_type
    ) return boolean is
    begin
        return depp_mode(depp_mode_fast_write_bit) = '1';
    end function;

end package body;
