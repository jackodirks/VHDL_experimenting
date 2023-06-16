#include <iostream>
#include <cassert>

#include "deppUartMaster.hpp"

static constexpr uint32_t spiMemStartAddress = 0x100000;
static constexpr uint32_t spiMemLength = 0x60000;

int main() {
    std::cout << "Hello, world!" << std::endl;
    DeppUartMaster master;
    master.selfTest();
    master.writeWord(spiMemStartAddress, 0x1);
    for (size_t i = 0; i < 128; ++i) {
        master.writeWord(spiMemStartAddress + i*4, i);
    }
    for (size_t i = 0; i < 128; ++i) {
        uint32_t data = master.readWord(spiMemStartAddress + i*4);
        assert(data == i);
    }
    return 0;
}
