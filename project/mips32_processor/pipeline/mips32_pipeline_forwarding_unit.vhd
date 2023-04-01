library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.mips32_pkg;

entity mips32_pipeline_forwarding_unit is
    port (
        rsDataFromID : in mips32_pkg.data_type;
        rsAddressFromID : in mips32_pkg.registerFileAddress_type;
        regDataBFromID : in mips32_pkg.data_type;
        regAddressBFromID : in mips32_pkg.registerFileAddress_type;

        regDataFromEx : in mips32_pkg.data_type;
        regAddressFromEx : in mips32_pkg.registerFileAddress_type;
        regWriteFromEx : in boolean;

        regDataFromMem : in mips32_pkg.data_type;
        regAddressFromMem : in mips32_pkg.registerFileAddress_type;
        regWriteFromMem : in boolean;

        rsData : out mips32_pkg.data_type;
        regDataB : out mips32_pkg.data_type
    );
end entity;

architecture behaviourial of mips32_pipeline_forwarding_unit is
begin
    determineRsData : process(rsDataFromID, rsAddressFromID, regDataFromEx, regAddressFromEx, regWriteFromEx,
                                regDataFromMem, regAddressFromMem, regWriteFromMem)
    begin
        if rsAddressFromID = 0 then
            rsData <= rsDataFromID;
        elsif regWriteFromEx and rsAddressFromID = regAddressFromEx then
            rsData <= regDataFromEx;
        elsif regWriteFromMem and rsAddressFromID = regAddressFromMem then
            rsData <= regDataFromMem;
        else
            rsData <= rsDataFromID;
        end if;
    end process;

    determineRegDataB : process(regDataBFromID, regAddressBFromID, regDataFromEx, regAddressFromEx, regWriteFromEx,
                                regDataFromMem, regAddressFromMem, regWriteFromMem)
    begin
        if regAddressBFromID = 0 then
            regDataB <= regDataBFromID;
        elsif regWriteFromEx and regAddressBFromID = regAddressFromEx then
            regDataB <= regDataFromEx;
        elsif regWriteFromMem and regAddressBFromID = regAddressFromMem then
            regDataB <= regDataFromMem;
        else
            regDataB <= regDataBFromID;
        end if;
    end process;
end architecture;
