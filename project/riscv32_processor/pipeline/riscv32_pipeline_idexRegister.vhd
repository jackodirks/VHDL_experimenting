library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.riscv32_pkg.all;

entity riscv32_pipeline_idexRegister is
    port (
        clk : in std_logic;
        -- Control in
        stall : in boolean;
        nop : in boolean;
        -- Pipeline control in
        executeControlWordIn : in riscv32_ExecuteControlWord_type;
        memoryControlWordIn : in riscv32_MemoryControlWord_type;
        writeBackControlWordIn : in riscv32_WriteBackControlWord_type;
        -- Pipeline data in
        programCounterIn : in riscv32_address_type;
        rs1DataIn : in riscv32_data_type;
        rs1AddressIn : in riscv32_registerFileAddress_type;
        rs2DataIn : in riscv32_data_type;
        rs2AddressIn : in riscv32_registerFileAddress_type;
        immidiateIn : in riscv32_data_type;
        rdAddressIn : in riscv32_registerFileAddress_type;
        -- Pipeline control out
        executeControlWordOut : out riscv32_ExecuteControlWord_type;
        memoryControlWordOut : out riscv32_MemoryControlWord_type;
        writeBackControlWordOut : out riscv32_WriteBackControlWord_type;
        -- Pipeline data out
        programCounterOut : out riscv32_address_type;
        rs1DataOut : out riscv32_data_type;
        rs1AddressOut : out riscv32_registerFileAddress_type;
        rs2DataOut : out riscv32_data_type;
        rs2AddressOut : out riscv32_registerFileAddress_type;
        immidiateOut : out riscv32_data_type;
        rdAddressOut : out riscv32_registerFileAddress_type
    );
end entity;

architecture behaviourial of riscv32_pipeline_idexRegister is
begin
    process(clk)
        variable executeControlWord_var : riscv32_ExecuteControlWord_type := riscv32_executeControlWordAllFalse;
        variable memoryControlWord_var : riscv32_MemoryControlWord_type := riscv32_memoryControlWordAllFalse;
        variable writeBackControlWord_var : riscv32_WriteBackControlWord_type := riscv32_writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if nop and not stall then
                executeControlWord_var := riscv32_executeControlWordAllFalse;
                memoryControlWord_var := riscv32_memoryControlWordAllFalse;
                writeBackControlWord_var := riscv32_writeBackControlWordAllFalse;
            elsif not stall then
                executeControlWord_var := executeControlWordIn;
                memoryControlWord_var := memoryControlWordIn;
                writeBackControlWord_var := writeBackControlWordIn;
                programCounterOut <= programCounterIn;
                rs1DataOut <= rs1DataIn;
                rs1AddressOut <= rs1AddressIn;
                rs2DataOut <= rs2DataIn;
                rs2AddressOut <= rs2AddressIn;
                immidiateOut <= immidiateIn;
                rdAddressOut <= rdAddressIn;
            end if;
        end if;
        executeControlWordOut <= executeControlWord_var;
        memoryControlWordOut <= memoryControlWord_var;
        writeBackControlWordOut <= writeBackControlWord_var;
    end process;

end architecture;
