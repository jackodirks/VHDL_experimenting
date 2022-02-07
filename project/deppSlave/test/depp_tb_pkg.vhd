library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src;
use src.depp_pkg.all;
use src.bus_pkg.all;

package depp_tb_pkg is

    function depp_tb_depp2bus (
        address : natural range 0 to 2**8 - 1 := 0;
        writeData : natural range 0 to 2**8 - 1 := 0;
        writeEnable : boolean := false;
        readEnable : boolean := false
    ) return depp2bus_type;

    procedure depp_tb_single_write (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        signal addr : in bus_address_type;
        signal data : in bus_data_type;
        signal wMask : in bus_write_mask
    );

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

    procedure depp_tb_single_write (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        signal addr : in bus_address_type;
        signal data : in bus_data_type;
        signal wMask : in bus_write_mask
    ) is
    begin
        usb_write <= '1';
        usb_astb <= '1';
        usb_dstb <= '1';
        usb_db <= (others => 'Z');
        wait until usb_wait = '0';
        wait until falling_edge(clk);
        -- Transmit the address
        for b in 0 to bus_address_type'length/usb_db'length - 1 loop
            usb_db <= std_logic_vector(to_unsigned(depp2bus_addr_reg_start + b, usb_db'length));
            usb_write <= '0';
            usb_astb <= '0';
            wait until usb_wait = '1' and falling_edge(clk);
            usb_write <= '1';
            usb_astb <= '1';
            usb_db <= (others => 'Z');
            wait until usb_wait = '0' and falling_edge(clk);
            usb_db <= addr((b+1)*usb_db'length - 1 downto b * usb_db'length);
            usb_write <= '0';
            usb_dstb <= '0';
            wait until usb_wait = '1' and falling_edge(clk);
            usb_write <= '1';
            usb_dstb <= '1';
            usb_db <= (others => 'Z');
            wait until usb_wait = '0' and falling_edge(clk);
        end loop;
    end depp_tb_single_write;

end depp_tb_pkg;
