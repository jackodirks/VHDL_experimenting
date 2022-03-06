#include <iostream>
#include <string>

#include "deppMaster.hpp"

int main(void)
{
    DeppMaster master("Basys2");
    uint8_t data[2048] = {0};
    uint8_t retData[2048] = {0};
    for (size_t i = 0; i < 2048; i += 1) {
        data[i] = (i & 0xff);
    }
    master.setDataBulk(&data[0], 2048, 0x0);
    master.getDataBulk(&retData[0], 2048, 0x0);

    for (size_t i = 0; i < 2048; i += 1) {
        if (data[i] != retData[i]) {
            std::cout << "Error at " << i << " Expected: " << (uint32_t)data[i] << " but got: " << (uint32_t)retData[i] << std::endl;
        }
    }

    return 0;
}
