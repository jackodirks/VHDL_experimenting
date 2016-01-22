----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    20:00:14 01/21/2016
-- Design Name:
-- Module Name:    uart_main - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_main is
    generic (
    CLOCKSPEED : natural;
    BAUDRATE : natural
)
Port (
         rst : in STD_LOGIC;
         clk : in STD_LOGIC;
         uart_rx : in STD_LOGIC;
         uart_tx : out STD_LOGIC;
         data_ready: out STD_LOGIC;
         send_start: in STD_LOGIC;
         receved_data : out STD_LOGIC_VECTOR(7 DOWNTO 0);
         send_data : in STD_LOGIC_VECTOR(7 DOWNTO 0)
     );
end uart_main;

architecture Behavioral of uart_main is

begin


end Behavioral;

