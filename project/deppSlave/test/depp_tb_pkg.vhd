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
        deppMode        : depp_data_type;
        fault        : boolean;
    end record;

    constant DEPP_SLAVE_STATE_TYPE_IDLE : depp_slave_state_type := (
        address => (others => '0'),
        writeData => (others => '0'),
        readData => (others => '0'),
        writeMask => (others => '0'),
        deppMode => (others => '0'),
        fault => false
    );

    procedure depp_tb_depp_set_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in depp_address_type
    );

    procedure depp_tb_depp_set_data (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant data : in depp_data_type;
        constant expect_completion : in boolean
    );

    procedure depp_tb_depp_get_data (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        variable data : out depp_data_type;
        constant expect_completion : in boolean
    );

    procedure depp_tb_depp_write_to_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in depp_address_type;
        constant data : in depp_data_type
    );

    procedure depp_tb_depp_read_from_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in depp_address_type;
        variable data : out depp_data_type
    );

    procedure depp_tb_bus_set_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant address : in bus_address_type
    );

    procedure depp_tb_bus_set_write_mask (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant write_mask : in bus_write_mask
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

    procedure depp_tb_bus_prepare_read (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant address : in bus_address_type
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

    procedure depp_tb_bus_finish_write_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic
    );

    procedure depp_tb_bus_finish_read_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        variable data : out depp_data_type
    );

    procedure depp_tb_slave_check_state (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        variable actualState : out depp_slave_state_type
    );


end depp_tb_pkg;

package body depp_tb_pkg is
    procedure depp_tb_depp_set_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in depp_address_type
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
    end procedure;

    procedure depp_tb_depp_set_data (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant data : in depp_data_type;
        constant expect_completion : in boolean
    ) is
    begin
        usb_db <= (others => 'Z');
        usb_astb <= '1';
        usb_dstb <= '1';
        usb_write <= '1';
        wait until usb_wait = '0' and falling_edge(clk);
        usb_db <= data;
        usb_dstb <= '0';
        usb_write <= '0';
        if expect_completion then
            wait until usb_wait = '1' and falling_edge(clk);
            usb_db <= (others => 'Z');
            usb_dstb <= '1';
            usb_write <= '1';
        end if;
    end procedure;

    procedure depp_tb_depp_get_data (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        variable data : out depp_data_type;
        constant expect_completion : in boolean
    ) is
    begin
        usb_db <= (others => 'Z');
        usb_astb <= '1';
        usb_dstb <= '1';
        usb_write <= '1';
        wait until usb_wait = '0' and falling_edge(clk);
        usb_dstb <= '0';
        if expect_completion then
            wait until usb_wait = '1' and falling_edge(clk);
            data := usb_db;
            usb_dstb <= '1';
        else
            data := (others => '0');
        end if;
    end procedure;

    procedure depp_tb_depp_write_to_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in depp_address_type;
        constant data : in depp_data_type
    ) is
    begin
        depp_tb_depp_set_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => addr
        );
        depp_tb_depp_set_data(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            data => data,
            expect_completion => true
        );
    end procedure;

    procedure depp_tb_depp_read_from_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant addr : in depp_address_type;
        variable data : out depp_data_type
    ) is
    begin
        depp_tb_depp_set_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => addr
        );
        depp_tb_depp_get_data(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            data => data,
            expect_completion => true
        );
    end procedure;

    procedure depp_tb_bus_set_address (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant address : in bus_address_type
    ) is
    begin
        for b in 0 to depp2bus_addr_reg_len - 1 loop
                depp_tb_depp_write_to_address(
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
    end procedure;

    procedure depp_tb_bus_set_write_mask (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant write_mask : in bus_write_mask
    ) is
        variable writeMaskReg : std_logic_vector(7 downto 0);
    begin
        writeMaskReg := (others => '0');
        writeMaskReg(write_mask'range) := write_mask;
        depp_tb_depp_write_to_address(
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
    begin
        -- Address
        depp_tb_bus_set_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            address => address
        );
         -- writeData
        for b in 0 to depp2bus_writeData_reg_len - 1 loop
            depp_tb_depp_write_to_address(
                clk => clk,
                usb_db => usb_db,
                usb_write => usb_write,
                usb_astb => usb_astb,
                usb_dstb => usb_dstb,
                usb_wait => usb_wait,
                addr => std_logic_vector(to_unsigned(depp2bus_writeData_reg_start + b, usb_db'length)),
                data => writeData((b+1)*8 - 1 downto b*8)
            );
        end loop;
        depp_tb_bus_set_write_mask (
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            write_mask => writeMask
        );
    end procedure;

    procedure depp_tb_bus_prepare_read (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        constant address : in bus_address_type
    ) is
    begin
        depp_tb_bus_set_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            address => address
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

    procedure depp_tb_bus_finish_write_transaction (
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

    procedure depp_tb_bus_finish_read_transaction (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        variable data : out depp_data_type
    ) is
    begin
        wait until usb_wait = '1' and falling_edge(clk);
        data := usb_db;
        usb_dstb <= '1';
        usb_write <= '1';
        wait until usb_wait = '0' and falling_edge(clk);
        usb_db <= (others => 'Z');
    end procedure;

    procedure depp_tb_slave_check_state (
        signal clk : in std_logic;

        signal usb_db : inout std_logic_vector(7 downto 0);
        signal usb_write : out std_logic;
        signal usb_astb : out std_logic;
        signal usb_dstb : out std_logic;
        signal usb_wait : in std_logic;

        variable actualState : out depp_slave_state_type
    ) is
        variable faultReg : depp_data_type := (others => '0');
        variable writeMaskReg : depp_data_type := (others => '0');
    begin
        for b in 0 to depp2bus_addr_reg_len - 1 loop
            depp_tb_depp_read_from_address(
                clk => clk,
                usb_db => usb_db,
                usb_write => usb_write,
                usb_astb => usb_astb,
                usb_dstb => usb_dstb,
                usb_wait => usb_wait,
                addr => std_logic_vector(to_unsigned(depp2bus_addr_reg_start + b, usb_db'length)),
                data => actualState.address((b+1)*8 - 1 downto b*8)
            );
        end loop;
        for b in 0 to depp2bus_writeData_reg_len - 1 loop
            depp_tb_depp_read_from_address(
                clk => clk,
                usb_db => usb_db,
                usb_write => usb_write,
                usb_astb => usb_astb,
                usb_dstb => usb_dstb,
                usb_wait => usb_wait,
                addr => std_logic_vector(to_unsigned(depp2bus_writeData_reg_start + b, usb_db'length)),
                data => actualState.writeData((b+1)*8 - 1 downto b*8)
            );
        end loop;
        for b in 0 to depp2bus_readData_reg_len - 1 loop
            depp_tb_depp_read_from_address(
                clk => clk,
                usb_db => usb_db,
                usb_write => usb_write,
                usb_astb => usb_astb,
                usb_dstb => usb_dstb,
                usb_wait => usb_wait,
                addr => std_logic_vector(to_unsigned(depp2bus_readData_reg_start + b, usb_db'length)),
                data => actualState.readData((b+1)*8 - 1 downto b*8)
            );
        end loop;
        depp_tb_depp_read_from_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => std_logic_vector(to_unsigned(depp2bus_write_mask_reg_start, usb_db'length)),
            data => writeMaskReg
        );
        actualState.writeMask := writeMaskReg(actualState.writeMask'range);
        depp_tb_depp_read_from_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => std_logic_vector(to_unsigned(depp2bus_mode_register_start, usb_db'length)),
            data => actualState.deppMode
        );
        depp_tb_depp_read_from_address(
            clk => clk,
            usb_db => usb_db,
            usb_write => usb_write,
            usb_astb => usb_astb,
            usb_dstb => usb_dstb,
            usb_wait => usb_wait,
            addr => std_logic_vector(to_unsigned(depp2bus_fault_register_start, usb_db'length)),
            data => faultReg
        );
        actualState.fault := faultReg(0) = '1';
    end procedure;

end depp_tb_pkg;
