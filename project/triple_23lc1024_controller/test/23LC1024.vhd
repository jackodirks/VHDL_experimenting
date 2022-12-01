-- *******************************************************************************************************
-- **                                                                                                   **
-- **   23LC1024.vhd - 23LC1024 1 MBIT SPI SERIAL SRAM (VCC = +2.5V TO +5.5V)                           **
-- **                                                                                                   **
-- *******************************************************************************************************

-- Based on 23LC1024.v by Young Engineering
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library tb;
use tb.M23LC1024_pkg.all;

entity M23LC1024 is
    port (
        cs_n : in std_logic;
        so_sio1 : inout std_logic;
        sio2 : inout std_logic;
        hold_n_sio3 : inout std_logic;
        sck : in std_logic;
        si_sio0 : inout std_logic;

        dbg_opmode : out OperationMode;
        dbg_iomode : out InoutMode
    );
end M23LC1024;


architecture behavioral of M23LC1024 is
    type ActiveInstruction is (InstructionNOP, InstructionRead, InstructionRDMR, InstructionWRMR, InstructionWrite, InstructionEDIO, InstructionEQIO, InstructionRSTIO);
    type ByteArray is array (0 to 2**17 - 1) of std_logic_vector(7 downto 0);

    signal dataShifterI : std_logic_vector(7 downto 0) := (others => '0'); -- Serial input data shifter
    signal dataShifterO : std_logic_vector(7 downto 0) := (others => '0'); -- Serial output data shifter
    signal clockCounter : natural := 0; -- Serial input clock counter
    signal addrRegister : std_logic_vector(16 downto 0) := (others => '0'); -- Address register

    signal activeInstr : ActiveInstruction := InstructionNOP;
    signal opMode : OperationMode := ByteMode;
    signal ioMode : InoutMode := SpiMode;

    signal outputActive : boolean := false;
    signal hold : boolean := false;

    constant CSSetupTime : time := 25 ns;
    constant CSHoldTime : time := 50 ns;
    constant CSDisableTime : time := 25 ns;
    constant DataSetupTime : time := 10 ns;
    constant DataHoldTime : time := 10 ns;
    constant ClkHighTime : time := 25 ns;
    constant ClkLowTime : time := 25 ns;
    constant ClkDelayTime : time := 25 ns;
    constant DataValidFromClockLow : time := 25 ns;

    pure function decodeInstRegister(instRegister : std_logic_vector(7 downto 0)) return ActiveInstruction is
        variable ret_val : ActiveInstruction := InstructionNOP;
    begin
        case instRegister is
            when "00000011" =>
                ret_val := InstructionRead;
            when "00000001" =>
                ret_val := InstructionWRMR;
            when "00000010" =>
                ret_val := InstructionWrite;
            when "00000101" =>
                ret_val := InstructionRDMR;
            when "00111011" =>
                ret_val := InstructionEDIO;
            when "00111000" =>
                ret_val := InstructionEQIO;
            when "11111111" =>
                ret_val := InstructionRSTIO;
            when others =>
                assert false report "Unknown instruction" severity error;
        end case;
        return ret_val;
    end function;

    pure function decodeModeRegister(modeRegister : std_logic_vector(7 downto 0)) return OperationMode is
        variable ret_val : OperationMode := ByteMode;
    begin
        assert (modeRegister(5 downto 0) = "000000") report "Last 6 bit of mode register write should be all zeros!" severity error;
        case modeRegister(7 downto 6) is
            when "00" =>
                ret_val := ByteMode;
            when "01" =>
                ret_val := SeqMode;
            when "10" =>
                ret_val := PageMode;
            when others =>
                assert false report "Illegal mode" severity error;
        end case;
        return ret_val;
    end function;

    pure function encodeModeRegister(curMode : OperationMode) return std_logic_vector is
        variable ret_val : std_logic_vector(7 downto 0) := (others => '0');
    begin
        case curMode is
            when ByteMode =>
                ret_val(7 downto 6) := "00";
            when SeqMode =>
                ret_val(7 downto 6) := "01";
            when PageMode =>
                ret_val(7 downto 6) := "10";
        end case;
        return ret_val;
    end function;

    pure function incrementAddress(curAddr : std_logic_vector(16 downto 0);
                                   operMode : OperationMode) return std_logic_vector is
        variable ret_val : std_logic_vector(16 downto 0) := curAddr;
    begin
        case operMode is
            when SeqMode =>
                ret_val := std_logic_vector(to_unsigned(to_integer(unsigned(curAddr)) + 1, curAddr'length));
            when PageMode =>
                ret_val(4 downto 0) := std_logic_vector(to_unsigned(to_integer(unsigned(curAddr(4 downto 0))) + 1, 5));
            when others =>
        end case;
        return ret_val;
    end function;

begin
-- *******************************************************************************************************
-- **   INITIALIZATION                                                                                  **
-- *******************************************************************************************************
    process (ioMode, hold_n_sio3)
    begin
        hold <= ioMode = SpiMode and hold_n_sio3 = '0';
    end process;

-- *******************************************************************************************************
-- **   CORE LOGIC                                                                                      **
-- *******************************************************************************************************
-- -------------------------------------------------------------------------------------------------------
--      1.01:  Internal Reset Logic
-- -------------------------------------------------------------------------------------------------------
    process(cs_n, sck)
    begin
        if rising_edge(cs_n) then
            outputActive <= false;
        elsif rising_edge(sck) and not hold and (activeInstr = InstructionRead or activeInstr = InstructionRDMR) then
            case ioMode is
                when SpiMode =>
                    if (clockCounter >= 32) and (clockCounter mod 8 = 0) then
                        outputActive <= true;
                    end if;
                when SdiMode =>
                    if (clockCounter >= 20) and (clockCounter mod 4 = 0) then
                        outputActive <= true;
                    end if;
                when SqiMode =>
                    if (clockCounter >= 10) and (clockCounter mod 2 = 0) then
                        outputActive <= true;
                    end if;
            end case;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.02:  Input Data Shifter
-- -------------------------------------------------------------------------------------------------------
    process(sck)
    begin
        if rising_edge(sck) and not hold and cs_n = '0' then
            case ioMode is
                when SpiMode =>
                    dataShifterI <= dataShifterI(6 downto 0) & si_sio0;
                when SdiMode =>
                    dataShifterI <= dataShifterI(5 downto 0) & so_sio1 & si_sio0;
                when SqiMode =>
                    dataShifterI <= dataShifterI(3 downto 0) & hold_n_sio3 & sio2 & so_sio1 & si_sio0;
            end case;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.03:  Clock Cycle Counter
-- -------------------------------------------------------------------------------------------------------
    process(cs_n, sck)
    begin
        if rising_edge(cs_n) then
            clockCounter <= 0;
        elsif rising_edge(sck) and not hold and cs_n = '0' then
            clockCounter <= clockCounter + 1;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.04:  Instruction Register
-- -------------------------------------------------------------------------------------------------------
    process(sck)
    begin
        if rising_edge(sck) and not hold then
            case ioMode is
                when SpiMode =>
                    if (clockCounter = 7) then
                        activeInstr <= decodeInstRegister(dataShifterI(6 downto 0) & si_sio0);
                    end if;
                when SdiMode =>
                    if (clockCounter = 3) then
                        activeInstr <= decodeInstRegister(dataShifterI(5 downto 0) & so_sio1 & si_sio0);
                    end if;
                when SqiMode =>
                    if (clockCounter = 1) then
                        activeInstr <= decodeInstRegister(dataShifterI(3 downto 0) & hold_n_sio3 & sio2  & so_sio1 & si_sio0);
                    end if;
            end case;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.05:  Address Register
-- -------------------------------------------------------------------------------------------------------
    process(sck)
    begin
        if rising_edge(sck) and (activeInstr = InstructionRead or activeInstr = InstructionWrite) and not hold then
            case ioMode is
                when SpiMode =>
                    if (clockCounter = 15) then addrRegister(16) <= si_sio0; end if;
                    if (clockCounter = 23) then addrRegister(15 downto 8) <= dataShifterI(6 downto 0) & si_sio0; end if;
                    if (clockCounter = 31) then addrRegister(7 downto 0) <= dataShifterI(6 downto 0) & si_sio0; end if;
                when SdiMode =>
                    if (clockCounter = 7) then addrRegister(16) <= si_sio0; end if;
                    if (clockCounter = 11) then addrRegister(15 downto 8) <= dataShifterI(5 downto 0) & so_sio1 & si_sio0; end if;
                    if (clockCounter = 15) then addrRegister(7 downto 0) <= dataShifterI(5 downto 0) & so_sio1 & si_sio0; end if;
                when SqiMode =>
                    if (clockCounter = 3) then addrRegister(16) <= si_sio0; end if;
                    if (clockCounter = 5) then addrRegister(15 downto 8) <= dataShifterI(3 downto 0) & hold_n_sio3 & sio2 & so_sio1 & si_sio0; end if;
                    if (clockCounter = 7) then addrRegister(7 downto 0) <= dataShifterI(3 downto 0) & hold_n_sio3 & sio2 & so_sio1 & si_sio0; end if;
            end case;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.06:  Status Register Write
-- -------------------------------------------------------------------------------------------------------
    process(sck)
    begin
        if rising_edge(sck) and (activeInstr = InstructionWRMR) and not hold then
            case ioMode is
                when SpiMode =>
                    if (clockCounter = 15) then
                        opMode <= decodeModeRegister(dataShifterI(6 downto 0) & si_sio0);
                    end if;
                when SdiMode =>
                    if (clockCounter = 7) then
                        opMode <= decodeModeRegister(dataShifterI(5 downto 0) & so_sio1 & si_sio0);
                    end if;
                when SqiMode =>
                    if (clockCounter = 3) then
                        opMode <= decodeModeRegister(dataShifterI(3 downto 0) & hold_n_sio3 & sio2  & so_sio1 & si_sio0);
                    end if;
            end case;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.07:  I/O Mode Instructions
-- -------------------------------------------------------------------------------------------------------
    process(activeInstr)
    begin
        case activeInstr is
            when InstructionEDIO =>
                ioMode <= SdiMode;
            when InstructionEQIO =>
                ioMode <= SqiMode;
            when InstructionRSTIO =>
                ioMode <= SpiMode;
            when others =>
        end case;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.08:  Array Read/Write
-- -------------------------------------------------------------------------------------------------------
    process(sck)
        variable memoryBlock : ByteArray := (others => (others => '0'));
    begin
        if rising_edge(sck) and not hold then
            if activeInstr = InstructionWrite then
                case ioMode is
                    when SpiMode =>
                        if (clockCounter >= 39) and (clockCounter mod 8 = 7) then
                        memoryBlock(to_integer(unsigned(addrRegister))) := dataShifterI(6 downto 0) & si_sio0;
                        addrRegister <= incrementAddress(addrRegister, opMode);
                        end if;
                    when SdiMode =>
                        if (clockCounter >= 19) and (clockCounter mod 4 = 3) then
                        memoryBlock(to_integer(unsigned(addrRegister))) := dataShifterI(5 downto 0) & so_sio1 & si_sio0;
                        addrRegister <= incrementAddress(addrRegister, opMode);
                        end if;
                    when SqiMode =>
                        if (clockCounter >= 9) and (clockCounter mod 2 = 1) then
                        memoryBlock(to_integer(unsigned(addrRegister))) := dataShifterI(3 downto 0) & hold_n_sio3 & sio2 & so_sio1 & si_sio0;
                        addrRegister <= incrementAddress(addrRegister, opMode);
                        end if;
                end case;
            elsif activeInstr = InstructionRead then
                case ioMode is
                    when SpiMode =>
                        if (clockCounter >= 32) and (clockCounter mod 8 = 0) then
                            dataShifterO <= memoryBlock(to_integer(unsigned(addrRegister)));
                            addrRegister <= incrementAddress(addrRegister, opMode);
                        else
                            dataShifterO <= std_logic_vector(shift_left(unsigned(dataShifterO), 1));
                        end if;
                    when SdiMode =>
                        if (clockCounter >= 20) and (clockCounter mod 4 = 0) then
                            dataShifterO <= memoryBlock(to_integer(unsigned(addrRegister)));
                            addrRegister <= incrementAddress(addrRegister, opMode);
                        else
                            dataShifterO <= std_logic_vector(shift_left(unsigned(dataShifterO), 2));
                        end if;
                    when SqiMode =>
                        if (clockCounter >= 10) and (clockCounter mod 2 = 0) then
                            dataShifterO <= memoryBlock(to_integer(unsigned(addrRegister)));
                            addrRegister <= incrementAddress(addrRegister, opMode);
                        else
                            dataShifterO <= std_logic_vector(shift_left(unsigned(dataShifterO), 4));
                        end if;
                end case;
            end if;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.09:  Output Data Shifter
-- -------------------------------------------------------------------------------------------------------
    process(sck)
    begin
        if falling_edge(sck) and not hold and activeInstr = InstructionRDMR then
            case ioMode is
                when SpiMode =>
                    if (clockCounter >= 32) and (clockCounter mod 8 = 0) then
                        dataShifterO <= encodeModeRegister(opMode);
                    else
                        dataShifterO <= std_logic_vector(shift_left(unsigned(dataShifterO), 1));
                    end if;
                when SdiMode =>
                    if (clockCounter >= 20) and (clockCounter mod 4 = 0) then
                        dataShifterO <= encodeModeRegister(opMode);
                    else
                        dataShifterO <= std_logic_vector(shift_left(unsigned(dataShifterO), 2));
                    end if;
                when SqiMode =>
                    if (clockCounter >= 10) and (clockCounter mod 2 = 0) then
                        dataShifterO <= encodeModeRegister(opMode);
                    else
                        dataShifterO <= std_logic_vector(shift_left(unsigned(dataShifterO), 4));
                    end if;
            end case;
        end if;
    end process;
-- -------------------------------------------------------------------------------------------------------
--      1.10:  Output Data Buffer
-- -------------------------------------------------------------------------------------------------------
    process(dataShifterO, cs_n)
    begin
        if cs_n = '1' then
            si_sio0 <= 'Z';
            so_sio1 <= 'Z';
            sio2 <= 'Z';
            HOLD_N_SIO3 <= 'Z';
        else
            case ioMode is
                when SpiMode =>
                    if outputActive then
                        so_sio1 <= dataShifterO(0);
                    else
                        so_sio1 <= 'Z';
                    end if;
                when SdiMode =>
                    if outputActive then
                        si_sio0 <= dataShifterO(0);
                        so_sio1 <= dataShifterO(1);
                    else
                        si_sio0 <= 'Z';
                        so_sio1 <= 'Z';
                    end if;
                when SqiMode =>
                    if outputActive then
                        si_sio0 <= dataShifterO(0);
                        so_sio1 <= dataShifterO(1);
                        sio2 <= dataShifterO(2);
                        HOLD_N_SIO3 <= dataShifterO(3);
                    else
                        si_sio0 <= 'Z';
                        so_sio1 <= 'Z';
                        sio2 <= 'Z';
                        HOLD_N_SIO3 <= 'Z';
                    end if;
            end case;
        end if;
    end process;
-- *******************************************************************************************************
-- **   DEBUG LOGIC                                                                                     **
-- *******************************************************************************************************
-- -------------------------------------------------------------------------------------------------------
--      2.1:  Debug signal handling
-- -------------------------------------------------------------------------------------------------------
    dbg_opmode <= opMode;
    dbg_iomode <= ioMode;
-- *******************************************************************************************************
-- **   TIMING CHECKS                                                                                   **
-- *******************************************************************************************************
-- The numbers in the falure message come from the datasheet.
    process(sck, cs_n, si_sio0, so_sio1, sio2, hold_n_sio3)
        variable last_sck_rise : time := 0 ns;
        variable last_sck_fall : time := 0 ns;
    begin
        if rising_edge(sck) then
            last_sck_rise := now;
            assert sck'delayed'stable(ClkLowTime) report "Timing failure 9" severity error;
            if cs_n = '0' then
                assert cs_n'stable(CSSetupTime) report "Timing failure 2" severity error;
            end if;
            if cs_n = '1' then
                assert cs_n'stable(ClkDelayTime) report "Timing failure 11" severity error;
            end if;
            case ioMode is
                when SpiMode =>
                    assert si_sio0'stable(DataSetupTime) report "Timing failure 5" severity error;
                when SdiMode =>
                    assert si_sio0'stable(DataSetupTime) report "Timing failure 5" severity error;
                    assert so_sio1'stable(DataSetupTime) report "Timing failure 5" severity error;
                when SqiMode =>
                    assert si_sio0'stable(DataSetupTime) report "Timing failure 5" severity error;
                    assert so_sio1'stable(DataSetupTime) report "Timing failure 5" severity error;
                    assert sio2'stable(DataSetupTime) report "Timing failure 5" severity error;
                    assert hold_n_sio3'stable(DataSetupTime) report "Timing failure 5" severity error;
            end case;
        end if;
        if falling_edge(sck) then
            last_sck_fall := now;
            assert sck'delayed'stable(ClkHighTime) report "Timing failure 10" severity error;
        end if;
        if falling_edge(cs_n) then
            assert cs_n'delayed'stable(CSDisableTime) report "Timing failure 4" severity error;
        end if;
        if rising_edge(cs_n) then
            assert now - last_sck_rise >= CSHoldTime report "Timing failure 3" severity error;
        end if;
        if (rising_edge(si_sio0) or falling_edge(si_sio0)) and last_sck_rise >= 0 ns then
            assert now - last_sck_rise >= DataHoldTime report "Timing failure 6" severity error;
            assert now - last_sck_fall <= DataValidFromClockLow report "Timing failure 12" severity error;
        end if;
        if (rising_edge(so_sio1) or falling_edge(so_sio1)) and (ioMode = SdiMode or ioMode = SqiMode) and last_sck_rise >= 0 ns then
            assert now - last_sck_rise >= DataHoldTime report "Timing failure 6" severity error;
            assert now - last_sck_fall <= DataValidFromClockLow report "Timing failure 12" severity error;
        end if;
        if (rising_edge(sio2) or falling_edge(sio2)) and ioMode = SqiMode and last_sck_rise >= 0 ns then
            assert now - last_sck_rise >= DataHoldTime report "Timing failure 6" severity error;
            assert now - last_sck_fall <= DataValidFromClockLow report "Timing failure 12" severity error;
        end if;
        if (rising_edge(hold_n_sio3) or falling_edge(hold_n_sio3)) and ioMode = SqiMode and last_sck_rise >= 0 ns then
            assert now - last_sck_rise >= DataHoldTime report "Timing failure 6" severity error;
            assert now - last_sck_fall <= DataValidFromClockLow report "Timing failure 12" severity error;
        end if;

    end process;

end behavioral;
