#include <string>

#include "digilent/dpcdecl.h"

class DeppMaster {
    private:
        HIF hif;

        void DeppPutRegWrapper(const BYTE &bAddr, const BYTE &bData) const;
        void DeppGetRegWrapper(const BYTE &bAddr, BYTE *bData) const;
        
        void DeppPutRegSetWrapper(BYTE *pbAddrData, const DWORD &nAddrDataPairs) const;
        void DeppGetRegSetWrapper(BYTE *pbAddr, BYTE *pbData, const DWORD &cbData) const;

        void DeppPutRegRepeatWrapper(const BYTE &bAddr, BYTE *pbData, const DWORD cbData) const;
        void DeppGetRegRepeatWrapper(const BYTE &bAddr, BYTE *pbData, const DWORD cbData) const;

        void setWriteMask(const uint8_t &writeMask) const;
        void setAddress(uint32_t address) const;
        void forceRead() const;
        void forceWrite() const;

    public:
        explicit DeppMaster(const std::string& devStr);

        ~DeppMaster();

        void setDataBulk(const uint8_t* data, const size_t &count, const uint32_t &startAddress) const;
        void getDataBulk(uint8_t* data, const size_t &count, const uint32_t &startAddress) const;

        void setData(const uint32_t &data, const uint32_t &address, const uint8_t &writeMask = 0xff) const;
        void getData(uint32_t &data, const uint32_t &address) const;

        void setData(const uint16_t &data, const uint32_t &address) const;
        void getData(uint16_t &data, const uint32_t &address) const;

        void setData(const uint8_t &data, const uint32_t &address) const;
        void getData(uint8_t &data, const uint32_t &address) const;
};
