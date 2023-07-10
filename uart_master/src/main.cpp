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

static void dumpList(DeppUartMaster& master) {
    uint32_t curAddress = spiMemStartAddress + 0x98;
    for (std::size_t i = 0; i < 11; ++i) {
        int32_t tmp = master.readWord(curAddress);
        std::cout << std::dec << "At index " << i << " value " << tmp << std::endl;
        curAddress += 4;
    }
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

static void printClockSpeed(DeppUartMaster& master) {
    uint32_t clkSpeed = master.readWord(cpuBaseAddress + 4);
    std::cout << "Clock speed is " << clkSpeed << " Hz." << std::endl;
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
    uint32_t cpuStatus = master.readWord(cpuBaseAddress);
    std::cout << std::hex << "cpuStatus, pre run: 0x" << cpuStatus << std::endl;
    dumpList(master);
    master.writeWord(cpuBaseAddress, 0x0);
    usleep(200000);
    master.writeWord(cpuBaseAddress, 0x1);
    cpuStatus = master.readWord(cpuBaseAddress);
    std::cout << std::hex << "cpuStatus, post run: 0x" << cpuStatus << std::endl;
    dumpList(master);
    return 0;
}
