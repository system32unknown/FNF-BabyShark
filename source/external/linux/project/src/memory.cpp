#include "memory.hpp"

#include <cstdio>
#include <unistd.h>

size_t GetCurrentRSS() {
    long rssPages = 0;

    FILE* fp = std::fopen("/proc/self/statm", "r");
    if (fp == nullptr) return 0;

    if (std::fscanf(fp, "%*s%ld", &rssPages) != 1) {
        std::fclose(fp);
        return 0;
    }

    std::fclose(fp);
    
    const long pageSize = sysconf(_SC_PAGESIZE);
    return (size_t)rssPages * (size_t)pageSize;
}