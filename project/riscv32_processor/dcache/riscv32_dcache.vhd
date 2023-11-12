library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.riscv32_pkg.all;
use work.bus_pkg.all;

entity riscv32_dcache is
    generic (
        word_count_log2b : natural;
        tag_size : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        addressIn : in riscv32_address_type;
        addressOut : out riscv32_address_type;
        dataIn : in riscv32_data_type;
        dataOut : out riscv32_instruction_type;
        byteMask : in riscv32_byte_mask_type;

        doWrite : in boolean;
        miss : out boolean;
        resetDirty : in boolean;
        dirty : out boolean
    );
end entity;

architecture behaviourial of riscv32_dcache is
    -- Tag size is what is left after subtracting the fact that we store word based and the address bits that are covered by the
    -- actual cache address.
    constant sub_word_part_lsb : natural := 0;
    constant sub_word_part_msb : natural := riscv32_address_width_log2b - riscv32_byte_width_log2b - 1;
    constant address_part_lsb : natural := riscv32_address_width_log2b - riscv32_byte_width_log2b;
    constant address_part_msb : natural := address_part_lsb + word_count_log2b - 1;
    constant tag_part_lsb : natural := address_part_msb + 1;
    constant tag_part_msb : natural := tag_part_lsb + tag_size - 1;

    signal tagOut : std_logic_vector(tag_size - 1 downto 0);
    signal tagIn : std_logic_vector(tag_size - 1 downto 0);
    signal requestAddress : std_logic_vector(word_count_log2b - 1 downto 0);
    signal valid : boolean;
    signal dirtyOut : boolean;
    signal dataFromBrank : riscv32_data_type;

    signal modified_byte_mask : riscv32_byte_mask_type;
    signal modified_data : riscv32_data_type;
    signal sub_word_part : natural range 0 to 2**(sub_word_part_msb + 1) -1;
begin

    tagIn <= addressIn(tag_part_msb downto tag_part_lsb);
    requestAddress <= addressIn(address_part_msb downto address_part_lsb);
    sub_word_part <= to_integer(unsigned(addressIn(sub_word_part_msb downto sub_word_part_lsb)));

    realign_write : process(addressIn, dataIn, byteMask, sub_word_part)
    begin
        modified_byte_mask <= std_logic_vector(shift_left(unsigned(byteMask), sub_word_part));
        modified_data <= std_logic_vector(shift_left(unsigned(dataIn), sub_word_part * riscv32_byte_width));
    end process;

    realign_read : process(addressIn, dataFromBrank, sub_word_part)
    begin
        dataOut <= std_logic_vector(shift_right(unsigned(dataFromBrank), sub_word_part * riscv32_byte_width));
    end process;

    miss <= not valid or (tagIn /= tagOut);
    dirty <= dirtyOut and valid;

    determineAddressOut : process(tagOut, requestAddress)
    begin
        addressOut <= (others => '0');
        addressOut(tag_part_msb downto tag_part_lsb) <= tagOut;
        addressOut(address_part_msb downto address_part_lsb) <= requestAddress;
    end process;

    dcache_bank : entity work.riscv32_dcache_bank
    generic map (
        word_count_log2b => word_count_log2b,
        tag_size => tag_size
    ) port map (
        clk => clk,
        rst => rst,
        requestAddress => requestAddress,
        dataOut => dataFromBrank,
        dataIn => modified_data,
        tagOut => tagOut,
        tagIn => tagIn,
        byteMask => modified_byte_mask,
        valid => valid,
        dirty => dirtyOut,
        resetDirty => resetDirty,
        doWrite => doWrite
    );
end architecture;
