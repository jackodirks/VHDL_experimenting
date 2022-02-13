library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library src;
use src.depp_pkg.all;
use src.bus_pkg.all;

package depp_tb_pkg is

    type depp_slave_state_type is record
        address         : bus_address_type;
        writeData       : bus_data_type;
        readData        : bus_data_type;
        writeMask       : bus_write_mask;
    end record;

    procedure depp_tb_depp_write_with_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in std_logic_vector(7 downto 0);
        constant data : in std_logic_vector(7 downto 0)
    );

    procedure depp_tb_bus_prepare_write (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant address : in bus_address_type;
        constant writeData : in bus_data_type;
        constant writeMask : in bus_write_mask
    );

    procedure depp_tb_bus_start_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant doRead : in boolean
    );

    procedure depp_tb_bus_finish_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic
    );

end depp_tb_pkg;

package body depp_tb_pkg is
    procedure depp_tb_depp_write_with_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in std_logic_vector(7 downto 0);
        constant data : in std_logic_vector(7 downto 0)
    ) is
    begin
        usb_write <= '1';
        usb_astb <= '1';
        usb_dstb <= '1';
        usb_db <= (others => 'Z');
        wait until usb_wait = '0' and falling_edge(clk);
        usb_db <= addr;
        usb_astb <= '0';
        usb_write <= '0';
        wait until usb_wait = '1' and falling_edge(clk);
        usb_db <= (others => 'Z');
        usb_astb <= '1';
        usb_write <= '1';
        wait until usb_wait = '0' and falling_edge(clk);
        usb_db <= data;
        usb_dstb <= '0';
        usb_write <= '0';
        wait until usb_wait = '1' and falling_edge(clk);
        usb_db <= (others => 'Z');
        usb_dstb <= '1';
        usb_write <= '1';
    end procedure;

    procedure depp_tb_bus_prepare_write (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant address : in bus_address_type;
        constant writeData : in bus_data_type;
        constant writeMask : in bus_write_mask
    ) is
        variable writeMaskReg : std_logic_vector(7 downto 0);
    begin
        writeMaskReg := (others => '0');
        writeMaskReg(writeMask'range) := writeMask;
        -- Address
        for b in 0 to depp2bus_addr_reg_len - 1 loop
                depp_tb_depp_write_with_address(
                clk => clk,
                usb_db => usb_db,
                usb_write => usb_write,
                usb_astb => usb_astb,
                usb_dstb => usb_dstb,
                usb_wait => usb_wait,
                addr => std_logic_vector(to_unsigned(depp2bus_addr_reg_start + b, usb_db'length)),
                data => address((b+1)*8 - 1 downto b*8)
            );
        end loop;
         -- writeData
        for b in 0 to depp2bus_data_reg_len - 1 loop
            depp_tb_depp_write_with_address(
                clk => clk,
                usb_db => usb_db,
                usb_write => usb_write,
                usb_astb => usb_astb,
                usb_dstb => usb_dstb,
                usb_wait => usb_wait,
                addr => std_logic_vector(to_unsigned(depp2bus_data_reg_start + b, usb_db'length)),
                data => writeData((b+1)*8 - 1 downto b*8)
            );
        end loop;
        depp_tb_depp_write_with_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => std_logic_vector(to_unsigned(depp2bus_write_mask_reg_start, usb_db'length)),
            data => writeMaskReg
        );
    end procedure;


    procedure depp_tb_bus_start_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant doRead : in boolean
    ) is
        variable activateReg : std_logic_vector(7 downto 0) := (others => '0');
    begin
        if doRead then
            activateReg(0) := '1';
        end if;
        usb_write <= '1';
        usb_astb <= '1';
        usb_dstb <= '1';
        usb_db <= (others => 'Z');
        wait until usb_wait = '0' and falling_edge(clk);
        usb_db <= std_logic_vector(to_unsigned(depp2bus_activation_register_start, usb_db'length));
        usb_astb <= '0';
        usb_write <= '0';
        wait until usb_wait = '1' and falling_edge(clk);
        usb_db <= (others => 'Z');
        usb_astb <= '1';
        usb_write <= '1';
        wait until usb_wait = '0' and falling_edge(clk);
        usb_db <= activateReg;
        usb_dstb <= '0';
        usb_write <= '0';
    end procedure;

    procedure depp_tb_bus_finish_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic
    ) is
    begin
        wait until usb_wait = '1' and falling_edge(clk);
        usb_db <= (others => 'Z');
        usb_dstb <= '1';
        usb_write <= '1';
        wait until usb_wait = '0' and falling_edge(clk);
    end procedure;

end depp_tb_pkg;
