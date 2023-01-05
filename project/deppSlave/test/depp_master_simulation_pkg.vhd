library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

library src;
use src.bus_pkg;
use src.depp_pkg.all;
library tb;
use tb.depp_tb_pkg.all;

package depp_master_simulation_pkg is
    procedure read_busWord_array(
              signal clk : in std_logic;

              signal usb_db : inout std_logic_vector(7 downto 0);
              signal usb_write : out std_logic;
              signal usb_astb : out std_logic;
              signal usb_dstb : out std_logic;
              signal usb_wait : in std_logic;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_array);

    procedure write_busWord_array(
              signal clk : in std_logic;

              signal usb_db : inout std_logic_vector(7 downto 0);
              signal usb_write : out std_logic;
              signal usb_astb : out std_logic;
              signal usb_dstb : out std_logic;
              signal usb_wait : in std_logic;
              constant addr : in bus_pkg.bus_address_type;
              constant writeMask : in bus_pkg.bus_write_mask;
              variable data : in bus_pkg.bus_data_array);
end package;

package body depp_master_simulation_pkg is
    procedure read_busWord_array(
              signal clk : in std_logic;

              signal usb_db : inout std_logic_vector(7 downto 0);
              signal usb_write : out std_logic;
              signal usb_astb : out std_logic;
              signal usb_dstb : out std_logic;
              signal usb_wait : in std_logic;
              constant addr : in bus_pkg.bus_address_type;
              variable data : out bus_pkg.bus_data_array) is
        variable depp_mode : depp_data_type := (others => '0');
        variable depp_addr : depp_address_type := (others => '0');
        constant depp_word_per_bus_word : natural := bus_pkg.bus_data_type'length / depp_data_type'length;
    begin
        -- Set fast read mode
        depp_mode(depp_mode_fast_read_bit) := '1';
        depp_addr := std_logic_vector(to_unsigned(depp2bus_mode_register_start, depp_addr'length));
        depp_tb_depp_write_to_address (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => depp_addr,
            data => depp_mode
        );
        -- Set the start address on the bus
        depp_tb_bus_set_address (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            address => addr
        );
        -- Set the depp address to the start of the read area
        depp_addr := std_logic_vector(to_unsigned(depp2bus_readData_reg_start, depp_addr'length));
        depp_tb_depp_set_address (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => depp_addr
        );
        -- Read from the bus
        for i in 0 to data'length -1 loop
            for j in 0 to depp_word_per_bus_word - 1 loop
                depp_tb_depp_get_data(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    data => data(i)(((j+1)*depp_data_type'length) - 1 downto (j)*depp_data_type'length),
                    expect_completion => true
                );
            end loop;
        end loop;
    end read_busWord_array;

    procedure write_busWord_array(
              signal clk : in std_logic;

              signal usb_db : inout std_logic_vector(7 downto 0);
              signal usb_write : out std_logic;
              signal usb_astb : out std_logic;
              signal usb_dstb : out std_logic;
              signal usb_wait : in std_logic;
              constant addr : in bus_pkg.bus_address_type;
              constant writeMask : in bus_pkg.bus_write_mask;
              variable data : in bus_pkg.bus_data_array) is
        variable depp_mode : depp_data_type := (others => '0');
        variable depp_addr : depp_address_type := (others => '0');
        constant depp_word_per_bus_word : natural := bus_pkg.bus_data_type'length / depp_data_type'length;
    begin
        -- Set fast write mode
        depp_mode(depp_mode_fast_write_bit) := '1';
        depp_addr := std_logic_vector(to_unsigned(depp2bus_mode_register_start, depp_addr'length));
        depp_tb_depp_write_to_address (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => depp_addr,
            data => depp_mode
        );
        -- Set the start address on the bus
        depp_tb_bus_set_address (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            address => addr
        );
        -- Set the writemask on the bus
        depp_tb_bus_set_write_mask (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            write_mask => writeMask
        );
        -- Set the depp address to the start of the write area
        depp_addr := std_logic_vector(to_unsigned(depp2bus_writeData_reg_start, depp_addr'length));
        depp_tb_depp_set_address (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => depp_addr
        );
        -- Write to the bus
        for i in 0 to data'length - 1 loop
            for j in 0 to depp_word_per_bus_word - 1 loop
            --info(natural'image(((j+1)*depp_data_type'length) - 1) & " downto " & natural'image((j)*depp_data_type'length));
                depp_tb_depp_set_data(
                    clk => clk,
                    usb_db => usb_db,
                    usb_write => usb_write,
                    usb_astb => usb_astb,
                    usb_dstb => usb_dstb,
                    usb_wait => usb_wait,
                    data => data(i)(((j+1)*depp_data_type'length) - 1 downto (j)*depp_data_type'length),
                    expect_completion => true
                );
            end loop;
        end loop;
    end write_busWord_array;
end package body depp_master_simulation_pkg;
