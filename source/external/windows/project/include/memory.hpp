#pragma once

/**
 * Retrieves the current working set size (in bytes) of the calling process.
 *
 * This function queries the operating system for the amount of physical memory currently allocated to the process (its working set).
 *
 * @return The working set size in bytes. Returns 0 if the query fails.
 */
size_t GetCurrentRSS();