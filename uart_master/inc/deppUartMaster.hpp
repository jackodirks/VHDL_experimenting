#pragma once

#include <string>
#include <cstdint>
#include <termios.h>
#include <vector>

class DeppUartMaster {
    public:
        DeppUartMaster(const std::string& devName = "/dev/ttyUSB1", speed_t baudRate = B2000000);

        DeppUartMaster(const DeppUartMaster&) = delete;

        DeppUartMaster& operator=(const DeppUartMaster&) = delete;

        ~DeppUartMaster();

        void writeWord(uint32_t address, uint32_t data);
        void writeWordSequence(uint32_t address, const std::vector<uint32_t>& data);
        uint32_t readWord(uint32_t address);
        std::vector<uint32_t> readWordSequence(uint32_t address, size_t wordCount);
        void selfTest();
    private:
        int fd;
        struct termios oldSettings;

        void writeByte(uint8_t data);
        void writeWord(uint32_t data);
        void writeArray(const uint8_t* data, size_t len);

        uint8_t readByte();
        uint32_t readWord();
        void readArray(uint8_t* data, size_t len);
        void checkReturnValue();
};
