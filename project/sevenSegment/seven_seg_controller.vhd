library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg;
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
        mst2slv : in bus_pkg.bus_mst2slv_type;
        slv2mst : out bus_pkg.bus_slv2mst_type;

        digit_anodes : out std_logic_vector(digit_count - 1 downto 0);
        kathode : out seven_seg_kath_type
    );
end seven_seg_controller;

architecture behaviourial of seven_seg_controller is
    constant check_range     :   bus_pkg.addr_range_type := (
        low => std_logic_vector(to_unsigned(0, bus_pkg.bus_address_type'length)),
        high => std_logic_vector(to_unsigned(digit_count - 1, bus_pkg.bus_address_type'length))
    );

    signal timer_done : std_logic;
    signal digit_storage : bus_pkg.bus_byte_array(digit_count - 1 downto 0) := (others => (others => '0'));
begin

    bus_interaction : process(clk, mst2slv)
        variable full_addr : natural range 0 to 2*digit_count;
        variable addr : natural range 0 to digit_count - 1 := 0;
        variable fault : boolean := false;
        variable slv2mst_internal : bus_pkg.bus_slv2mst_type := bus_pkg.BUS_SLV2MST_IDLE;
    begin
        slv2mst_internal.faultData := (others => '0');
        slv2mst_internal.writeValid := '1';
        slv2mst_internal.faultData := bus_pkg.bus_fault_address_out_of_range;
        if bus_pkg.bus_requesting(mst2slv) and not bus_pkg.bus_addr_in_range(mst2slv.address, check_range) then
            fault := true;
            slv2mst_internal.fault := '1';
        else
            fault := false;
            slv2mst_internal.fault := '0';
        end if;

        if rising_edge(clk) then
            -- Bus interaction
            if rst = '1' then
                slv2mst_internal.readValid := '0';
                digit_storage <= (others => (others => '0'));
            else
                if bus_pkg.read_transaction(mst2slv, slv2mst_internal) then
                    slv2mst_internal.readValid := '0';
                elsif mst2slv.readReady = '1' and not fault then
                    slv2mst_internal.readValid := '1';
                end if;

                if not fault and bus_pkg.bus_requesting(mst2slv) then
                    slv2mst_internal.readData := (others => '0');
                    full_addr := to_integer(unsigned(mst2slv.address(mst2slv.address'range)));
                    for b in 0 to bus_pkg.bus_bytes_per_word - 1 loop
                        if (full_addr + b < digit_count) then
                            addr := full_addr + b;
                            if mst2slv.writeReady = '1' and mst2slv.byteMask(b) = '1' then
                                digit_storage(addr) <= mst2slv.writeData((b+1) * bus_pkg.bus_byte_size - 1 downto b*bus_pkg.bus_byte_size);
                            end if;
                            slv2mst_internal.readData((b+1) * bus_pkg.bus_byte_size - 1 downto b*bus_pkg.bus_byte_size) := digit_storage(addr);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
        slv2mst <= slv2mst_internal;
    end process;

    digit_control : process(clk)
        variable cur_digit : natural range 0 to digit_count - 1 := 0;
    begin
        if rising_edge(clk) then
            -- Digit control
            if timer_done = '1' then
                if cur_digit = digit_count - 1 then
                    cur_digit := 0;
                else
                    cur_digit := cur_digit + 1;
                end if;
            end if;
            -- Set the output to the digits
            kathode <= hex_to_seven_seg(digit_storage(cur_digit)(digit_info_type'range));

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

