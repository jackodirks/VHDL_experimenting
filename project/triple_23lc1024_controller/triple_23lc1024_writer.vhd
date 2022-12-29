library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.triple_23lc1024_pkg.all;

entity triple_23lc1024_writer is
    generic (
        spi_clk_half_period_ticks : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        spi_clk : out std_logic;
        spi_sio : inout std_logic_vector(3 downto 0);

        cs_set : out std_logic;
        cs_state : in std_logic;

        ready : in std_logic;
        valid : out std_logic;
        active : out boolean;
        fault : in boolean;

        address : in bus_address_type;
        write_data : in bus_data_type;
        burst : in std_logic
    );
end triple_23lc1024_writer;

architecture behavioral of triple_23lc1024_writer is
    constant instructionWrite : std_logic_vector(7 downto 0) := "00000010";

    signal half_period_timer_rst : std_logic := '1';
    signal half_period_timer_done : std_logic;
begin

    process(rst, clk)
        variable count : natural := 0;
        variable valid_interal : std_logic := '0';
        variable cs_set_internal : std_logic := '1';
        variable transmitData : bus_data_type := (others => '0');
        variable burst_internal : std_logic := '0';
        variable transmitCommandAndAddress : std_logic_vector(31 downto 0) := (others => '0');
        constant max_count : natural := 16 + 2**(bus_data_width_log2b - 2) * 2;
        variable burst_transaction_complete : boolean := false;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                spi_clk <= '0';
                spi_sio <= (others => 'Z');
                cs_set_internal := '1';
                valid_interal := '0';
                active <= false;
                count := 0;
                burst_transaction_complete := false;
            else
                if half_period_timer_done = '1' then
                    count := count + 1;
                end if;

                if count mod 2 = 0 then
                    spi_clk <= '0';
                else
                    spi_clk <= '1';
                end if;

                if count = 0 then
                    burst_transaction_complete := false;
                    half_period_timer_rst <= '1';
                    spi_sio <= (others => 'Z');
                    if cs_set_internal = '1' then
                        valid_interal := '1';
                        active <= false;
                    else
                        active <= true;
                        valid_interal := '0';
                    end if;
                    if cs_set_internal = '1' and ready = '1' then
                        cs_set_internal := '0';
                        transmitCommandAndAddress := instructionWrite & "0000000" & address(16 downto 0);
                        transmitData := reorder_nibbles(write_data);
                        burst_internal := burst;
                        active <= true;
                    end if;
                    if cs_set_internal = '0' and cs_state = '0' then
                        spi_sio <= transmitCommandAndAddress(transmitCommandAndAddress'high downto transmitCommandAndAddress'high - 3);
                        half_period_timer_rst <= '0';
                        active <= true;
                    end if;
                end if;

                if count >= 1 and count <= 15 then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    active <= true;
                    valid_interal := '0';
                    if count mod 2 = 0 and half_period_timer_done = '1' then
                        transmitCommandAndAddress := std_logic_vector(shift_left(unsigned(transmitCommandAndAddress), 4));
                    end if;
                    spi_sio <= transmitCommandAndAddress(transmitCommandAndAddress'high downto transmitCommandAndAddress'high - 3);
                end if;

                if count = 16 then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    active <= true;
                    valid_interal := '0';
                    spi_sio <= transmitData(3 downto 0);
                end if;

                if count > 16 and count < max_count - 1 then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    active <= true;
                    valid_interal := '0';
                    if count mod 2 = 0 and half_period_timer_done = '1' then
                        transmitData := std_logic_vector(shift_right(unsigned(transmitData), 4));
                    end if;
                    spi_sio <= transmitData(3 downto 0);
                end if;

                if count = max_count - 1 then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    active <= true;
                    valid_interal := '0';
                    if burst_internal = '1' and not burst_transaction_complete and not fault then
                        valid_interal := '1';
                        if ready = '1' then
                            transmitData := reorder_nibbles(write_data);
                            burst_internal := burst;
                            burst_transaction_complete := true;
                        else
                            half_period_timer_rst <= '1';
                        end if;
                    end if;
                end if;

                if count = max_count then
                    half_period_timer_rst <= '0';
                    cs_set_internal := '0';
                    active <= true;
                    valid_interal := '0';
                    if burst_transaction_complete and not fault then
                        burst_transaction_complete := false;
                        count := 16;
                        spi_sio <= transmitData(3 downto 0);
                    else
                        half_period_timer_rst <= '1';
                        cs_set_internal := '1';
                        spi_sio <= (others => 'Z');
                        if cs_state = '1' then
                            count := 0;
                            active <= false;
                        end if;
                    end if;
                end if;
            end if;
        end if;
        cs_set <= cs_set_internal;
        valid <= valid_interal;
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
