library IEEE;
use IEEE.std_logic_1164.all;

library tb;
use tb.M23LC1024_pkg.all;

entity triple_M23LC1024 is
    port (
        cs_n : in std_logic_vector(2 downto 0);
        so_sio1 : inout std_logic;
        sio2 : inout std_logic;
        hold_n_sio3 : inout std_logic;
        sck : in std_logic;
        si_sio0 : inout std_logic;

        dbg_opmode_array : out OperationModeArray(2 downto 0);
        dbg_iomode_array : out InoutModeArray(2 downto 0)
    );
end triple_M23LC1024;

architecture behavioral of triple_M23LC1024 is
begin
    mem0 : entity tb.M23LC1024
    port map (
        cs_n => cs_n(0),
        so_sio1 => so_sio1,
        sio2 => sio2,
        hold_n_sio3 => hold_n_sio3,
        sck => sck,
        si_sio0 => si_sio0,
        dbg_opmode => dbg_opmode_array(0),
        dbg_iomode => dbg_iomode_array(0)
    );

    mem1 : entity tb.M23LC1024
    port map (
        cs_n => cs_n(1),
        so_sio1 => so_sio1,
        sio2 => sio2,
        hold_n_sio3 => hold_n_sio3,
        sck => sck,
        si_sio0 => si_sio0,
        dbg_opmode => dbg_opmode_array(1),
        dbg_iomode => dbg_iomode_array(1)
    );

    mem2 : entity tb.M23LC1024
    port map (
        cs_n => cs_n(2),
        so_sio1 => so_sio1,
        sio2 => sio2,
        hold_n_sio3 => hold_n_sio3,
        sck => sck,
        si_sio0 => si_sio0,
        dbg_opmode => dbg_opmode_array(2),
        dbg_iomode => dbg_iomode_array(2)
    );
end behavioral;
