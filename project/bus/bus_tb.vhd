library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;
use IEEE.numeric_std.ALL;
use IEEE.math_real.ALL;

library work;
use work.bus_pkg.all;

entity bus_tb is
    generic (
        clock_period : time;
        randVal : natural
    );
    port (
        clk : in STD_LOGIC;
        done : out boolean;
        success : out boolean
    );
end bus_tb;

architecture Behavioral of bus_tb is

    type mem_type is record
        rst : std_logic;
        mst2slv : bus_mst2slv_type;
        slv2mst : bus_slv2mst_type;
        done : boolean;
        success : boolean;
    end record;

    constant MEM_TYPE_DEFAULT : mem_type := (
        rst => '0',
        mst2slv => BUS_MST2SLV_IDLE,
        slv2mst => BUS_SLV2MST_IDLE,
        done => false,
        success => false
    );

    signal mem_256_byte_control : mem_type := MEM_TYPE_DEFAULT;

begin
    mem_256_byte : entity work.bus_singleport_ram
    generic map (
        DEPTH_LOG2B => 8
    )
    port map (
        rst => mem_256_byte_control.rst,
        clk => clk,
        mst2mem => mem_256_byte_control.mst2slv,
        mem2mst => mem_256_byte_control.slv2mst
    );

    done <= mem_256_byte_control.done;
    success <= mem_256_byte_control.success;

    mem_256_byte_test : process
        variable suc : boolean := true;
    begin
        wait for clock_period/2;
        for A in 0 to 255 loop
            mem_256_byte_control.mst2slv.address <= std_logic_vector(to_unsigned(A, 8));
            for D in 0 to 255 loop
                if mem_256_byte_control.slv2mst.ack /= '0' then
                    report "At the start of A" & integer'image(A) severity error;
                    suc := false;
                end if;
                mem_256_byte_control.mst2slv.writeData <= std_logic_vector(to_unsigned(D, 8));
                mem_256_byte_control.mst2slv.writeEnable <= '1';
                wait for clock_period;
                if mem_256_byte_control.slv2mst.ack /= '1' then
                    report "One cycle after writeEnable in A" & integer'image(A) severity error;
                    suc := false;
                end if;
                mem_256_byte_control.mst2slv.writeEnable <= '0';
                wait for clock_period;
                assert mem_256_byte_control.slv2mst.ack = '0' severity error;
            end loop;
        end loop;
        mem_256_byte_control.done <= true;
        mem_256_byte_control.success <= suc;
        wait;
    end process;

end Behavioral;    
