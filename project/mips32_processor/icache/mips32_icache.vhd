library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.mips32_pkg.all;
use work.bus_pkg.all;

entity mips32_icache is
    generic (
        rangeMap : addr_range_and_mapping_type;
        word_count_log2b : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        requestAddress : in mips32_address_type;
        instructionOut : out mips32_instruction_type;
        instructionIn : in mips32_instruction_type;

        doWrite : in boolean;
        fault : out boolean;
        miss : out boolean
    );
end entity;

architecture behaviourial of mips32_icache is

    constant relevant_part_lsb : natural := mips32_address_width_log2b - mips32_byte_width_log2b;
    constant address_range_size : natural := to_integer(unsigned(rangeMap.addr_range.high)) - to_integer(unsigned(rangeMap.addr_range.low));
    constant relevant_part_msb : natural := integer(ceil(log2(real(address_range_size)))) - 1;
    constant tag_size_log2b : natural := relevant_part_msb - relevant_part_lsb - word_count_log2b + 1;
    constant tag_msb : natural := relevant_part_msb;
    constant tag_lsb : natural := relevant_part_msb - tag_size_log2b + 1;
    constant address_msb : natural := relevant_part_msb - tag_size_log2b;
    constant address_lsb : natural := relevant_part_lsb;

    signal tagFromBank : std_logic_vector(tag_size_log2b - 1 downto 0);
    signal tagToBank : std_logic_vector(tag_size_log2b - 1 downto 0);
    signal remappedAddress : mips32_address_type;
    signal valid : boolean;
begin
    fault <= not bus_addr_in_range(requestAddress, rangeMap.addr_range);
    remappedAddress <= bus_apply_addr_map(requestAddress, rangeMap.mapping);
    tagToBank <= remappedAddress(tag_msb downto tag_lsb);
    miss <= not (valid and tagFromBank = tagToBank);

    icache_bank : entity work.mips32_icache_bank
    generic map (
        word_count_log2b => word_count_log2b,
        tag_size_log2b => tag_size_log2b
    ) port map (
        clk => clk,
        rst => rst,
        requestAddress => remappedAddress(address_msb downto address_lsb),
        instructionOut => instructionOut,
        instructionIn => instructionIn,
        tagOut => tagFromBank,
        tagIn => tagToBank,
        valid => valid,
        doWrite => doWrite
    );
end architecture;
