library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg;

entity mips32_debug_controller is
    port (
        clk : in std_logic;
        rst : in std_logic;

        mst2debug : in bus_mst2slv_type;
        debug2mst : out bus_slv2mst_type;

        controllerReset : out boolean;
        controllerStall : out boolean
    );
end entity;

architecture behaviourial of mips32_debug_controller is
    signal regZero : mips32_pkg.data_type := (others => '0');

begin

    controllerReset <= regZero(0) = '1';
    controllerStall <= regZero(1) = '1';

    process(clk)
        variable debug2mst_buf : bus_slv2mst_type := BUS_SLV2MST_IDLE;
        variable regZero_buf : mips32_pkg.data_type := (0 => '1', others => '0');
        constant acceptableWriteMask : bus_write_mask_type := (others => '1');
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regZero_buf(0) := '1';
                regZero_buf(1) := '0';
                debug2mst_buf := BUS_SLV2MST_IDLE;
            elsif any_transaction(mst2debug, debug2mst_buf) then
                debug2mst_buf := BUS_SLV2MST_IDLE;
            elsif bus_requesting(mst2debug) then
                if mst2debug.address(1 downto 0) /= "00" then
                    debug2mst_buf.fault := '1';
                    debug2mst_buf.faultData := bus_fault_unaligned_access;
                elsif mst2debug.writeReady = '1' and mst2debug.writeMask /= acceptableWriteMask then
                    debug2mst_buf.fault := '1';
                    debug2mst_buf.faultData := bus_fault_illegal_write_mask;
                elsif mst2debug.address = X"00000000" then
                    if mst2debug.readReady = '1' then
                        debug2mst_buf.readData := regZero_buf;
                        debug2mst_buf.readValid := '1';
                    elsif mst2debug.writeReady = '1' then
                        regZero_buf := mst2debug.writeData;
                        debug2mst_buf.writeValid := '1';
                    end if;
                else
                    debug2mst_buf.fault := '1';
                    debug2mst_buf.faultData := bus_fault_address_out_of_range;
                end if;
            end if;
        end if;
        debug2mst <= debug2mst_buf;
        regZero <= regZero_buf;
    end process;
end behaviourial;
