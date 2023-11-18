#include <iostream>
#include <cassert>
#include <fstream>
#include <iterator>
#include <vector>
#include <unistd.h>
#include <cstring>

#include "deppUartMaster.hpp"
#include "inputFile.hpp"

static constexpr uint32_t spiMemStartAddress = 0x100000;
static constexpr uint32_t spiMemLength = 0x60000;
static constexpr uint32_t cpuBaseAddress = 0x2000;

template<typename T>
static void dumpSubList(DeppUartMaster& master, uint32_t startAddress) {
    uint32_t curAddress = startAddress;
    T data[12];
    std::size_t index = 0;
    std::size_t totalWords = (sizeof(T)*12)/sizeof(uint32_t);
    for (std::size_t i = 0; i < totalWords; ++i) {
        uint32_t tmp = master.readWord(curAddress);
        for (std::size_t j = 0; j < sizeof(uint32_t)/sizeof(T); ++j) {
            data[index] = static_cast<T>(tmp);
            index++;
            if (sizeof(T) != sizeof(uint32_t)) {
                tmp >>= sizeof(T)*8;
            }
        }
        curAddress += 4;
    }
    for (std::size_t i = 0; i < 12; ++i) {
        std::cout << std::dec << "At index " << i << " value " << (int)data[i] << std::endl;
    }
}

static void dumpList(DeppUartMaster& master) {
    uint32_t curAddress = 0x120000;
    std::cout << "32 bit:" << std::endl;
    dumpSubList<int32_t>(master, curAddress);
    curAddress = 0x120030;
    std::cout << "16 bit:" << std::endl;
    dumpSubList<int16_t>(master, curAddress);
    curAddress = 0x120048;
    std::cout << "8 bit:" << std::endl;
    dumpSubList<int8_t>(master, curAddress);
}

static void writeAndVerify(DeppUartMaster& master, const std::string& filePath, uint32_t startAddress) {
    std::vector<uint32_t> data = readFromFile(filePath);
    uint32_t currentAddress = startAddress;
    for (uint32_t elem : data) {
        master.writeWord(currentAddress, elem);
        currentAddress += 4;
    }
    currentAddress = startAddress;
    for (size_t i = 0; i < data.size(); ++i) {
        uint32_t readData = master.readWord(currentAddress);
        if (data[i] != readData) {
            std::cout << std::hex << "Validation failed at address " << currentAddress << " expected data " << data[i] << " received data " << readData << std::dec << std::endl;
        }
        currentAddress += 4;
    }
}

static void clearMemory(DeppUartMaster& master, uint32_t startAddress, uint32_t wordCount) {
    uint32_t currentAddress = startAddress;
    for (uint32_t i = 0; i < wordCount; ++i) {
        master.writeWord(currentAddress, 0);
        currentAddress += 4;
    }
}

static void printClockSpeed(DeppUartMaster& master) {
    uint32_t clkSpeed = master.readWord(cpuBaseAddress + 4);
    std::cout << "Clock speed is " << clkSpeed << " Hz." << std::endl;
}

static void dumpRegFile(DeppUartMaster& master) {
    uint32_t currentAddress = cpuBaseAddress + (32*4);
    for (size_t i = 0; i < 32; ++i) {
        uint32_t readData = master.readWord(currentAddress);
        std::cout << std::dec << "$" << i << std::hex << ": " << readData << std::dec << std::endl;
        currentAddress += 4;
    }
}

int main(int argc, char* argv[]) {
    DeppUartMaster master;
    master.selfTest();
    if (argc < 2) {
        std::cout << "Expected 1 argument: the file path" << std::endl;
        return EXIT_FAILURE;
    }
    std::string path(argv[1]);
    printClockSpeed(master);
    writeAndVerify(master, path, spiMemStartAddress);
    clearMemory(master, 0x120000, 25);
    uint32_t cpuStatus = master.readWord(cpuBaseAddress);
    dumpRegFile(master);
    std::cout << std::hex << "cpuStatus, pre run: 0x" << cpuStatus << std::endl;
    dumpList(master);
    master.writeWord(cpuBaseAddress, 0x0);
    usleep(1000);
    master.writeWord(cpuBaseAddress, 0x1);
    cpuStatus = master.readWord(cpuBaseAddress);
    std::cout << std::hex << "cpuStatus, post run: 0x" << cpuStatus << std::endl;
    dumpRegFile(master);
    dumpList(master);
    return 0;
}
