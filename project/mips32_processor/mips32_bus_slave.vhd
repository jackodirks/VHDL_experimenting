library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_bus_slave is
    port (
        clk : in std_logic;
        rst : in std_logic;

        mst2slv : in bus_mst2slv_type;
        slv2mst : out bus_slv2mst_type;

        address_to_cpz : out natural range 0 to 31;
        write_to_cpz : out boolean;
        data_to_cpz : out mips32_data_type;
        data_from_cpz : in mips32_data_type
    );
end entity;

architecture behaviourial of mips32_bus_slave is
begin

    process(clk)
        variable slv2mst_buf : bus_slv2mst_type := BUS_SLV2MST_IDLE;
        variable internal_transaction : boolean := false;
        variable has_fault : boolean := false;
        variable fault_data : bus_fault_type;
    begin
        if rising_edge(clk) then
            write_to_cpz <= false;
            if rst = '1' then
                slv2mst_buf := BUS_SLV2MST_IDLE;
                has_fault := false;
                internal_transaction := false;
                write_to_cpz <= false;
            elsif any_transaction(mst2slv, slv2mst_buf) then
                slv2mst_buf := BUS_SLV2MST_IDLE;
            elsif has_fault then
                has_fault := false;
                slv2mst_buf.fault := '1';
                slv2mst_buf.faultData := fault_data;
            elsif internal_transaction then
                internal_transaction := false;
                slv2mst_buf.readValid := '1';
                slv2mst_buf.writeValid := '1';
                slv2mst_buf.readData := data_from_cpz;
            elsif bus_requesting(mst2slv) then
                if mst2slv.address(1 downto 0) /= "00" then
                    has_fault := true;
                    fault_data := bus_fault_unaligned_access;
                elsif mst2slv.bytemask /= "1111" then
                    has_fault := true;
                    fault_data := bus_fault_illegal_byte_mask;
                else
                    address_to_cpz <= to_integer(unsigned(mst2slv.address(7 downto 2)));
                    data_to_cpz <= mst2slv.writeData;
                    write_to_cpz <= mst2slv.writeReady = '1';
                    internal_transaction := true;
                end if;
            end if;
        end if;
        slv2mst <= slv2mst_buf;
    end process;

end behaviourial;
