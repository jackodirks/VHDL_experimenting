library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_exmemRegister is
    port (
        clk : in std_logic;
        -- Control in
        stall : in boolean;
        nop : in boolean;
        -- Pipeline control in
        memoryControlWordIn : in mips32_MemoryControlWord_type;
        writeBackControlWordIn : in mips32_WriteBackControlWord_type;
        -- Pipeline data in
        execResultIn : in mips32_data_type;
        regDataReadIn : in mips32_data_type;
        destinationRegIn : in mips32_registerFileAddress_type;
        rdAddressIn : in mips32_registerFileAddress_type;
        has_branched_in : in boolean;
        -- Pipeline control out
        memoryControlWordOut : out mips32_MemoryControlWord_type;
        writeBackControlWordOut : out mips32_WriteBackControlWord_type;
        -- Pipeline data out
        execResultOut : out mips32_data_type;
        regDataReadOut : out mips32_data_type;
        destinationRegOut : out mips32_registerFileAddress_type;
        rdAddressOut : out mips32_registerFileAddress_type;
        has_branched_out : out boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_exmemRegister is
begin
    process(clk)
        variable memoryControlWordOut_buf : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
        variable writeBackControlWordOut_buf : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if nop and not stall then
                memoryControlWordOut_buf := mips32_memoryControlWordAllFalse;
                writeBackControlWordOut_buf := mips32_writeBackControlWordAllFalse;
            elsif not stall then
                memoryControlWordOut_buf := memoryControlWordIn;
                writeBackControlWordOut_buf := writeBackControlWordIn;
                execResultOut <= execResultIn;
                regDataReadOut <= regDataReadIn;
                destinationRegOut <= destinationRegIn;
                rdAddressOut <= rdAddressIn;
                has_branched_out <= has_branched_in;
            end if;
        end if;
        memoryControlWordOut <= memoryControlWordOut_buf;
        writeBackControlWordOut <= writeBackControlWordOut_buf;
    end process;
end architecture;
