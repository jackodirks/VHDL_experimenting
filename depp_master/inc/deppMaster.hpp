#include <string>
#include <vector>

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

        void prepareBusWriteTransaction(uint8_t writeMask, uint8_t burstLen, uint32_t address) const;
        void setAddress(uint32_t address) const;
        void updateBurstLen(uint8_t burstLen) const;
        void transmitWords(std::vector<uint32_t>::const_iterator& it, std::size_t count) const;

    public:
        explicit DeppMaster(const std::string& devStr);

        ~DeppMaster();

        void writeOperation(const std::vector<uint32_t>& data, uint32_t address, uint8_t writeMask) const;
        std::vector<uint32_t> readOperation(uint32_t address, std::size_t count);
};
