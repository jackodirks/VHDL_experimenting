library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.mips32_pkg;

entity mips32_pipeline_writeBack is
    port (
        -- From mem stage: control signals
        writeBackControlWord : in mips32_pkg.WriteBackControlWord_type;

        -- From mem stage: control signals
        aluResult : in mips32_pkg.data_type;
        memDataRead : in mips32_pkg.data_type;
        destinationReg : in mips32_pkg.registerFileAddress_type;

        -- To instruction decode: regWrite
        regWrite : out boolean;
        regWriteAddress : out mips32_pkg.registerFileAddress_type;
        regWriteData : out mips32_pkg.data_type
    );
end entity;

architecture behaviourial of mips32_pipeline_writeBack is
begin
    process(writeBackControlWord, aluResult, destinationReg)
    begin
        regWrite <= writeBackControlWord.regWrite;
        regWriteAddress <= destinationReg;
        if writeBackControlWord.MemtoReg then
            regWriteData <= memDataRead;
        else
            regWriteData <= aluResult;
        end if;
    end process;

end architecture;
