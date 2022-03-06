#include <iostream>
#include <stdexcept>
#include <cstring>
#include <string>
#include <memory>

#include "digilent/dpcdecl.h"
#include "digilent/depp.h"
#include "digilent/dmgr.h"

#include "deppMaster.hpp"

// Address register is 4 byte
static constexpr BYTE addrRegStart = 0;
// Write data register is 4 byte
static constexpr BYTE writeDataRegStart = 4;
// Read data register is 4 byte
static constexpr BYTE readDataRegStart = 8;
// Write mask register is 1 byte
static constexpr BYTE writeMaskRegStart = 12;
// Mode register is 1 byte
static constexpr BYTE modeRegStart = 13;
// Fault register is 1 byte
static constexpr BYTE faultRegStart = 14;
// Activation register is 1 byte
static constexpr BYTE activationRegStart = 15;

// Mode bits
static constexpr BYTE modeFastRead = 1;
static constexpr BYTE modeFastWrite = 2;

// address & wordAlignMask results in a word aligned address
static constexpr uint32_t wordAlignMask = 0xfffffffc;

void DeppMaster::DeppPutRegWrapper(const BYTE &bAddr, const BYTE &bData) const
{
    if (!DeppPutReg(this->hif, bAddr, bData, false)) {
        throw std::invalid_argument("DeppPutReg failed");
    }
}

void DeppMaster::DeppGetRegWrapper(const BYTE &bAddr, BYTE *bData) const
{
    if (!DeppGetReg(this->hif, bAddr, bData, false)) {
        throw std::invalid_argument("DeppGetReg failed");
    }
}

void DeppMaster::DeppPutRegSetWrapper(BYTE *pbAddrData, const DWORD &nAddrDataPairs) const
{
    if (!DeppPutRegSet(this->hif, pbAddrData, nAddrDataPairs, false)) {
        throw std::invalid_argument("DeppPutRegSet failed");
    }
}

void DeppMaster::DeppGetRegSetWrapper(BYTE *pbAddr, BYTE *pbData, const DWORD &cbData) const
{
    if (!DeppGetRegSet(this->hif, pbAddr, pbData, cbData, false)) {
        throw std::invalid_argument("DeppGetRegSet failed");
    }
}

void DeppMaster::DeppPutRegRepeatWrapper(const BYTE &bAddr, BYTE *pbData, const DWORD cbData) const
{
    if (!DeppPutRegRepeat(this->hif, bAddr, pbData, cbData, false)) {
        throw std::invalid_argument("DeppPutRegRepeat failed");
    }
}

void DeppMaster::DeppGetRegRepeatWrapper(const BYTE &bAddr, BYTE *pbData, const DWORD cbData) const
{
    if (!DeppGetRegRepeat(this->hif, bAddr, pbData, cbData, false)) {
        throw std::invalid_argument("DeppGetRegRepeat failed");
    }
}

void DeppMaster::setWriteMask(const uint8_t &writeMask) const
{
    BYTE data = writeMask;
    DeppPutRegWrapper(writeMaskRegStart, data);
}


void DeppMaster::setAddress(uint32_t address) const
{
    BYTE pbAddrData[8];
    for (size_t i = 0; i < 8; i += 2) {
        pbAddrData[i] = addrRegStart + i/2;
        pbAddrData[i + 1] = address & 0xff;
        address >>= 8;
    }
    DeppPutRegSetWrapper(&pbAddrData[0], 4);
}

void DeppMaster::forceRead() const
{
    DeppPutRegWrapper(activationRegStart, 0x01);
}

void DeppMaster::forceWrite() const
{
    DeppPutRegWrapper(activationRegStart, 0x0);
}

DeppMaster::DeppMaster(const std::string& devStr)
{
    std::unique_ptr<char[]> szSel(new char[devStr.length() + 1]);
    strncpy(szSel.get(), devStr.c_str(), devStr.length());
    szSel[devStr.length()] = '\0';
    if (!DmgrOpen(&this->hif, szSel.get())) {
        throw std::invalid_argument("DmgrOpen failed (invalid device name?)");
    }
    if (!DeppEnable(this->hif)) {
        DmgrClose(this->hif);
        throw std::invalid_argument("DeppEnable failed");
    }

    // Enable fast read and fast write. Dont use the wrapper, we might need to destruct
    if (!DeppPutReg(this->hif, modeRegStart, modeFastRead | modeFastWrite, false)) {
        DeppDisable(this->hif);
        DmgrClose(this->hif);
        throw std::invalid_argument("DeppPutReg failed");
    }
}

DeppMaster::~DeppMaster()
{
    DeppDisable(this->hif);
    DmgrClose(this->hif);
}

void DeppMaster::setDataBulk(const uint8_t* data, const size_t &count, const uint32_t &startAddress) const
{
    if (count == 0) {
        return;
    }
    std::unique_ptr<BYTE[]> pbData(new BYTE[count]);
    for (size_t i = 0; i < count; ++i) {
        pbData[i] = data[i];
    }
    // This function takes care to do everything aligned.
    uint32_t addr = startAddress & wordAlignMask;
    // Set the start address
    setAddress(addr);
    // Write the unaligned head (if any)
    size_t headCnt = 4 - (startAddress & 0x3);
    if (headCnt < 4) {
        size_t actCnt = headCnt;
        if (count < headCnt) {
            actCnt = count;
        }
        uint8_t writeMask = 0x08 >> (headCnt - 1);
        if (actCnt == 2) {
            writeMask |= 0x08 >> (headCnt - 2);
        } else if (actCnt == 3) {
            writeMask |= 0xc;
        }
        setWriteMask(writeMask);
        DeppPutRegRepeatWrapper(writeDataRegStart + 4 - headCnt, &pbData[0], actCnt);
        if (actCnt < headCnt) {
            forceWrite();
        }
    } else {
        headCnt = 0;
    }
    if (headCnt >= count) {
        // We are already done
        return;
    }
    // Update the writeMask
    setWriteMask(0xf);
    // Write the bulk
    DeppPutRegRepeatWrapper(writeDataRegStart, &pbData[headCnt], count - headCnt);
    // Check if we have to finish differently
    size_t tailCnt = (startAddress + count) & 0x3;
    if (tailCnt > 0) {
        uint8_t writeMask = 0xf >> (4 - tailCnt);
        setWriteMask(writeMask);
        forceWrite();
    }
}

void DeppMaster::getDataBulk(uint8_t* data, const size_t &count, const uint32_t &startAddress) const
{
    uint32_t address = startAddress & wordAlignMask;
    size_t auxElements = startAddress - address;
    std::unique_ptr<BYTE[]> pbData(new BYTE[count + auxElements]);
    setAddress(address);
    DeppGetRegRepeatWrapper(readDataRegStart, &pbData[0], count + auxElements);
    for (size_t i = 0; i < count; i += 1) {
        data[i] = pbData[i + auxElements];
    }
}

void DeppMaster::setData(const uint32_t &data, const uint32_t &address, const uint8_t &writeMask) const
{
    setWriteMask(writeMask);
    setAddress(address);
    BYTE pData[4];
    for (size_t i = 0; i < 4; i += 1) {
        pData[i] = (data >> i*8) & 0xff;
    }
    DeppPutRegRepeatWrapper(writeDataRegStart, &pData[0], 4);
    // No need for a force write, since the transaction will autostart
}

void DeppMaster::getData(uint32_t &data, const uint32_t &address) const
{
    setAddress(address);
    BYTE pData[4];
    DeppGetRegRepeatWrapper(readDataRegStart, &pData[0], 4);
    data = pData[0] | (pData[1] << 8) | (pData[2] << 16) | (pData[3] << 24);
}

void DeppMaster::setData(const uint16_t &data, const uint32_t &address) const
{
    // First, set the write mask
    setWriteMask(0x0f);
    // Then, set the address
    setAddress(address);
    // Set the data
    BYTE pData[2];
    pData[0] = data & 0xff;
    pData[1] = (data >> 8) & 0xff;
    DeppPutRegRepeatWrapper(writeDataRegStart, &pData[0], 2);
    // Force a write
    forceWrite();

}

void DeppMaster::getData(uint16_t &data, const uint32_t &address) const
{
    // First set the address
    setAddress(address);
    // Then force a read
    forceRead();
    // Then read back
    BYTE ret[2];
    DeppGetRegRepeatWrapper(readDataRegStart, &ret[0], 2);
    data = ret[0] | (ret[1] << 8);
}

void DeppMaster::setData(const uint8_t &data, const uint32_t &address) const
{
    // First, set the write mask
    setWriteMask(0x01);
    // Then, set the address
    setAddress(address);
    // Set the data
    DeppPutRegWrapper(writeDataRegStart, data);
    // Force a write
    forceWrite();
}

void DeppMaster::getData(uint8_t &data, const uint32_t &address) const
{
    BYTE ret;
    // First set the address
    setAddress(address);
    // Then force a read
    forceRead();
    // Then read back
    DeppGetRegWrapper(readDataRegStart, &ret);
    data = ret;
}
