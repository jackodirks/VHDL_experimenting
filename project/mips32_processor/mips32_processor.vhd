library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.bus_pkg.all;
use work.mips32_pkg.all;

entity mips32_processor is
    generic (
        startAddress : bus_address_type
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Control slave
        mst2control : in bus_mst2slv_type;
        control2mst : out bus_slv2mst_type;

        -- Instruction fetch master
        instructionFetch2slv : out bus_mst2slv_type;
        slv2instructionFetch : in bus_slv2mst_type;

        -- Memory master
        memory2slv : out bus_mst2slv_type;
        slv2memory : in bus_slv2mst_type
    );
end entity;

architecture behaviourial of mips32_processor is
    signal pipelineStall : boolean;

    signal pipelineRst : std_logic;
    signal instructionAddress : mips32_address_type;
    signal instruction : mips32_instruction_type;
    signal dataAddress : mips32_address_type;
    signal dataRead : boolean;
    signal dataWrite : boolean;
    signal dataToBus : mips32_data_type;
    signal dataFromBus : mips32_data_type;

    signal controllerReset : boolean;
    signal controllerStall : boolean;

    signal instructionFetchHasFault : boolean;
    signal instructionFetchFaultData : bus_fault_type;
    signal instructionStall : boolean;

    signal memoryHasFault : boolean;
    signal memoryFaultData : bus_fault_type;
    signal memoryStall : boolean;
    signal forbidBusInteraction : boolean;
begin
    pipelineStall <= controllerStall or instructionStall or memoryStall;
    forbidBusInteraction <= controllerReset or controllerStall;

    process(rst, controllerReset)
    begin
        if rst = '1' or controllerReset then
            pipelineRst <= '1';
        else
            pipelineRst <= '0';
        end if;
    end process;

    process(controllerStall, instructionStall)
    begin
    end process;

    pipeline : entity work.mips32_pipeline
        generic map (
            startAddress => startAddress
        ) port map (
            clk => clk,
            rst => pipelineRst,
            stall => pipelineStall,
            instructionAddress => instructionAddress,
            instruction => instruction,
            dataAddress => dataAddress,
            dataRead => dataRead,
            dataWrite => dataWrite,
            dataOut => dataToBus,
            dataIn => dataFromBus
        );

    bus_slave : entity work.mips32_bus_slave
    port map (
        clk => clk,
        rst => rst,
        mst2slv => mst2control,
        slv2mst => control2mst,
        controllerReset => controllerReset,
        controllerStall => controllerStall
    );

    if2bus : entity work.mips32_if2bus
    port map (
        clk => clk,
        rst => rst,
        forbidBusInteraction => forbidBusInteraction,
        flushCache => controllerReset,
        mst2slv => instructionFetch2slv,
        slv2mst => slv2instructionFetch,
        hasFault => instructionFetchHasFault,
        faultData => instructionFetchFaultData,
        requestAddress => instructionAddress,
        instruction => instruction,
        stall => instructionStall
    );

    mem2bus : entity work.mips32_mem2bus
    port map (
        clk => clk,
        rst => rst,
        forbidBusInteraction => forbidBusInteraction,
        flushCache => controllerReset,
        mst2slv => memory2slv,
        slv2mst => slv2memory,
        hasFault => memoryHasFault,
        faultData => memoryFaultData,
        address => dataAddress,
        dataIn => dataToBus,
        dataOut => dataFromBus,
        doWrite => dataWrite,
        doRead => dataRead,
        stall => memoryStall
    );
end architecture;
