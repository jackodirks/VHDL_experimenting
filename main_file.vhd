----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:03:27 08/21/2015 
-- Design Name: 
-- Module Name:    main_file - Behavioral 
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

entity main_file is
    Port ( 
				rst : in STD_LOGIC;
			  --JA_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
           --JB_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
           --JC_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
           --JD_gpio : inout  STD_LOGIC_VECTOR (3 downto 0);
           slide_switch : in  STD_LOGIC_VECTOR (7 downto 0);
           --push_button : in  STD_LOGIC_VECTOR (3 downto 0);
           led : out  STD_LOGIC_VECTOR (7 downto 0)
           --seven_seg_kath : out  STD_LOGIC_VECTOR (7 downto 0);
           --seven_seg_an : out  STD_LOGIC_VECTOR (3 downto 0);
           --clk : in  STD_LOGIC
			  );
end main_file;

architecture Behavioral of main_file is

begin
led <= slide_switch;

end Behavioral;

