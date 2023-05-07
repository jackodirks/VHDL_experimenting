library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
use work.mips32_pkg;

entity mips32_registerFile is
    port (
        clk : in std_logic;

        readPortOneAddress : in mips32_pkg.registerFileAddress_type;
        readPortOneData : out mips32_pkg.data_type;

        readPortTwoAddress : in mips32_pkg.registerFileAddress_type;
        readPortTwoData : out mips32_pkg.data_type;

        writePortDoWrite : in boolean;
        writePortAddress : in mips32_pkg.registerFileAddress_type;
        writePortData : in mips32_pkg.data_type
    );
end entity;

architecture behaviourial of mips32_registerFile is
    signal registerFile : mips32_pkg.data_array(1 to 31);
begin

    readPortOne : process(readPortOneAddress, writePortDoWrite, writePortAddress, writePortData, registerFile)
    begin
        if readPortOneAddress = 0 then
            readPortOneData <= (others => '0');
        elsif readPortOneAddress = writePortAddress and writePortDoWrite then
            readPortOneData <= writePortData;
        else
            readPortOneData <= registerFile(readPortOneAddress);
        end if;
    end process;

    readPortTwo : process(readPortTwoAddress, writePortDoWrite, writePortAddress, writePortData, registerFile)
    begin
        if readPortTwoAddress = 0 then
            readPortTwoData <= (others => '0');
        elsif readPortTwoAddress = writePortAddress and writePortDoWrite then
            readPortTwoData <= writePortData;
        else
            readPortTwoData <= registerFile(readPortTwoAddress);
        end if;
    end process;

    writePort : process(clk)
    begin
        if rising_edge(clk) then
            if writePortAddress /= 0 and writePortDoWrite then
                registerFile(writePortAddress) <= writePortData;
            end if;
        end if;
    end process;

end behaviourial;
