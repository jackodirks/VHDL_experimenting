library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.triple_23lc1024_pkg.all;

entity triple_23lc1024_reader is
    generic (
        spi_clk_half_period_ticks : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        spi_clk : out std_logic;
        spi_sio_in : in std_logic_vector(3 downto 0);
        spi_sio_out : out std_logic_vector(3 downto 0);

        cs_set : out std_logic;
        cs_state : in std_logic;

        ready : in std_logic;
        valid : out std_logic;
        active : out boolean;
        fault : out std_logic;

        address : in bus_address_type;
        read_data : out bus_data_type;
        burst : in std_logic;
        faultData : out bus_fault_type
    );
end triple_23lc1024_reader;

architecture behavioral of triple_23lc1024_reader is
    constant instructionRead : std_logic_vector(7 downto 0) := "00000011";

    signal half_period_timer_rst : std_logic := '1';
    signal half_period_timer_done : std_logic;

    procedure detect_fault (
        variable fault_internal : out std_logic;
        signal faultData_internal : out std_logic_vector(faultData'range))
    is
        constant expBusAlignment : std_logic_vector(bus_bytes_per_word_log2b - 1 downto 0) := (others => '0');
    begin
        fault_internal := '0';
        if address(expBusAlignment'range) /= expBusAlignment then
            fault_internal := '1';
            faultData_internal <= bus_fault_unaligned_access;
        elsif burst = '1' and not is_address_legal_for_burst(address) then
            fault_internal := '1';
            faultData_internal <= bus_fault_illegal_address_for_burst;
        end if;
    end detect_fault;
begin

    process(clk)
        constant max_count : natural := 20 + 2**(bus_data_width_log2b - 2) * 2;
        variable count : natural range 0 to max_count := 0;
        variable cs_set_internal : std_logic := '1';
        variable fault_internal : std_logic := '0';
        variable read_data_internal : bus_data_type := (others => '0');
        variable transmitCommandAndAddress : std_logic_vector(31 downto 0) := (others => '0');
        variable transaction_complete : boolean := false;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                spi_clk <= '0';
                spi_sio_out <= (others => 'Z');
                cs_set_internal := '1';
                valid <= '0';
                active <= false;
                count := 0;
                transaction_complete := false;
            else
                if half_period_timer_done = '1' then
                    count := count + 1;
                end if;

                if count mod 2 = 0 then
                    spi_clk <= '0';
                else
                    spi_clk <= '1';
                end if;

                if cs_set_internal = '0' then
                    active <= true;
                else
                    active <= false;
                end if;

                if count = 0 then
                    transaction_complete := false;
                    half_period_timer_rst <= '1';
                    spi_sio_out <= (others => 'Z');
                    valid <= '0';
                    if fault_internal = '1' then
                        fault_internal := '0';
                    elsif cs_set_internal = '1' and ready = '1' then
                        transmitCommandAndAddress := instructionRead & "0000000" & address(16 downto 0);
                        detect_fault(fault_internal => fault_internal, faultData_internal => faultData);
                        if fault_internal = '0' then
                            cs_set_internal := '0';
                        end if;
                    elsif cs_set_internal = '0' and cs_state = '0' then
                        spi_sio_out <= transmitCommandAndAddress(transmitCommandAndAddress'high downto transmitCommandAndAddress'high - 3);
                        half_period_timer_rst <= '0';
                    end if;
                end if;

                if count > 0 then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    valid <= '0';
                    fault_internal := '0';
                end if;

                if count >= 1 and count <= 15 then
                    if count mod 2 = 0 and half_period_timer_done = '1' then
                        transmitCommandAndAddress := std_logic_vector(shift_left(unsigned(transmitCommandAndAddress), 4));
                    end if;
                    spi_sio_out <= transmitCommandAndAddress(transmitCommandAndAddress'high downto transmitCommandAndAddress'high - 3);
                end if;

                if count > 15 then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    valid <= '0';
                    fault_internal := '0';
                    spi_sio_out <= (others => 'Z');
                end if;
                -- now we get a dummy byte. Also the point where we continue from when doing a burst.
                if count >= 16 and count <= 20 then
                    transaction_complete := false;
                end if;

                -- Now the incoming data, which we read on the rising edge (= when count is uneven)
                if count > 20 and count < max_count - 1 then
                    if count mod 2 = 1 and half_period_timer_done = '1' then
                        read_data_internal(read_data_internal'high downto read_data_internal'high - 3) := spi_sio_in;
                    end if;
                    if count mod 2 = 0 and half_period_timer_done = '1' then
                        read_data_internal := std_logic_vector(shift_right(unsigned(read_data_internal), 4));
                    end if;
                end if;

                if count = max_count - 1 then
                    if half_period_timer_done = '1' then
                        read_data_internal(read_data_internal'high downto read_data_internal'high - 3) := spi_sio_in;
                    end if;
                    if not transaction_complete then
                        if ready = '1' then
                            valid <= '1';
                            transaction_complete := true;
                            detect_fault(fault_internal => fault_internal, faultData_internal => faultData);
                            if fault_internal = '0' and burst = '1' then
                                count := 19;
                            end if;
                        else
                            half_period_timer_rst <= '1';
                        end if;
                    end if;
                end if;

                if count = max_count then
                    half_period_timer_rst <= '1';
                    cs_set_internal := '1';
                    transaction_complete := false;
                    active <= true;
                    if cs_state = '1' then
                        count := 0;
                    end if;
                end if;
            end if;
        end if;
        cs_set <= cs_set_internal;
        read_data <= reorder_nibbles(read_data_internal);
        fault <= fault_internal;
    end process;

    half_period_timer : entity work.simple_multishot_timer
    generic map (
        match_val => spi_clk_half_period_ticks
    )
    port map (
        clk => clk,
        rst => half_period_timer_rst,
        done => half_period_timer_done
    );
end behavioral;

