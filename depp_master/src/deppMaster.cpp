#include <iostream>
#include <stdexcept>
#include <cstring>
#include <string>
#include <memory>

#include "digilent/dpcdecl.h"
#include "digilent/depp.h"
#include "digilent/dmgr.h"

#include "deppMaster.hpp"

static constexpr BYTE faultDataRegStart = 0;
static constexpr BYTE faultAddressRegStart = 1;
static constexpr BYTE writeMaskRegStart = 5;
static constexpr BYTE burstLengthRegStart = 6;
static constexpr BYTE addressRegStart = 7;
static constexpr BYTE readWriteRegStart = 11;

static constexpr std::size_t maxBurstSize = 255;

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

void DeppMaster::prepareBusWriteTransaction(uint8_t writeMask, uint8_t burstLen, uint32_t address) const {
    BYTE pbData[6];
    pbData[0] = writeMask;
    pbData[1] = burstLen;
    for (size_t i = 2; i < 6; ++i) {
        pbData[i] = address & 0xff;
        address >>= 8;
    }
    this->DeppPutRegRepeatWrapper(writeMaskRegStart, &pbData[0], 6);
}

void DeppMaster::setAddress(uint32_t address) const
{
    BYTE pbData[4];
    for (size_t i = 0; i < 4; i ++) {
        pbData[i] = address & 0xff;
        address >>= 8;
    }
    this->DeppPutRegRepeatWrapper(addressRegStart, &pbData[0], 4);
}

void DeppMaster::updateBurstLen(uint8_t burstLen) const {
    BYTE bData = burstLen;
    this->DeppPutRegWrapper(burstLengthRegStart, bData);
}

void DeppMaster::transmitWords(std::vector<uint32_t>::const_iterator& it, std::size_t count) const {
    std::vector<BYTE> pbData(count*4);
    for (std::size_t i = 0; i < count; ++i) {
        std::size_t pdDataIndex = i*4;
        uint32_t address = *it;
        for (std::size_t j = 0; j < 4; ++j) {
            pbData[pdDataIndex + j] = address & 0xff;
            address >>= 8;
        }
        std::advance(it, 1);
    }
    this->DeppPutRegRepeatWrapper(readWriteRegStart, pbData.data(), count*4);
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
}

DeppMaster::~DeppMaster()
{
    DeppDisable(this->hif);
    DmgrClose(this->hif);
}

void DeppMaster::writeOperation(const std::vector<uint32_t>& data, uint32_t address, uint8_t writeMask) const {
    std::size_t count = data.size();
    if (count == 0)
        return;

    std::vector<BYTE> pbData;
    for (uint32_t d : data) {
        for (std::size_t j = 0; j < 4; ++j) {
            pbData.push_back(d & 0xff);
            d >>= 8;
        }
    }
    this->prepareBusWriteTransaction(writeMask, 0, address);
    this->DeppPutRegRepeatWrapper(readWriteRegStart, &pbData.data()[0], 4*count);
}

std::vector<uint32_t> DeppMaster::readOperation(uint32_t address, std::size_t count) {
    std::size_t origCount = count;
    if (count == 0) {
        return std::vector<uint32_t>();
    }
    std::vector<BYTE> pbData(count*4);
    this->setAddress(address);
    std::size_t pbDataIndex = 0;
    this->DeppGetRegRepeatWrapper(readWriteRegStart, &pbData.data()[pbDataIndex*4], 4*count);

    std::vector<uint32_t> retval;
    for (size_t i = 0; i < origCount; ++i) {
        uint32_t data = pbData[i*4] | ((uint32_t)pbData[i*4 + 1] << 8) | ((uint32_t)pbData[i*4 + 2] << 16) | ((uint32_t)pbData[i*4 + 3] << 24);
        retval.push_back(data);
    }
    return retval;
}
