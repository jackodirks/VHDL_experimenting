#include <sstream>
#include <cstring>
#include <stdexcept>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <linux/serial.h>
#include <sys/ioctl.h>
#include "deppUartMaster.hpp"

static constexpr uint8_t ERROR_NO_ERROR = 0x0;
static constexpr uint8_t ERROR_UNKOWN_COMMAND = 0x1;
static constexpr uint8_t ERROR_BUS = 0x2;

static constexpr uint8_t COMMAND_READ_WORD = 0x1;
static constexpr uint8_t COMMAND_WRITE_WORD = 0x2;
static constexpr uint8_t COMMAND_READ_WORD_SEQUENCE = 0x3;
static constexpr uint8_t COMMAND_WRITE_WORD_SEQUENCE = 0x4;

static constexpr uint8_t BUS_FAULT_NO_FAULT = 0x0;
static constexpr uint8_t BUS_FAULT_UNALIGNED_ACCESS = 0x1;
static constexpr uint8_t BUS_FAULT_ADDRESS_OUT_OF_RANGE = 0x2;
static constexpr uint8_t BUS_FAULT_ILLEGAL_WRITE_MASK = 0x3;
static constexpr uint8_t BUS_FAULT_ILLEGAL_ADDRESS_FOR_BURST = 0x4;

DeppUartMaster::DeppUartMaster(const std::string& devName, speed_t baudRate) {
    this->fd = open(devName.c_str(), O_RDWR | O_NOCTTY);
    if (this->fd == -1) {
        std::stringstream ss;
        ss << "Failed to open " << devName << " : " << errno << " (" << strerror(errno) << ")";
        throw std::invalid_argument(ss.str());
    }
    struct termios tty;
    if (tcgetattr (fd, &tty) != 0) {
        std::stringstream ss;
        ss << "tcgetattr failed: " << errno << " (" << strerror(errno) << ")";
        throw std::runtime_error(ss.str());
    }
    this->oldSettings = tty;
    cfmakeraw(&tty);
    cfsetospeed(&tty, baudRate);
    cfsetispeed(&tty, baudRate);
    tty.c_cc[VMIN] = 1;
    tty.c_cc[VTIME] = 0;
    if (tcsetattr (fd, TCSANOW, &tty) != 0) {
        std::stringstream ss;
        ss << "tcsetattr failed: " << errno << " (" << strerror(errno) << ")";
        throw std::runtime_error(ss.str());
    }

    struct serial_struct serial;
    if (ioctl(fd, TIOCGSERIAL, &serial) == -1) {
        std::stringstream ss;
        ss << "ioctl TIOCGSERIAL failed: " << errno << " (" << strerror(errno) << ")";
        throw std::runtime_error(ss.str());
    }
    serial.flags |= ASYNC_LOW_LATENCY;
    if (ioctl(fd, TIOCSSERIAL, &serial) == -1) {
        std::stringstream ss;
        ss << "ioctl TIOCSSERIAL failed: " << errno << " (" << strerror(errno) << ")";
        throw std::runtime_error(ss.str());
    }

    if (tcflush(this->fd, TCIOFLUSH) == -1) {
        std::stringstream ss;
        ss << "tcflush failed: " << errno << " (" << strerror(errno) << ")";
        throw std::runtime_error(ss.str());
    }
}

DeppUartMaster::~DeppUartMaster() {
    tcsetattr(this->fd, TCSANOW, &this->oldSettings);
    close(this->fd);
}

void DeppUartMaster::writeArray(const uint8_t* data, size_t len) {
    ssize_t retVal = 0;
    size_t count = 0;
    while (count < len) {
        retVal = write(this->fd, &data[count], len - count);
        if (retVal == -1) {
            std::stringstream ss;
            ss << "write failed: " << errno << " (" << strerror(errno) << ")";
            throw std::runtime_error(ss.str());
        }
        count += retVal;
    }
}

void DeppUartMaster::readArray(uint8_t* data, size_t len) {
    ssize_t retVal = 0;
    size_t count = 0;
    while (count < len) {
        retVal = read(this->fd, &data[count], len - count);
        if (retVal == -1) {
            std::stringstream ss;
            ss << "Read failed: " << errno << " (" << strerror(errno) << ")";
            throw std::runtime_error(ss.str());
        }
        count += retVal;
    }
}

void DeppUartMaster::writeByte(uint8_t data) {
    this->writeArray(&data, 1);
}

uint8_t DeppUartMaster::readByte() {
    uint8_t ret = 0;
    this->readArray(&ret, 1);
    return ret;
}

void DeppUartMaster::checkReturnValue() {
    uint8_t retVal = this->readByte();
    if (retVal != ERROR_NO_ERROR) {
        std::stringstream ss;
        ss << "Return value is something other than ERROR_NO_ERROR: " << (int)retVal;
        throw std::runtime_error(ss.str());
    }
}

void DeppUartMaster::writeWord(uint32_t data) {
    uint8_t buf[4];
    for (size_t i = 0; i < 4; ++i) {
        buf[i] = static_cast<uint8_t>(data & 0xff);
        data >>= 8;
    }
    this->writeArray(&buf[0], 4);
}

uint32_t DeppUartMaster::readWord() {
    uint8_t buf[4];
    this->readArray(&buf[0], 4);
    uint32_t retVal = buf[0];
    retVal += static_cast<uint32_t>(buf[1]) << 8;
    retVal += static_cast<uint32_t>(buf[2]) << 16;
    retVal += static_cast<uint32_t>(buf[3]) << 24;
    return retVal;
}

void DeppUartMaster::writeWord(uint32_t address, uint32_t data) {
    this->writeByte(COMMAND_WRITE_WORD);
    this->checkReturnValue();
    this->writeWord(address);
    this->writeWord(data);
    this->checkReturnValue();
}

uint32_t DeppUartMaster::readWord(uint32_t address) {
    this->writeByte(COMMAND_READ_WORD);
    this->checkReturnValue();
    this->writeWord(address);
    uint32_t data = this->readWord();
    this->checkReturnValue();
    return data;
}

void DeppUartMaster::writeWordSequence(uint32_t address, const std::vector<uint32_t>& data) {
    size_t wordsTransmitted = 0;
    while (wordsTransmitted < data.size()) {
        this->writeByte(COMMAND_WRITE_WORD_SEQUENCE);
        this->checkReturnValue();
        uint32_t tmpAddr = address + wordsTransmitted*4;
        this->writeWord(tmpAddr);
        size_t wordsToWrite = std::min((size_t)256, data.size() - wordsTransmitted);
        uint8_t sequenceSizeMinusOne = wordsToWrite - 1;
        this->writeByte(sequenceSizeMinusOne);
        for (size_t i = wordsTransmitted; i < wordsTransmitted + wordsToWrite; ++i) {
            this->writeWord(data[i]);
        }
        this->checkReturnValue();
        wordsTransmitted += wordsToWrite;
    }
}

std::vector<uint32_t> DeppUartMaster::readWordSequence(uint32_t address, size_t wordCount) {
    std::vector<uint32_t> returnList(wordCount);
    size_t wordsReceived = 0;
    while(wordsReceived < wordCount) {
        this->writeByte(COMMAND_READ_WORD_SEQUENCE);
        this->checkReturnValue();
        uint32_t tmpAddr = address + wordsReceived*4;
        this->writeWord(tmpAddr);
        size_t wordsToRead = std::min((size_t)256, wordCount - wordsReceived);
        uint8_t sequenceSizeMinusOne = wordsToRead - 1;
        this->writeByte(sequenceSizeMinusOne);
        for (size_t i = wordsReceived; i < wordsReceived + wordsToRead; ++i) {
            returnList[i] = this->readWord();
        }
        this->checkReturnValue();
        wordsReceived += wordsToRead;
    }
    return returnList;
}

void DeppUartMaster::selfTest() {
    // Wrong byte
    this->writeByte(0xff);
    uint8_t retVal = this->readByte();
    if (retVal != ERROR_UNKOWN_COMMAND) {
        std::stringstream ss;
        ss << "Write 0xff then read resulted in something other than ERROR_UNKOWN_COMMAND: " << (int)retVal;
        throw std::runtime_error(ss.str());
    }
    // Write to address 0
    this->writeByte(COMMAND_WRITE_WORD);
    retVal = this->readByte();
    if (retVal != ERROR_NO_ERROR) {
        std::stringstream ss;
        ss << "Write COMMAND_WRITE_WORD in something other than ERROR_NO_ERROR: " << (int)retVal;
        throw std::runtime_error(ss.str());
    }
    // address
    this->writeWord(0x0);
    // data
    this->writeWord(0x0);
    retVal = this->readByte();
    if ((retVal & 0xf) != ERROR_BUS) {
        std::stringstream ss;
        ss << "Write to address 0 does not result in ERROR_BUS, but in: " << (int)(retVal & 0xf);
        throw std::runtime_error(ss.str());
    }

    if (retVal >> 4 != BUS_FAULT_ADDRESS_OUT_OF_RANGE) {
        std::stringstream ss;
        ss << "Write to address 0 does not result in BUS_FAULT_ADDRESS_OUT_OF_RANGE, but in: " << (int)(retVal>>4);
        throw std::runtime_error(ss.str());
    }

    // Read from address 0
    this->writeByte(COMMAND_READ_WORD);
    retVal = this->readByte();
    if (retVal != ERROR_NO_ERROR) {
        std::stringstream ss;
        ss << "Write COMMAND_WRITE_WORD in something other than ERROR_NO_ERROR: " << (int)retVal;
        throw std::runtime_error(ss.str());
    }
    // address
    this->writeWord(0x0);
    // Pop 4 bytes
    this->readByte();
    this->readByte();
    this->readByte();
    this->readByte();
    // Read return value
    retVal = this->readByte();
    if ((retVal & 0xf) != ERROR_BUS) {
        std::stringstream ss;
        ss << "Read from address 0 does not result in ERROR_BUS, but in: " << (int)(retVal & 0xf);
        throw std::runtime_error(ss.str());
    }
    if (retVal >> 4 != BUS_FAULT_ADDRESS_OUT_OF_RANGE) {
        std::stringstream ss;
        ss << "Read from address 0 does not result in BUS_FAULT_ADDRESS_OUT_OF_RANGE, but in: " << (int)(retVal>>4);
        throw std::runtime_error(ss.str());
    }
}
