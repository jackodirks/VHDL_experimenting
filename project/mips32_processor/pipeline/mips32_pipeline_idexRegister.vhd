library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_idexRegister is
    port (
        clk : in std_logic;
        -- Control in
        stall : in boolean;
        nop : in boolean;
        -- Pipeline control in
        executeControlWordIn : in mips32_ExecuteControlWord_type;
        memoryControlWordIn : in mips32_MemoryControlWord_type;
        writeBackControlWordIn : in mips32_WriteBackControlWord_type;
        -- Pipeline data in
        programCounterPlusFourIn : in mips32_address_type;
        rsDataIn : in mips32_data_type;
        rsAddressIn : in mips32_registerFileAddress_type;
        rtDataIn : in mips32_data_type;
        rtAddressIn : in mips32_registerFileAddress_type;
        immidiateIn : in mips32_data_type;
        destinationRegIn : in mips32_registerFileAddress_type;
        rdAddressIn : in mips32_registerFileAddress_type;
        aluFunctionIn : in mips32_aluFunction_type;
        shamtIn : in mips32_shamt_type;
        -- Pipeline control out
        executeControlWordOut : out mips32_ExecuteControlWord_type;
        memoryControlWordOut : out mips32_MemoryControlWord_type;
        writeBackControlWordOut : out mips32_WriteBackControlWord_type;
        -- Pipeline data out
        programCounterPlusFourOut : out mips32_address_type;
        rsDataOut : out mips32_data_type;
        rsAddressOut : out mips32_registerFileAddress_type;
        rtDataOut : out mips32_data_type;
        rtAddressOut : out mips32_registerFileAddress_type;
        immidiateOut : out mips32_data_type;
        destinationRegOut : out mips32_registerFileAddress_type;
        rdAddressOut : out mips32_registerFileAddress_type;
        aluFunctionOut : out mips32_aluFunction_type;
        shamtOut : out mips32_shamt_type
    );
end entity;

architecture behaviourial of mips32_pipeline_idexRegister is
begin
    process(clk)
        variable executeControlWord_var : mips32_ExecuteControlWord_type := mips32_executeControlWordAllFalse;
        variable memoryControlWord_var : mips32_MemoryControlWord_type := mips32_memoryControlWordAllFalse;
        variable writeBackControlWord_var : mips32_WriteBackControlWord_type := mips32_writeBackControlWordAllFalse;
    begin
        if rising_edge(clk) then
            if nop and not stall then
                executeControlWord_var := mips32_executeControlWordAllFalse;
                memoryControlWord_var := mips32_memoryControlWordAllFalse;
                writeBackControlWord_var := mips32_writeBackControlWordAllFalse;
            elsif not stall then
                executeControlWord_var := executeControlWordIn;
                memoryControlWord_var := memoryControlWordIn;
                writeBackControlWord_var := writeBackControlWordIn;
                programCounterPlusFourOut <= programCounterPlusFourIn;
                rsDataOut <= rsDataIn;
                rsAddressOut <= rsAddressIn;
                rtDataOut <= rtDataIn;
                rtAddressOut <= rtAddressIn;
                immidiateOut <= immidiateIn;
                destinationRegOut <= destinationRegIn;
                rdAddressOut <= rdAddressIn;
                aluFunctionOut <= aluFunctionIn;
                shamtOut <= shamtIn;
            end if;
        end if;
        executeControlWordOut <= executeControlWord_var;
        memoryControlWordOut <= memoryControlWord_var;
        writeBackControlWordOut <= writeBackControlWord_var;
    end process;

end architecture;
