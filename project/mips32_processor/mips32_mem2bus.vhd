library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_mem2bus is
    port (
        clk : in std_logic;
        rst : in std_logic;

        forbidBusInteraction : in boolean;
        flushCache : in boolean;

        mst2slv : out bus_mst2slv_type;
        slv2mst : in bus_slv2mst_type;

        hasFault : out boolean;
        faultData : out bus_fault_type;

        address : in mips32_address_type;
        dataIn : in mips32_data_type;
        dataOut : out mips32_data_type;
        doWrite : in boolean;
        doRead : in boolean;

        stall : out boolean
    );
end entity;

architecture behaviourial of mips32_mem2bus is
    signal stall_buf : boolean := false;
    signal read_stall : boolean := false;
    signal write_stall : boolean := false;

    -- Read cache
    signal read_cache_valid : boolean := false;
    signal read_cache_address : mips32_address_type;
    signal read_cache_data : mips32_data_type;

    -- Write cache
    signal write_cache_valid : boolean := false;
    signal write_cache_address : mips32_address_type;
    signal write_cache_data : mips32_data_type;
begin
    stall_buf <= read_stall or write_stall;
    stall <= stall_buf;

    read_handling : process(doRead, address, read_cache_valid, read_cache_address, read_cache_data)
    begin
        read_stall <= false;
        if doRead then
            if read_cache_valid and read_cache_address = address then
                dataOut <= read_cache_data;
            else
                read_stall <= true;
            end if;
        end if;
    end process;

    write_handling : process(doWrite, address, dataIn, write_cache_valid, write_cache_address, write_cache_data)
    begin
        write_stall <= false;
        if doWrite then
            write_stall <= not (write_cache_valid and address = write_cache_address and dataIn = write_cache_data);
        end if;
    end process;

    bus_handling : process(clk)
        variable mst2slv_buf : bus_mst2slv_type := BUS_MST2SLV_IDLE;
        variable hasFault_buf : boolean := false;
        variable bus_active : boolean := false;
        constant fullWordWriteMask : bus_write_mask_type := (others => '1');
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mst2slv_buf := BUS_MST2SLV_IDLE;
                hasFault_buf := false;
                bus_active := false;
                read_cache_valid <= false;
                write_cache_valid <= false;
            elsif any_transaction(mst2slv_buf, slv2mst) then
                if fault_transaction(mst2slv_buf, slv2mst) then
                    hasFault_buf := true;
                    faultData <= slv2mst.faultData;
                elsif read_transaction(mst2slv_buf, slv2mst) then
                    bus_active := false;
                    read_cache_valid <= true;
                    read_cache_address <= mst2slv_buf.address;
                    read_cache_data <= slv2mst.readData;
                elsif write_transaction(mst2slv_buf, slv2mst) then
                    bus_active := false;
                    write_cache_valid <= true;
                    write_cache_address <= mst2slv_buf.address;
                    write_cache_data <= mst2slv_buf.writeData;
                end if;
                mst2slv_buf := BUS_MST2SLV_IDLE;
            elsif stall_buf and not bus_active and not hasFault_buf and not forbidBusInteraction then
                bus_active := true;
                if doRead then
                    mst2slv_buf := bus_mst2slv_read(address => address);
                elsif doWrite then
                    read_cache_valid <= false;
                    mst2slv_buf := bus_mst2slv_write(address => address,
                                                             write_data => dataIn,
                                                             write_mask => fullWordWriteMask);
                end if;
            elsif not stall_buf and not doRead and not doWrite then
                read_cache_valid <= false;
                write_cache_valid <= false;
            end if;

            if flushCache then
                read_cache_valid <= false;
                write_cache_valid <= false;
            end if;
        end if;
        mst2slv <= mst2slv_buf;
        hasFault <= hasFault_buf;
    end process;

end architecture;
