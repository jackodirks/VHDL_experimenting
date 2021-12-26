library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.seven_seg_pkg.all;

entity seven_seg_controller is
    generic (
        -- The controller cycles through the seven segment displays
        -- This variable controls how long (in clk cycles) every digit is turned on.
        hold_count : natural range 1 to natural'high;
        digit_count : natural range 1 to natural'high
    );
    port (
        clk     : in std_logic;
        rst     : in std_logic;

        -- Bus connection
        mst2slv : in bus_mst2slv_type;
        slv2mst : out bus_slv2mst_type;

        digit_anodes : out std_logic_vector(digit_count - 1 downto 0);
        kathode : out seven_seg_kath_type
    );
end seven_seg_controller;

architecture behaviourial of seven_seg_controller is
    type digit_storage_array is array (natural range <>) of digit_info_type;

    constant check_range     :   addr_range_type := (
        low => std_logic_vector(to_unsigned(0, bus_address_type'length)),
        high => std_logic_vector(to_unsigned(digit_count - 1, bus_address_type'length))
    );

    signal digit_storage : digit_storage_array(digit_count - 1 downto 0) := (others => (others => '0'));

    signal timer_done : std_logic;
begin

    sequential : process(clk)
        variable addr : natural range 0 to digit_count - 1 := 0;
        variable cur_digit : natural range 0 to digit_count - 1 := 0;
    begin
        if rising_edge(clk) then
            -- Bus interaction
            slv2mst.readData <= (others => '0');
            if bus_addr_in_range(mst2slv.address, check_range) then
                addr := to_integer(unsigned(mst2slv.address(mst2slv.address'high downto 0)));
                if mst2slv.writeEnable = '1' then
                    digit_storage(addr) <= mst2slv.writeData(digit_info_type'high downto 0);
                end if;
                slv2mst.readData(digit_info_type'high downto 0) <= digit_storage(addr);
                slv2mst.fault <= '0';
            else
                slv2mst.fault <= '1';
            end if;

            if rst = '1' then
                slv2mst.ack <= '0';
            else
                slv2mst.ack <= bus_requesting(mst2slv);
            end if;

            -- Digit control
            if timer_done = '1' then
                if cur_digit = digit_count - 1 then
                    cur_digit := 0;
                else
                    cur_digit := cur_digit + 1;
                end if;
            end if;

            -- Set the output to the digits
            kathode <= hex_to_seven_seg(digit_storage(cur_digit));

            digit_anodes <= (others => '1');
            digit_anodes(cur_digit) <= '0';
        end if;
    end process;

    timer : entity work.simple_multishot_timer
    generic map (
        match_val   => hold_count
    )
    port map (
        clk         => clk,
        rst         => '0',
        done        => timer_done
    );
end behaviourial;

