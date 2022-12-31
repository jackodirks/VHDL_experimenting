library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library work;
use work.bus_pkg.all;

entity triple_23lc1024_controller is
    generic (
        system_clock_period : time;
        min_spi_clock_period : time := 50 ns;
        min_spi_cs_setup : time := 25 ns;
        min_spi_cs_hold : time := 50 ns
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        spi_clk : out std_logic;
        spi_sio_in : in std_logic_vector(3 downto 0);
        spi_sio_out : out std_logic_vector(3 downto 0);
        spi_cs : out std_logic_vector(2 downto 0);

        mst2slv : in bus_mst2slv_type;
        slv2mst : out bus_slv2mst_type
    );
end triple_23lc1024_controller;

architecture behavioral of triple_23lc1024_controller is
    constant min_spi_clk_half_period : time := min_spi_clock_period / 2;
    constant spi_clk_half_period_ticks : natural := (min_spi_clk_half_period + (system_clock_period - 1 fs))/(system_clock_period);
    constant spi_cs_setup_ticks : natural := (min_spi_cs_setup + (system_clock_period - 1 fs))/system_clock_period;
    constant spi_cs_hold_ticks : natural := (min_spi_cs_hold + (system_clock_period - 1 fs)) / system_clock_period;

    -- Config specific signals
    signal config_done : boolean := false;
    signal spi_clk_config : std_logic;
    signal spi_sio_config : std_logic_vector(3 downto 0);
    signal spi_cs_config : std_logic_vector(2 downto 0);

    -- Read specific signals
    signal read_active : boolean := false;
    signal spi_clk_read : std_logic;
    signal spi_sio_read_in : std_logic_vector(3 downto 0);
    signal spi_sio_read_out : std_logic_vector(3 downto 0);
    signal cs_set_read  : std_logic;
    signal ready_read : std_logic;
    signal valid_read : std_logic;
    signal fault_read : std_logic;
    signal faultData_read : bus_fault_type;

    -- CS control signals
    signal spi_cs_internal : std_logic_vector(2 downto 0);
    signal cs_n_requested : std_logic_vector(1 downto 0);
    signal cs_state : std_logic;
    signal cs_set : std_logic;

    -- Bus data
    signal address : bus_address_type;
    signal writeData : bus_data_type;
    signal writeMask : bus_write_mask;
    signal readData : bus_data_type;

    -- Bus control
    signal burst : std_logic;
begin

    bus_data_handling : process(mst2slv, readData)
    begin
    end process;

    bus_handling : process(mst2slv, valid_read, fault_read, faultData_read, config_done)
    begin
        slv2mst <= BUS_SLV2MST_IDLE;
        -- data
        address <= mst2slv.address;
        writeData <= mst2slv.writeData;
        writeMask <= mst2slv.writeMask;
        slv2mst.readData <= readData;
        slv2mst.faultData <= faultData_read;

        -- control
        burst <= mst2slv.burst;
        if config_done then
            ready_read <= mst2slv.readReady;
            slv2mst.fault <= fault_read;
            slv2mst.readValid <= valid_read;
        else
            ready_read <= '0';
        end if;
    end process;

    cs_control_handling : process(mst2slv, read_active)
    begin
        cs_n_requested <= mst2slv.address(18 downto 17);
        if read_active then
            cs_set <= cs_set_read;
        else
            cs_set <= '1';
        end if;
    end process;

    cs_mux : process(config_done, spi_cs_config, spi_cs_internal)
    begin
        if not config_done then
            spi_cs <= spi_cs_config;
        else
            spi_cs <= spi_cs_internal;
        end if;
    end process;

    other_spi_mux : process(config_done, read_active, spi_clk_config, spi_sio_config, spi_clk_read, spi_sio_read_out, spi_sio_in)
    begin
        if not config_done then
            spi_clk <= spi_clk_config;
            spi_sio_out <= spi_sio_config;
        elsif read_active then
            spi_clk <= spi_clk_read;
            spi_sio_out <= spi_sio_read_out;
            spi_sio_read_in <= spi_sio_in;
        else
            spi_clk <= '0';
            spi_sio_out <= (others => 'Z');
        end if;
    end process;

    config : entity work.triple_23lc1024_config
    generic map (
        cs_wait_ticks => spi_cs_hold_ticks,
        spi_clk_half_period_ticks => spi_clk_half_period_ticks
    )
    port map (
        clk => clk,
        rst => rst,
        spi_clk => spi_clk_config,
        spi_sio => spi_sio_config,
        spi_cs => spi_cs_config,
        config_done => config_done
    );

    reader : entity work.triple_23lc1024_reader
    generic map (
        spi_clk_half_period_ticks => spi_clk_half_period_ticks
    )
    port map (
        clk => clk,
        rst => rst,
        spi_clk => spi_clk_read,
        spi_sio_in => spi_sio_read_in,
        spi_sio_out => spi_sio_read_out,
        cs_set => cs_set_read,
        cs_state => cs_state,
        ready => ready_read,
        valid => valid_read,
        active => read_active,
        fault => fault_read,
        address => address,
        read_data => readData,
        burst => burst,
        faultData => faultData_read
    );

    cs_control : entity work.triple_23lc1024_cs_control
    generic map (
        spi_cs_setup_ticks => spi_cs_setup_ticks,
        spi_cs_hold_ticks => spi_cs_hold_ticks
    ) port map (
        clk => clk,
        cs_set => cs_set,
        cs_state => cs_state,
        cs_n_requested => cs_n_requested,
        spi_cs_n => spi_cs_internal
    );
end behavioral;
