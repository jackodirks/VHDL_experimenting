library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.riscv32_pkg.all;

entity riscv32_pipeline_memwbRegister is
    port (
        clk : in std_logic;
        -- Control in
        stall : in boolean;
        nop : in boolean;
        -- Pipeline control in
        writeBackControlWordIn : in riscv32_WriteBackControlWord_type;
        -- Pipeline data in
        execResultIn : in riscv32_data_type;
        memDataReadIn : in riscv32_data_type;
        rdAddressIn : in riscv32_registerFileAddress_type;
        -- Pipeline control out
        writeBackControlWordOut : out riscv32_WriteBackControlWord_type;
        -- Pipeline data out
        execResultOut : out riscv32_data_type;
        memDataReadOut : out riscv32_data_type;
        rdAddressOut : out riscv32_registerFileAddress_type
    );
end entity;

architecture behaviourial of riscv32_pipeline_memWbRegister is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if nop and not stall then
                writeBackControlWordOut <= riscv32_writeBackControlWordAllFalse;
            elsif not stall then
                writeBackControlWordOut <= writeBackControlWordIn;
                execResultOut <= execResultIn;
                memDataReadOut <= memDataReadIn;
                rdAddressOut <= rdAddressIn;
            end if;
        end if;
    end process;
end architecture;
