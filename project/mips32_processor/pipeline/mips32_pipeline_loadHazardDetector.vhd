library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mips32_pkg.all;

entity mips32_pipeline_loadHazardDetector is
    port (
        executeControlWordFromID : in mips32_ExecuteControlWord_type;
        writeBackControlWordFromEx : in mips32_WriteBackControlWord_type;
        targetRegFromEx : in mips32_registerFileAddress_type;
        readPortOneAddressFromID : in mips32_registerFileAddress_type;
        readPortTwoAddressFromID : in mips32_registerFileAddress_type;

        loadHazardDetected : out boolean
    );
end entity;

architecture behaviourial of mips32_pipeline_loadHazardDetector is
    signal loadHazardPortOne : boolean;
    signal loadHazardPortTwo : boolean;
begin
    loadHazardPortOne <= targetRegFromEx = readPortOneAddressFromID;
    loadHazardPortTwo <= targetRegFromEx = readPortTwoAddressFromID and not executeControlWordFromID.ALUSrc;

    loadHazardDetected <= (loadHazardPortOne or loadHazardPortTwo) and writeBackControlWordFromEx.memToReg and targetRegFromEx /= 0;
end architecture;
