library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.sync_pkg.all;

library src;
use src.mips32_pkg.all;

library tb;
use tb.mips32_pipeline_simulated_memory_pkg;

entity mips32_pipeline_simulated_memory is
    generic (
        constant actor : actor_t;
        memory_size_log2b : natural range mips32_data_width_log2b to 20;
        offset_address : natural := 0;
        constant logger : logger_t := get_logger("pipeline_simulated_bus_memory")
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : out boolean;

        if_stall_cycles : in natural;

        ifRequestAddress : in mips32_address_type;
        ifData : out mips32_data_type;

        doMemRead : in boolean;
        doMemWrite : in boolean;
        memAddress : in mips32_address_type;
        dataToMem : in mips32_data_type;
        dataFromMem : out mips32_data_type
    );
end entity;

architecture tb of mips32_pipeline_simulated_memory is
    constant byte_count : natural := 2**memory_size_log2b;

    signal memory : mips32_byte_array(offset_address to offset_address + byte_count);

    -- vcom interaction
    signal vcom_request_write : boolean := false;
    signal vcom_write_done : boolean := false;
    signal vcom_request_address : natural;
    signal vcom_request_data : mips32_data_type;
begin
    stall_handling : process(clk, ifRequestAddress, if_stall_cycles)
        variable cached_address : mips32_address_type := (others => '0');
        variable stall_cycles_left : natural := 0;
        variable stall_buf : boolean := false;
    begin

        if if_stall_cycles'active then
            info(logger, name(actor) & "stall_cycles_left updates to " & integer'image(if_stall_cycles));
            stall_cycles_left := if_stall_cycles;
            cached_address := (others => '0');
        end if;

        if rising_edge(clk) then
            if stall_buf then
                stall_cycles_left := stall_cycles_left - 1;
            else
                stall_cycles_left := if_stall_cycles;
            end if;
        end if;

        if cached_address /= ifRequestAddress and stall_cycles_left /= 0 then
            stall_buf := true;
        else
            stall_buf := false;
            cached_address := ifRequestAddress;
        end if;
        stall <= stall_buf;
    end process;

    ifHandling : process(ifRequestAddress, memory)
        variable actualRequestAddress : natural := offset_address;
    begin
        if ifRequestAddress'event then
            assert(ifRequestAddress(1 downto 0) = "00");
            actualRequestAddress := to_integer(unsigned(ifRequestAddress));
        end if;
        for i in 0 to mips32_bytes_per_data_word - 1 loop
            ifData((i + 1)*mips32_byte_type'length - 1 downto i*mips32_byte_type'length) <= memory(i + actualRequestAddress);
        end loop;
    end process;

    memReadHandling : process(doMemRead, memAddress, memory)
        variable actualRequestAddress : natural;
    begin
        if doMemRead then
            assert(memAddress(1 downto 0) = "00");
            actualRequestAddress := to_integer(unsigned(memAddress));
            assert(actualRequestAddress + mips32_bytes_per_data_word - 1 <= memory'high);
            for i in 0 to mips32_bytes_per_data_word - 1 loop
                dataFromMem((i + 1)*mips32_byte_type'length - 1 downto i*mips32_byte_type'length) <= memory(i + actualRequestAddress);
            end loop;
        end if;
    end process;

    memWriteHandling : process(clk, vcom_request_write, vcom_request_address, vcom_request_data)
        variable actualRequestAddress : natural;
    begin
        if rising_edge(clk) and rst /= '1' and doMemWrite then
            assert(memAddress(1 downto 0) = "00");
            actualRequestAddress := to_integer(unsigned(memAddress));
            assert(actualRequestAddress + mips32_bytes_per_data_word - 1 <= memory'high);
            for i in 0 to mips32_bytes_per_data_word - 1 loop
                memory(i+actualRequestAddress) <=
                    dataToMem((i + 1)*mips32_byte_type'length - 1 downto i*mips32_byte_type'length);
            end loop;
        end if;

        if vcom_request_write then
            for i in 0 to mips32_bytes_per_data_word - 1 loop
                memory(i + vcom_request_address) <=
                    vcom_request_data((i + 1)*mips32_byte_type'length - 1 downto i*mips32_byte_type'length);
            end loop;
            vcom_write_done <= true;
        else
            vcom_write_done <= false;
        end if;
    end process;

    msg_handler : process is
        variable request_msg, reply_msg : msg_t;
        variable msg_type : msg_type_t;
        variable address : natural;
        variable return_data : mips32_data_type;
    begin
        receive(net, actor, request_msg);
        msg_type := message_type(request_msg);
        handle_sync_message(net, msg_type, request_msg);
        if msg_type = mips32_pipeline_simulated_memory_pkg.read_fromAddress_msg then
            reply_msg := new_msg(mips32_pipeline_simulated_memory_pkg.read_reply_msg);
            address := pop(request_msg);
            for i in 0 to mips32_bytes_per_data_word - 1 loop
                return_data((i+1)*mips32_byte_type'length - 1 downto i*mips32_byte_type'length) := memory(address + i);
            end loop;
            push(reply_msg, return_data);
            reply(net, request_msg, reply_msg);
        elsif msg_type = mips32_pipeline_simulated_memory_pkg.write_toAddress_msg then
            vcom_request_address <= pop(request_msg);
            vcom_request_data <= pop(request_msg);
            vcom_request_write <= true;
            wait until vcom_write_done;
            info(logger, name(actor) & " is writing " & to_hstring(vcom_request_data) & " to address " & to_hstring(to_signed(vcom_request_address, 32)));
            vcom_request_write <= false;
            wait until not vcom_write_done;
        end if;
    end process;
end architecture;
