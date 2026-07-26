#pragma once

#include <cstddef>

/**
 * @brief Returns the current process Resident Set Size (RSS).
 *
 * RSS is the amount of physical memory currently occupied by the process.
 *
 * @return RSS in bytes, or 0 on failure.
 */
size_t GetCurrentRSS();