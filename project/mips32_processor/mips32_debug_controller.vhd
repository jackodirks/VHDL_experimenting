library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.mips32_pkg;

entity mips32_debug_controller is
    port (
        clk : in std_logic;

        mst2debug : in bus_pkg.bus_mst2slv_type;
        debug2mst : out bus_pkg.bus_slv2mst_type;

        programCounter : in mips32_pkg.address_type
    );
end entity;

architecture behaviourial of mips32_debug_controller is
begin

    process(clk)
        variable debug2mst_buf : bus_pkg.bus_slv2mst_type := bus_pkg.BUS_SLV2MST_IDLE;
    begin
        if rising_edge(clk) then
            if bus_pkg.any_transaction(mst2debug, debug2mst_buf) then
                debug2mst_buf := bus_pkg.BUS_SLV2MST_IDLE;
            elsif bus_pkg.bus_requesting(mst2debug) then
                if mst2debug.address(1 downto 0) /= "00" then
                    debug2mst_buf.fault := '1';
                    debug2mst_buf.faultData := bus_pkg.bus_fault_unaligned_access;
                elsif mst2debug.address = X"00000000" then
                    if mst2debug.readReady = '1' then
                        debug2mst_buf.readValid := '1';
                        debug2mst_buf.readData := programCounter;
                    elsif mst2debug.writeReady = '1' then
                        -- Writes are silently ignored
                        debug2mst_buf.writeValid := '1';
                    end if;
                else
                    debug2mst_buf.fault := '1';
                    debug2mst_buf.faultData := bus_pkg.bus_fault_address_out_of_range;
                end if;
            end if;
        end if;
        debug2mst <= debug2mst_buf;
    end process;
end behaviourial;
