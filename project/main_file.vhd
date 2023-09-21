library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;

entity main_file is
    generic (
        clk_period : time;
        baud_rate : positive := 115200
    );
    port (
        JA_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
        JB_gpio : out  STD_LOGIC_VECTOR (3 downto 0);
        clk : in  STD_LOGIC;
        global_reset : in std_logic;

        master_rx : in std_logic;
        master_tx : out std_logic
    );
end main_file;

architecture Behavioral of main_file is

    constant spiMemStartAddress : natural := 16#100000#;
    constant procStartAddress : bus_address_type := std_logic_vector(to_unsigned(spiMemStartAddress, bus_address_type'length));

    constant address_map : addr_range_and_mapping_array := (
        address_range_and_map(
            low => std_logic_vector(to_unsigned(16#2000#, bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#2100# - 1, bus_address_type'length)),
            mapping => bus_map_constant(bus_address_type'high - 8, '0') & bus_map_range(8, 0)
        ),
        address_range_and_map(
            low => std_logic_vector(to_unsigned(spiMemStartAddress, bus_address_type'length)),
            high => std_logic_vector(to_unsigned(16#160000# - 1, bus_address_type'length)),
            mapping => bus_map_constant(bus_address_type'high - 18, '0') & bus_map_range(18, 0)
        )
    );

    signal rst          : STD_LOGIC;

    signal extMaster2arbiter : bus_mst2slv_type;
    signal arbiter2extMaster : bus_slv2mst_type;

    signal instructionFetch2arbiter : bus_mst2slv_type;
    signal arbiter2instructionFetch : bus_slv2mst_type;

    signal memory2arbiter : bus_mst2slv_type;
    signal arbiter2memory : bus_slv2mst_type;

    signal arbiter2demux : bus_mst2slv_type;
    signal demux2arbiter : bus_slv2mst_type;

    signal demux2spimem : bus_mst2slv_type;
    signal spimem2demux : bus_slv2mst_type;

    signal demux2control : bus_mst2slv_type;
    signal control2demux : bus_slv2mst_type;

    signal mem_spi_sio_out : std_logic_vector(3 downto 0);
    signal mem_spi_sio_in : std_logic_vector(3 downto 0);
    signal mem_spi_cs_n : std_logic_vector(2 downto 0);
    signal mem_spi_clk : std_logic;

begin

    rst <= global_reset;

    mem_spi_sio_in <= JA_gpio;
    JA_gpio <= mem_spi_sio_out;
    JB_gpio(3 downto 1) <= mem_spi_cs_n;
    JB_gpio(0) <= mem_spi_clk;

    externalMaster : entity work.uart_bus_master
    generic map (
        clk_period => clk_period,
        baud_rate => baud_rate
    ) port map (
        rst => rst,
        clk => clk,
        mst2slv => extMaster2arbiter,
        slv2mst => arbiter2extMaster,
        rx => master_rx,
        tx => master_tx
    );

    processor : entity work.mips32_processor
    generic map (
        startAddress => procStartAddress,
        clk_period => clk_period,
        iCache_range => address_map(1).addr_range,
        iCache_word_count_log2b => 8,
        dCache_range => address_map(1).addr_range,
        dCache_word_count_log2b => 8
    ) port map (
        clk => clk,
        rst => rst,
        mst2control => demux2control,
        control2mst => control2demux,
        instructionFetch2slv => instructionFetch2arbiter,
        slv2instructionFetch => arbiter2instructionFetch,
        memory2slv => memory2arbiter,
        slv2memory => arbiter2memory
    );

    arbiter : entity work.bus_arbiter
    generic map (
        masterCount => 3
   ) port map (
        clk => clk,
        mst2arbiter(0) => instructionFetch2arbiter,
        mst2arbiter(1) => memory2arbiter,
        mst2arbiter(2) => extMaster2arbiter,
        arbiter2mst(0) => arbiter2instructionFetch,
        arbiter2mst(1) => arbiter2memory,
        arbiter2mst(2) => arbiter2extMaster,
        arbiter2slv => arbiter2demux,
        slv2arbiter => demux2arbiter
    );

    demux : entity work.bus_demux
    generic map (
        ADDRESS_MAP => address_map
    )
    port map (
        mst2demux => arbiter2demux,
        demux2mst => demux2arbiter,
        demux2slv(0) => demux2control,
        demux2slv(1) => demux2spimem,
        slv2demux(0) => control2demux,
        slv2demux(1) => spimem2demux
    );

    spimem : entity work.triple_23lc1024_controller
    generic map (
        system_clock_period => clk_period
    ) port map (
        clk => clk,
        rst => rst,
        spi_clk => mem_spi_clk,
        spi_sio_in => mem_spi_sio_in,
        spi_sio_out => mem_spi_sio_out,
        spi_cs => mem_spi_cs_n,
        mst2slv => demux2spimem,
        slv2mst => spimem2demux
    );
end Behavioral;
