library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_memwbRegister is
    port (
        clk : in std_logic;
        -- Control in
        stall : in boolean;
        nop : in boolean;
        -- Pipeline control in
        writeBackControlWordIn : in mips32_WriteBackControlWord_type;
        -- Pipeline data in
        execResultIn : in mips32_data_type;
        memDataReadIn : in mips32_data_type;
        destinationRegIn : in mips32_registerFileAddress_type;
        regWrite_override_in : in boolean;
        -- Pipeline control out
        writeBackControlWordOut : out mips32_WriteBackControlWord_type;
        -- Pipeline data out
        execResultOut : out mips32_data_type;
        memDataReadOut : out mips32_data_type;
        destinationRegOut : out mips32_registerFileAddress_type;
        regWrite_override_out : out boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_memWbRegister is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if nop and not stall then
                writeBackControlWordOut <= mips32_writeBackControlWordAllFalse;
                regWrite_override_out <= false;
            elsif not stall then
                writeBackControlWordOut <= writeBackControlWordIn;
                execResultOut <= execResultIn;
                memDataReadOut <= memDataReadIn;
                destinationRegOut <= destinationRegIn;
                regWrite_override_out <= regWrite_override_in;
            end if;
        end if;
    end process;
end architecture;
