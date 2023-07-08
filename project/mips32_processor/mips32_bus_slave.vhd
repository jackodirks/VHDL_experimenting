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

        controllerReset : out boolean;
        controllerStall : out boolean
    );
end entity;

architecture behaviourial of mips32_bus_slave is
    signal regZero : mips32_data_type := (others => '0');

begin

    controllerReset <= regZero(0) = '1';
    controllerStall <= regZero(1) = '1';

    process(clk)
        variable slv2mst_buf : bus_slv2mst_type := BUS_SLV2MST_IDLE;
        variable regZero_buf : mips32_data_type := (0 => '1', others => '0');
        constant acceptableWriteMask : bus_byte_mask_type := (others => '1');
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regZero_buf(0) := '1';
                regZero_buf(1) := '0';
                slv2mst_buf := BUS_SLV2MST_IDLE;
            elsif any_transaction(mst2slv, slv2mst_buf) then
                slv2mst_buf := BUS_SLV2MST_IDLE;
            elsif bus_requesting(mst2slv) then
                if mst2slv.address(1 downto 0) /= "00" then
                    slv2mst_buf.fault := '1';
                    slv2mst_buf.faultData := bus_fault_unaligned_access;
                elsif mst2slv.writeReady = '1' and mst2slv.byteMask /= acceptableWriteMask then
                    slv2mst_buf.fault := '1';
                    slv2mst_buf.faultData := bus_fault_illegal_byte_mask;
                elsif mst2slv.address = X"00000000" then
                    if mst2slv.readReady = '1' then
                        slv2mst_buf.readData := regZero_buf;
                        slv2mst_buf.readValid := '1';
                    elsif mst2slv.writeReady = '1' then
                        regZero_buf := mst2slv.writeData;
                        slv2mst_buf.writeValid := '1';
                    end if;
                else
                    slv2mst_buf.fault := '1';
                    slv2mst_buf.faultData := bus_fault_address_out_of_range;
                end if;
            end if;
        end if;
        slv2mst <= slv2mst_buf;
        regZero <= regZero_buf;
    end process;
end behaviourial;
