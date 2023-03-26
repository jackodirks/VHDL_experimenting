library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.sync_pkg.all;

library src;
use src.mips32_pkg;

library tb;
use tb.mips32_pipeline_simulated_memory_pkg;

entity mips32_pipeline_simulated_memory is
    generic (
        constant actor : actor_t;
        memory_size_log2b : natural range mips32_pkg.data_width_log2b to 20;
        stall_cycles : natural;
        constant logger : logger_t := get_logger("pipeline_simulated_bus_memory")
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        stall : out boolean;

        ifRequestAddress : in mips32_pkg.address_type;
        ifData : out mips32_pkg.data_type;

        doMemRead : in boolean;
        doMemWrite : in boolean;
        memAddress : in mips32_pkg.address_type;
        dataToMem : in mips32_pkg.data_type;
        dataFromMem : out mips32_pkg.data_type
    );
end entity;

architecture tb of mips32_pipeline_simulated_memory is
    constant byte_count : natural := 2**memory_size_log2b;

    signal memory : mips32_pkg.byte_array(0 to byte_count);

    -- vcom interaction
    signal vcom_request_write : boolean := false;
    signal vcom_write_done : boolean := false;
    signal vcom_request_address : natural;
    signal vcom_request_data : mips32_pkg.data_type;
begin
    stall <= false;

    ifHandling : process(ifRequestAddress, memory)
        variable actualRequestAddress : natural;
    begin
        --assert(ifRequestAddress(1 downto 0) = "00");
        actualRequestAddress := to_integer(unsigned(ifRequestAddress));
        assert(actualRequestAddress + mips32_pkg.bytes_per_data_word - 1 <= byte_count);
        for i in 0 to mips32_pkg.bytes_per_data_word - 1 loop
            ifData((i + 1)*mips32_pkg.byte_type'length - 1 downto i*mips32_pkg.byte_type'length) <= memory(i + actualRequestAddress);
        end loop;
    end process;

    memReadHandling : process(doMemRead, memAddress, memory)
        variable actualRequestAddress : natural;
    begin
        if doMemRead then
            assert(memAddress(1 downto 0) = "00");
            actualRequestAddress := to_integer(unsigned(memAddress));
            assert(actualRequestAddress + 3 <= byte_count);
            for i in 0 to mips32_pkg.bytes_per_data_word - 1 loop
                dataFromMem((i + 1)*mips32_pkg.byte_type'length - 1 downto i*mips32_pkg.byte_type'length) <= memory(i + actualRequestAddress);
            end loop;
        end if;
    end process;

    memWriteHandling : process(clk, vcom_request_write, vcom_request_address, vcom_request_data)
        variable actualRequestAddress : natural;
    begin
        if rising_edge(clk) and rst /= '1' and doMemWrite then
            assert(memAddress(1 downto 0) = "00");
            actualRequestAddress := to_integer(unsigned(memAddress));
            assert(actualRequestAddress + mips32_pkg.bytes_per_data_word - 1 <= byte_count);
            for i in 0 to mips32_pkg.bytes_per_data_word - 1 loop
                memory(i+actualRequestAddress) <=
                    dataToMem((i + 1)*mips32_pkg.byte_type'length - 1 downto i*mips32_pkg.byte_type'length);
            end loop;
        end if;

        if vcom_request_write then
            for i in 0 to mips32_pkg.bytes_per_data_word - 1 loop
                memory(i + vcom_request_address) <=
                    vcom_request_data((i + 1)*mips32_pkg.byte_type'length - 1 downto i*mips32_pkg.byte_type'length);
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
        variable return_data : mips32_pkg.data_type;
    begin
        receive(net, actor, request_msg);
        msg_type := message_type(request_msg);
        handle_sync_message(net, msg_type, request_msg);
        if msg_type = mips32_pipeline_simulated_memory_pkg.read_fromAddress_msg then
            reply_msg := new_msg(mips32_pipeline_simulated_memory_pkg.read_reply_msg);
            address := pop(request_msg);
            for i in 0 to mips32_pkg.bytes_per_data_word - 1 loop
                return_data((i+1)*mips32_pkg.byte_type'length - 1 downto i*mips32_pkg.byte_type'length) := memory(address + i);
            end loop;
            push(reply_msg, return_data);
            reply(net, request_msg, reply_msg);
        elsif msg_type = mips32_pipeline_simulated_memory_pkg.write_toAddress_msg then
            vcom_request_address <= pop(request_msg);
            vcom_request_data <= pop(request_msg);
            vcom_request_write <= true;
            wait until vcom_write_done;
            vcom_request_write <= false;
            wait until not vcom_write_done;
        end if;
    end process;
end architecture;
