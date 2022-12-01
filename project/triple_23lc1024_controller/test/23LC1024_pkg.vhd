library IEEE;
use IEEE.std_logic_1164.all;

package M23LC1024_pkg is 
    type OperationMode is (ByteMode, PageMode, SeqMode);
    type InoutMode is (SpiMode, SdiMode, SqiMode);

    type OperationModeArray is array (natural range <>) of OperationMode;
    type InoutModeArray is array (natural range <>) of InoutMode;
end package;

