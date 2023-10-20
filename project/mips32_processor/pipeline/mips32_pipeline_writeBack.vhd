library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_pipeline_writeBack is
    port (
        -- From mem stage: control signals
        writeBackControlWord : in mips32_WriteBackControlWord_type;

        -- From mem stage: data
        execResult : in mips32_data_type;
        memDataRead : in mips32_data_type;
        destinationReg : in mips32_registerFileAddress_type;
        has_branched : in boolean;

        -- To instruction decode: regWrite
        regWrite : out boolean;
        regWriteAddress : out mips32_registerFileAddress_type;
        regWriteData : out mips32_data_type
    );
end entity;

architecture behaviourial of mips32_pipeline_writeBack is
begin
    process(writeBackControlWord, execResult, destinationReg, memDataRead, has_branched)
    begin
        regWrite <= writeBackControlWord.regWrite or (writeBackControlWord.write_on_branch and has_branched);
        regWriteAddress <= destinationReg;
        if writeBackControlWord.MemtoReg then
            regWriteData <= memDataRead;
        else
            regWriteData <= execResult;
        end if;
    end process;

end architecture;
