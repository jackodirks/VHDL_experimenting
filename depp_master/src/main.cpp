#include <iostream>
#include <string>

#include "deppMaster.hpp"

static constexpr uint32_t sevenSegStart = 0x0;
static constexpr uint32_t bMemStart = 0x1000;
static constexpr uint32_t spiMem0Start = 0x100000;
static constexpr uint32_t spiMem1Start = 0x120000;
static constexpr uint32_t spiMem2Start = 0x140000;


static void testSpiMem(DeppMaster& master) {
    static constexpr size_t buflen = 0x20000;
    uint8_t data[buflen] = {0};
    uint8_t retData[buflen] = {0};
    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = i & 0xff;
    }
    master.setDataBulk(&data[0], buflen, spiMem0Start);
    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = (i + buflen) & 0xff;
    }
    master.setDataBulk(&data[0], buflen, spiMem1Start);
    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = (i + buflen + buflen) & 0xff;
    }
    master.setDataBulk(&data[0], buflen, spiMem2Start);

    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = i & 0xff;
    }
    master.getDataBulk(&retData[0], buflen, spiMem0Start);
    for (size_t i = 0; i < buflen; i += 1) {
        if (data[i] != retData[i]) {
            std::cout << "SpiMem0: Error at " << i << " Expected: " << (uint32_t)data[i] << " but got: " << (uint32_t)retData[i] << std::endl;
        }
    }

    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = (i + buflen) & 0xff;
    }
    master.getDataBulk(&retData[0], buflen, spiMem1Start);
    for (size_t i = 0; i < buflen; i += 1) {
        if (data[i] != retData[i]) {
            std::cout << "SpiMem1: Error at " << i << " Expected: " << (uint32_t)data[i] << " but got: " << (uint32_t)retData[i] << std::endl;
        }
    }

    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = (i + buflen + buflen) & 0xff;
    }
    master.getDataBulk(&retData[0], buflen, spiMem2Start);
    for (size_t i = 0; i < buflen; i += 1) {
        if (data[i] != retData[i]) {
            std::cout << "SpiMem2: Error at " << i << " Expected: " << (uint32_t)data[i] << " but got: " << (uint32_t)retData[i] << std::endl;
        }
    }
}

static void testBMem(DeppMaster& master) {
    static constexpr size_t buflen = 0x800;
    uint8_t data[buflen] = {0};
    uint8_t retData[buflen] = {0};
    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = i & 0xff;
    }
    master.setDataBulk(&data[0], buflen, bMemStart);
    master.getDataBulk(&retData[0], buflen, bMemStart);
    for (size_t i = 0; i < buflen; i += 1) {
        if (data[i] != retData[i]) {
            std::cout << "BMem: Error at " << i << " Expected: " << (uint32_t)data[i] << " but got: " << (uint32_t)retData[i] << std::endl;
        }
    }
}

static void testSevenSeg(DeppMaster& master) {
    static constexpr size_t buflen = 4;
    uint8_t data[buflen] = {0};
    uint8_t retData[buflen] = {0};
    for (size_t i = 0; i < buflen; i += 1) {
        data[i] = i;
    }
    master.setDataBulk(&data[0], buflen, sevenSegStart);
    master.getDataBulk(&retData[0], buflen, sevenSegStart);
    for (size_t i = 0; i < buflen; i += 1) {
        if (data[i] != retData[i]) {
            std::cout << "SevenSeg: Error at " << i << " Expected: " << (uint32_t)data[i] << " but got: " << (uint32_t)retData[i] << std::endl;
        }
    }
}

int main(void)
{
    DeppMaster master("Basys2");
    testSpiMem(master);
    testBMem(master);
    testSevenSeg(master);
    return 0;
}
