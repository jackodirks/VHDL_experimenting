#include <iostream>
#include <string>

#include "deppMaster.hpp"

static constexpr uint32_t sevenSegStart = 0x0;
static constexpr std::size_t sevenSegWordCount = 1;
static constexpr uint32_t bMemStart = 0x1000;
static constexpr std::size_t bMemWordCount = 512;
static constexpr uint32_t spiMem0Start = 0x100000;
static constexpr uint32_t spiMem1Start = 0x120000;
static constexpr uint32_t spiMem2Start = 0x140000;
static constexpr std::size_t spiMemWordCount = 32768;


static void testSpiMem(DeppMaster& master) {
    std::vector<uint32_t> transmitDataMem0;
    std::vector<uint32_t> transmitDataMem1;
    std::vector<uint32_t> transmitDataMem2;
    for (size_t i = 0; i < spiMemWordCount; i += 1) {
        transmitDataMem0.push_back(i);
        transmitDataMem1.push_back(i+spiMemWordCount);
        transmitDataMem2.push_back(UINT32_MAX - i);
    }
    master.writeOperation(transmitDataMem0, spiMem0Start, 0xff);
    master.writeOperation(transmitDataMem1, spiMem1Start, 0xff);
    master.writeOperation(transmitDataMem2, spiMem2Start, 0xff);
    std::vector<uint32_t> receiveDataMem0 = master.readOperation(spiMem0Start, spiMemWordCount);
    std::vector<uint32_t> receiveDataMem1 = master.readOperation(spiMem1Start, spiMemWordCount);
    std::vector<uint32_t> receiveDataMem2 = master.readOperation(spiMem2Start, spiMemWordCount);
    for (size_t i = 0; i < spiMemWordCount; i += 1) {
        if (transmitDataMem0[i] != receiveDataMem0[i]) {
            std::cout << "SpiMem0: Error at " << i << " Expected: " << transmitDataMem0[i] << " but got: " << receiveDataMem0[i] << std::endl;
        }
        if (transmitDataMem1[i] != receiveDataMem1[i]) {
            std::cout << "SpiMem1: Error at " << i << " Expected: " << transmitDataMem1[i] << " but got: " << receiveDataMem1[i] << std::endl;
        }
        if (transmitDataMem2[i] != receiveDataMem2[i]) {
            std::cout << "SpiMem2: Error at " << i << " Expected: " << transmitDataMem2[i] << " but got: " << receiveDataMem2[i] << std::endl;
        }
    }
}

static void testBMem(DeppMaster& master) {
    std::vector<uint32_t> transmitData;

    for (size_t i = 0; i < bMemWordCount; i += 1) {
        transmitData.push_back(i);
    }
    master.writeOperation(transmitData, bMemStart, 0xff);
    std::vector<uint32_t> receiveData = master.readOperation(bMemStart, bMemWordCount);
    for (size_t i = 0; i < bMemWordCount; i += 1) {
        if (transmitData[i] != receiveData[i]) {
            std::cout << "BMem: Error at " << i << " Expected: " << (uint32_t)transmitData[i] << " but got: " << (uint32_t)receiveData[i] << std::endl;
        }
    }
}

static void testSevenSeg(DeppMaster& master) {
    std::vector<uint32_t> transmitData;
    transmitData.push_back(0x04030201);
    master.writeOperation(transmitData, sevenSegStart, 0x0f);
    std::vector<uint32_t> receiveData = master.readOperation(sevenSegStart, sevenSegWordCount);
    for (size_t i = 0; i < sevenSegWordCount; i += 1) {
        if (transmitData[i] != receiveData[i]) {
            std::cout << "SevenSeg: Error at " << i << " Expected: " << transmitData[i] << " but got: " << receiveData[i] << std::endl;
        }
    }
}

int main(void)
{
    DeppMaster master("Basys2");
    testSpiMem(master);
    testSevenSeg(master);
    testBMem(master);
    return 0;
}
