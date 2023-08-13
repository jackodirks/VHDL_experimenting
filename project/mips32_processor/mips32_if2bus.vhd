library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_if2bus is
    generic (
        rangeMap : addr_range_and_mapping_type;
        word_count_log2b : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        forbidBusInteraction : in boolean;
        flushCache : in boolean;

        mst2slv : out bus_mst2slv_type;
        slv2mst : in bus_slv2mst_type;

        hasFault : out boolean;
        faultData : out bus_fault_type;

        requestAddress : in mips32_address_type;
        instruction : out mips32_instruction_type;
        stall : out boolean
    );
end entity;

architecture behaviourial of mips32_if2bus is
    signal instruction_from_bus : mips32_instruction_type;
    signal icache_write : boolean := false;
    signal icache_miss : boolean;
    signal icache_fault : boolean;
    signal icache_flush : boolean;
    signal icache_reset : std_logic;

begin

    stall <= icache_miss or icache_fault;
    icache_reset <= '1' when flushCache or rst = '1' else '0';

    handleBus : process(clk)
        variable mst2slv_buf : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        variable hasFault_buf : boolean := false;
        variable faultData_buf : bus_fault_type := bus_fault_no_fault;
        variable transactionFinished_buf : boolean := false;
    begin
        if rising_edge(clk) then
            transactionFinished_buf := false;
            icache_flush <= false;
            if rst = '1' then
                mst2slv_buf := BUS_MST2SLV_IDLE;
                hasFault_buf := false;
                faultData_buf := bus_fault_no_fault;
            else
                if icache_fault then
                    hasFault_buf := true;
                    faultData_buf := bus_fault_address_out_of_range;
                end if;

                if icache_write then
                    icache_write <= false;
                elsif any_transaction(mst2slv_buf, slv2mst) then
                    if fault_transaction(mst2slv_buf, slv2mst) then
                        hasFault_buf := true;
                        faultData_buf := slv2mst.faultData;
                    elsif read_transaction(mst2slv_buf, slv2mst) then
                        instruction_from_bus <= slv2mst.readData(instruction'range);
                        icache_write <= true;
                    end if;
                    mst2slv_buf := BUS_MST2SLV_IDLE;
                elsif hasFault_buf or forbidBusInteraction then
                    -- Pass
                elsif icache_miss then
                    mst2slv_buf := bus_mst2slv_read(address => requestAddress);
                end if;
            end if;
        end if;
        mst2slv <= mst2slv_buf;
        hasFault <= hasFault_buf;
        faultData <= faultData_buf;
    end process;

    icache : entity work.mips32_icache
    generic map (
        word_count_log2b => word_count_log2b,
        rangeMap => rangeMap
    ) port map (
        clk => clk,
        rst => icache_reset,
        requestAddress => requestAddress,
        instructionOut => instruction,
        instructionIn => instruction_from_bus,
        doWrite => iCache_write,
        fault => icache_fault,
        miss => icache_miss
    );

end architecture;
