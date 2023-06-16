#include <cstdlib>
#include <cstdio>
#include <cstdint>
#include <cerrno>
#include <cstring>
#include <ios>
#include <sys/stat.h>
#include <cassert>

#include "inputFile.hpp"

std::vector<uint32_t> readFromFile(const std::string &filename)
{
    struct stat st;
    if (stat(filename.c_str(), &st) == -1) {
        throw std::system_error(errno, std::generic_category(), "When calling stat");
    }
    assert(st.st_size % 4 == 0);
    std::vector<uint32_t> buf(st.st_size/4);
    FILE *stream = fopen(filename.c_str(), "rb");
    if (stream == nullptr) {
        throw std::system_error(errno, std::generic_category(), "When opening file");
    }
    errno = 0;
    fread(buf.data(), 4, st.st_size/4, stream);
    fclose(stream);
    if (errno != 0) {
        throw std::system_error(errno, std::generic_category(), "When reading file");
    }
    return buf;
}
