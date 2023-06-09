library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.uart_bus_master_pkg;

entity uart_bus_master is
    generic (
        clk_period : time;
        baud_rate : positive
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        rx : in std_logic;
        tx : out std_logic;

        mst2slv : out bus_pkg.bus_mst2slv_type;
        slv2mst : in bus_pkg.bus_slv2mst_type
    );
end entity;

architecture behaviourial of uart_bus_master is

    type command_type is (no_command, command_read_word);

    signal tx_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data_ready : boolean := false;
    signal tx_busy : boolean;

    signal rx_byte : std_logic_vector(7 downto 0);
    signal rx_data_ready : boolean;

    pure function translateCommand(byte : std_logic_vector(7 downto 0))
                                   return command_type is
        variable ret_val : command_type := no_command;
    begin
        case byte is
            when uart_bus_master_pkg.COMMAND_READ_WORD =>
                ret_val := command_read_word;
            when others =>
                ret_val := no_command;
        end case;
        return ret_val;
    end function;

begin
    process(clk)
        variable active_command : command_type := no_command;
        variable last_received_byte : std_logic_vector(7 downto 0) := (others => '0');
        variable rx_count : natural := 0;
        variable tx_count : natural := 0;
        variable address : bus_pkg.bus_address_type := (others => '0');
        variable transaction_complete : boolean := false;
        variable mst2slv_buf : bus_pkg.bus_mst2slv_type := bus_pkg.BUS_MST2SLV_IDLE;
        variable slv2mst_buf : bus_pkg.bus_slv2mst_type := bus_pkg.BUS_SLV2MST_IDLE;
        variable tx_data_ready_buf : boolean := false;
        variable tx_data_ready_prev : boolean := false;
    begin
        if rising_edge(clk) then
            tx_data_ready_buf := false;

            if bus_pkg.any_transaction(mst2slv_buf, slv2mst) then
                slv2mst_buf := slv2mst;
                mst2slv_buf := bus_pkg.BUS_MST2SLV_IDLE;
                transaction_complete := true;
            end if;

            if rx_count = 1 then
                active_command := translateCommand(last_received_byte);
                if active_command = no_command then
                    tx_byte <= uart_bus_master_pkg.ERROR_UNKOWN_COMMAND;
                    tx_data_ready_buf := true;
                    rx_count := 0;
                end if;
            elsif rx_count > 1 and rx_count <= 5 then
                address((rx_count - 2)*8 + 7 downto (rx_count - 2)*8) := last_received_byte;
            end if;

            if rx_count = 5 then
                if transaction_complete then
                    if not tx_busy and not tx_data_ready_prev then
                        if tx_count < 4 then
                            tx_byte <= slv2mst_buf.readData(tx_count*8 + 7 downto tx_count*8);
                            tx_data_ready_buf := true;
                            tx_count := tx_count + 1;
                        else
                            if slv2mst_buf.fault = '1' then
                                tx_byte <= (7 downto 4 => slv2mst_buf.faultData, 3 downto 0 => uart_bus_master_pkg.ERROR_BUS(3 downto 0));
                            else
                                tx_byte <= uart_bus_master_pkg.ERROR_NO_ERROR;
                            end if;
                            tx_data_ready_buf := true;
                            rx_count := 0;
                            tx_count := 0;
                            active_command := no_command;
                        end if;
                    end if;
                elsif not bus_pkg.bus_requesting(mst2slv_buf) then
                    mst2slv_buf := bus_pkg.bus_mst2slv_read(address);
                end if;
            end if;

            if rx_data_ready then
                last_received_byte := rx_byte;
                rx_count := rx_count + 1;
            end if;
            tx_data_ready_prev := tx_data_ready_buf;
        end if;
        mst2slv <= mst2slv_buf;
        tx_data_ready <= tx_data_ready_buf;
    end process;

    bus_master_tx : entity work.uart_bus_master_tx
    generic map (
        clk_period => clk_period,
        baud_rate => baud_rate
    ) port map (
        clk => clk,
        rst => rst,
        tx => tx,
        transmit_byte => tx_byte,
        data_ready => tx_data_ready,
        busy => tx_busy
    );

    bus_master_rx : entity work.uart_bus_master_rx
    generic map (
        clk_period => clk_period,
        baud_rate => baud_rate
    ) port map (
        clk => clk,
        rst => rst,
        rx => rx,
        receive_byte => rx_byte,
        data_ready => rx_data_ready
    );
end architecture;
