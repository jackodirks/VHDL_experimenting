library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg;

entity mips32_if2bus is
    port (
        clk : in std_logic;
        rst : in std_logic;

        forbidBusInteraction : in boolean;
        flushCache : in boolean;

        mst2slv : out bus_mst2slv_type;
        slv2mst : in bus_slv2mst_type;

        hasFault : out boolean;
        faultData : out bus_fault_type;

        requestAddress : in mips32_pkg.address_type;
        instruction : out mips32_pkg.instruction_type;
        stall : out boolean
    );
end entity;

architecture behaviourial of mips32_if2bus is
    signal cachedAddress : mips32_pkg.address_type;
    signal cacheValid : boolean := false;

    signal stall_buf : boolean := false;

begin

    stall <= stall_buf;

    handleStall : process(cachedAddress, cacheValid, requestAddress)
    begin
        stall_buf <= not cacheValid or cachedAddress /= requestAddress;
    end process;

    handleBus : process(clk)
        variable mst2slv_buf : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        variable hasFault_buf : boolean := false;
        variable faultData_buf : bus_fault_type := bus_fault_no_fault;
        variable instruction_buf : mips32_pkg.instruction_type := (others => '0');
        variable transactionFinished_buf : boolean := false;
    begin
        if rising_edge(clk) then
            transactionFinished_buf := false;
            if rst = '1' then
                mst2slv_buf := BUS_MST2SLV_IDLE;
                hasFault_buf := false;
                faultData_buf := bus_fault_no_fault;
                cacheValid <= false;
            else
                if any_transaction(mst2slv_buf, slv2mst) then
                    if fault_transaction(mst2slv_buf, slv2mst) then
                        hasFault_buf := true;
                        faultData_buf := slv2mst.faultData;
                    elsif read_transaction(mst2slv_buf, slv2mst) then
                        instruction_buf := slv2mst.readData(instruction'range);
                        cacheValid <= true;
                        cachedAddress <= mst2slv_buf.address;
                    end if;
                    mst2slv_buf := BUS_MST2SLV_IDLE;
                elsif hasFault_buf or forbidBusInteraction then
                    -- Pass
                elsif stall_buf then
                    mst2slv_buf := bus_mst2slv_read(address => requestAddress);
                end if;

                if flushCache then
                    cacheValid <= false;
                end if;
            end if;
        end if;
        mst2slv <= mst2slv_buf;
        hasFault <= hasFault_buf;
        faultData <= faultData_buf;
        instruction <= instruction_buf;
    end process;

end architecture;
