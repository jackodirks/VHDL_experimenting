library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.bus_pkg;
-- TODO
-- Remove the fast read/write stuff and have it default enabled. Also remove the activation register
-- Add a fault register and a fault_address register (make sure that there is a NO_FAULT fault)
-- Add a burst register, length of 255 seems plenty
-- Overlay writeData and readData
-- Make a slide: byteMask -> burst -> busAddress -> read/write. Make it so that any read/write updates the internal depp address unless we are in the read/write register
-- This way, operations will be wayy cheaper since deppAddress will only ever be set once. For any operation.
-- Make another slide: faultData -> faultAddress put it in front of byteMask.

package depp_pkg is

    subtype depp_address_type is std_logic_vector(7 downto 0);
    subtype depp_data_type is std_logic_vector(7 downto 0);

    type selected_request_register_type is (reqReg_none, reqReg_faultData, reqReg_faultAddress, reqReg_byteMask, reqReg_burstLength, reqReg_address, reqReg_readWrite);

    constant depp_words_per_bus_word : natural := bus_pkg.bus_data_type'length / depp_pkg.depp_data_type'length;
    constant depp_words_per_bus_address : natural := bus_pkg.bus_address_type'length / depp_pkg.depp_data_type'length;
    constant depp_data_type_size : natural := depp_data_type'length;

    -- All registers are defined as inclusive start, inclusive end.
    constant depp2bus_faultData_reg_start : natural := 0;
    constant depp2bus_faultData_reg_end : natural := depp2bus_faultData_reg_start;
    constant depp2bus_faultAddress_reg_start : natural := depp2bus_faultData_reg_end + 1;
    constant depp2bus_faultAddress_reg_end : natural := depp2bus_faultAddress_reg_start + depp_words_per_bus_address - 1;
    constant depp2bus_byteMask_reg_start : natural := depp2bus_faultAddress_reg_end + 1;
    constant depp2bus_byteMask_reg_end : natural := depp2bus_byteMask_reg_start;
    constant depp2bus_burstLength_reg_start : natural := depp2bus_byteMask_reg_end + 1;
    constant depp2bus_burstLength_reg_end : natural := depp2bus_burstLength_reg_start;
    constant depp2bus_address_reg_start : natural := depp2bus_burstLength_reg_end + 1;
    constant depp2bus_address_reg_end : natural := depp2bus_address_reg_start + depp_words_per_bus_address - 1;
    constant depp2bus_readWrite_reg_start : natural := depp2bus_address_reg_end + 1;
    constant depp2bus_readWrite_reg_end : natural := depp2bus_readWrite_reg_start + depp_words_per_bus_word - 1;

    procedure decode_request_register (
        constant address : natural range 0 to 255;
        variable selected_request_register : out selected_request_register_type;
        variable relative_address : out natural range 0 to 255
    );

    pure function incremented_bus_address(
        address : bus_pkg.bus_address_type
    ) return bus_pkg.bus_address_type;

end package;

package body depp_pkg is
    procedure decode_request_register (
        constant address : natural range 0 to 255;
        variable selected_request_register : out selected_request_register_type;
        variable relative_address : out natural range 0 to 255
    ) is
    begin
        if address >= depp2bus_faultData_reg_start and address <= depp2bus_faultData_reg_end then
            selected_request_register := reqReg_faultData;
            relative_address := address - depp2bus_faultData_reg_start;
        elsif address >= depp2bus_faultAddress_reg_start and address <= depp2bus_faultAddress_reg_end then
            selected_request_register := reqReg_faultAddress;
            relative_address := address - depp2bus_faultAddress_reg_start;
        elsif address >= depp2bus_byteMask_reg_start and address <= depp2bus_byteMask_reg_end then
            selected_request_register := reqReg_byteMask;
            relative_address := address - depp2bus_byteMask_reg_start;
        elsif address >= depp2bus_burstLength_reg_start and address <= depp2bus_burstLength_reg_end then
            selected_request_register := reqReg_burstLength;
            relative_address := address - depp2bus_burstLength_reg_start;
        elsif address >= depp2bus_address_reg_start and address <= depp2bus_address_reg_end then
            selected_request_register := reqReg_address;
            relative_address := address - depp2bus_address_reg_start;
        elsif address >= depp2bus_readWrite_reg_start and address <= depp2bus_readWrite_reg_end then
            selected_request_register := reqReg_readWrite;
            relative_address := address - depp2bus_readWrite_reg_start;
        else
            selected_request_register := reqReg_none;
            relative_address := 0;
        end if;
    end procedure;

    pure function incremented_bus_address(
        address : bus_pkg.bus_address_type
    ) return bus_pkg.bus_address_type is
        variable addr : natural;
    begin
        addr := to_integer(unsigned(address));
        return std_logic_vector(to_unsigned(addr + depp_words_per_bus_address, address'length));
    end function;
end package body;
