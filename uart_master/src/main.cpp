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

static void writeFile(DeppUartMaster& master, const std::string& filePath, uint32_t startAddress) {
    std::vector<uint32_t> data = readFromFile(filePath);
    master.writeWordSequence(startAddress, data);
}

static bool verifyWrite(DeppUartMaster& master, const std::string& filePath, uint32_t startAddress) {
    std::vector<uint32_t> data = readFromFile(filePath);
    uint32_t currentAddress = startAddress;
    bool success = true;
    std::vector<uint32_t> dataFromDevice = master.readWordSequence(startAddress, data.size());
    for (size_t i = 0; i < data.size(); ++i) {
        if (data[i] != dataFromDevice[i]) {
            std::cout << std::hex << "Validation failed at address " << currentAddress << " expected data " << data[i] << " received data " << dataFromDevice[i] << std::dec << std::endl;
            success = false;
        }
        currentAddress += 4;
    }
    return success;
}

static void startProcessor(DeppUartMaster& master) {
    master.writeWord(cpuBaseAddress, 0x0);
}

static void stopProcessor(DeppUartMaster& master) {
    master.writeWord(cpuBaseAddress, 0x1);
}

int main(int argc, char* argv[]) {
    DeppUartMaster master;
    master.selfTest();
    std::cout << "Bus selftest completed OK" << std::endl;
    if (argc < 2) {
        std::cout << "Expected 1 argument: the file path" << std::endl;
        return EXIT_FAILURE;
    }
    std::string path(argv[1]);
    std::cout << "Stop the CPU" << std::endl;
    stopProcessor(master);
    std::cout << "Write" << std::endl;
    writeFile(master, path, spiMemStartAddress);
    std::cout << "Verify" << std::endl;
    bool success = verifyWrite(master, path, spiMemStartAddress);
    if (!success) {
        std::cout << "Not starting the CPU due to verification errors" << std::endl;
        return EXIT_FAILURE;
    }
    std::cout << "Start the CPU" << std::endl;
    startProcessor(master);
    return EXIT_SUCCESS;
}
