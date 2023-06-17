#include <iostream>
#include <cassert>
#include <fstream>
#include <iterator>
#include <vector>
#include <unistd.h>

#include "deppUartMaster.hpp"
#include "inputFile.hpp"

static constexpr uint32_t spiMemStartAddress = 0x100000;
static constexpr uint32_t spiMemLength = 0x60000;
static constexpr uint32_t cpuBaseAddress = 0x2000;

int main(int argc, char* argv[]) {
    DeppUartMaster master;
    master.selfTest();
    if (argc < 2) {
        std::cout << "Expected 1 argument: the file path" << std::endl;
        return EXIT_FAILURE;
    }
    std::string path(argv[1]);
    std::vector<uint32_t> data = readFromFile(path);
    uint32_t currentAddress = spiMemStartAddress;
    for (uint32_t elem : data) {
        master.writeWord(currentAddress, elem);
        currentAddress += 4;
    }
    uint32_t cpuStatus = master.readWord(cpuBaseAddress);
    std::cout << std::hex << "cpuStatus, pre run: 0x" << cpuStatus << std::endl;
    uint32_t result = master.readWord(spiMemStartAddress + 0x2C);
    std::cout << std::hex << "result, pre run: 0x" << result << std::endl;
    master.writeWord(cpuBaseAddress, 0x0);
    usleep(200000);
    master.writeWord(cpuBaseAddress, 0x1);
    result = master.readWord(spiMemStartAddress + 0x2C);
    std::cout << std::hex << "result, post run: 0x" << result << std::endl;
    cpuStatus = master.readWord(cpuBaseAddress);
    std::cout << std::hex << "cpuStatus, post run: 0x" << cpuStatus << std::endl;
    return 0;
}
