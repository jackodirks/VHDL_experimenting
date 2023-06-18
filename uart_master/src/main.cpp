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
    dumpList(master);
    master.writeWord(cpuBaseAddress, 0x0);
    usleep(200000);
    master.writeWord(cpuBaseAddress, 0x1);
    cpuStatus = master.readWord(cpuBaseAddress);
    std::cout << std::hex << "cpuStatus, post run: 0x" << cpuStatus << std::endl;
    dumpList(master);
    return 0;
}
