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

    type command_type is (no_command, command_read_word, command_write_word);

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
            when uart_bus_master_pkg.COMMAND_WRITE_WORD =>
                ret_val := command_write_word;
            when others =>
                ret_val := no_command;
        end case;
        return ret_val;
    end function;

    signal bytes_received : natural := 0;
    signal last_received_byte : std_logic_vector(7 downto 0) := (others => 'X');

    signal active_command : command_type := no_command;
    signal command_decoded : boolean := false;

    signal bytes_transmitted : natural := 0;
    signal byte_ready_for_transmission : std_logic_vector(7 downto 0) := (others => 'X');
    signal transmission_waiting : boolean := false;

    signal clear_internal_state : boolean := false;

    signal reset_internal_state : boolean := false;

    signal bus_address : bus_pkg.bus_address_type := (others => 'X');
    signal bus_address_ready : boolean := false;

    signal bus_write_data : bus_pkg.bus_data_type := (others => 'X');
    signal bus_write_data_ready : boolean := false;

    signal bus_transaction_complete : boolean := false;
    signal slv2mst_buf : bus_pkg.bus_slv2mst_type := bus_pkg.BUS_SLV2MST_IDLE;

begin

    reset_internal_state <= clear_internal_state or rst = '1';

    byte_receiver : process(clk)
    begin
        if rising_edge(clk) then
            if reset_internal_state then
                bytes_received <= 0;
            elsif rx_data_ready then
                last_received_byte <= rx_byte;
                bytes_received <= bytes_received + 1;
            end if;
        end if;
    end process;

    byte_transmitter : process(clk)
        variable tx_data_ready_buf : boolean := false;
        variable tx_data_ready_prev : boolean := false;
    begin
        if rising_edge(clk) then
            tx_data_ready_buf := false;
            if reset_internal_state then
                bytes_transmitted <= 0;
            elsif transmission_waiting and not tx_data_ready_prev and not tx_busy then
                tx_byte <= byte_ready_for_transmission;
                tx_data_ready_buf := true;
                bytes_transmitted <= bytes_transmitted + 1;
            end if;
            tx_data_ready_prev := tx_data_ready_buf;
        end if;
        tx_data_ready <= tx_data_ready_buf;
    end process;

    command_decoder : process(clk)
    begin
        if rising_edge(clk) then
            if reset_internal_state then
                command_decoded <= false;
                active_command <= no_command;
            elsif bytes_received = 1 then
                active_command <= translateCommand(last_received_byte);
                command_decoded <= true;
            end if;
        end if;
    end process;

    transmission_manager : process(clk)
    begin
        if rising_edge(clk) then
            clear_internal_state <= false;
            transmission_waiting <= false;
            if reset_internal_state then
                -- pass
            elsif command_decoded and bytes_transmitted = 0 then
                if active_command = no_command then
                    byte_ready_for_transmission <= uart_bus_master_pkg.ERROR_UNKOWN_COMMAND;
                else
                    byte_ready_for_transmission <= uart_bus_master_pkg.ERROR_NO_ERROR;
                end if;
                transmission_waiting <= true;
            elsif bytes_transmitted = 1 and active_command = no_command then
                clear_internal_state <= true;
            elsif bus_transaction_complete then
                transmission_waiting <= true;
                if bytes_transmitted = 1 then
                    if slv2mst_buf.fault = '1' then
                        byte_ready_for_transmission <= (7 downto 4 => slv2mst_buf.faultData,
                                                    3 downto 0 => uart_bus_master_pkg.ERROR_BUS(3 downto 0));
                    else
                        byte_ready_for_transmission <= uart_bus_master_pkg.ERROR_NO_ERROR;
                    end if;
                elsif bytes_transmitted = 2 and (slv2mst_buf.fault = '1' or active_command = command_write_word) then
                    clear_internal_state <= true;
                elsif bytes_transmitted > 1 and bytes_transmitted <= 5 then
                    byte_ready_for_transmission <= slv2mst_buf.readData((bytes_transmitted - 2)*8 + 7 downto (bytes_transmitted - 2)*8);
                end if;
            end if;
        end if;
    end process;

    address_receiver : process(clk)
    begin
        if rising_edge(clk) then
            if bytes_received > 1 and bytes_received <= 5 then
                bus_address((bytes_received - 2)*8 + 7 downto (bytes_received - 2)*8) <= last_received_byte;
            end if;
            if reset_internal_state then
                bus_address_ready <= false;
            elsif bytes_received = 5 then
                bus_address_ready <= true;
            end if;
        end if;
    end process;

    data_receiver : process(clk)
    begin
        if rising_edge(clk) then
            if bytes_received > 5 and bytes_received <= 9 then
                bus_write_data((bytes_received - 6)*8 + 7 downto (bytes_received - 6)*8) <= last_received_byte;
            end if;
            if reset_internal_state then
                bus_write_data_ready <= false;
            elsif bytes_received = 9 then
                bus_write_data_ready <= true;
            end if;
        end if;
    end process;


    bus_manager : process(clk)
        variable bus_transaction_started : boolean := false;
        variable mst2slv_buf : bus_pkg.bus_mst2slv_type := bus_pkg.BUS_MST2SLV_IDLE;
    begin
        if rising_edge(clk) then
            if reset_internal_state then
                bus_transaction_started := false;
                mst2slv_buf := bus_pkg.BUS_MST2SLV_IDLE;
                bus_transaction_complete <= false;
                slv2mst_buf <= bus_pkg.BUS_SLV2MST_IDLE;
            elsif active_command = command_read_word and bus_address_ready and not bus_transaction_started then
                mst2slv_buf := bus_pkg.bus_mst2slv_read(bus_address);
                bus_transaction_started := true;
            elsif active_command = command_write_word and bus_write_data_ready and not bus_transaction_started then
                mst2slv_buf := bus_pkg.bus_mst2slv_write(bus_address, bus_write_data, x"f");
                bus_transaction_started := true;
            elsif bus_pkg.any_transaction(mst2slv_buf, slv2mst) then
                slv2mst_buf <= slv2mst;
                mst2slv_buf := bus_pkg.BUS_MST2SLV_IDLE;
                bus_transaction_complete <= true;
            end if;
        end if;
        mst2slv <= mst2slv_buf;
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
