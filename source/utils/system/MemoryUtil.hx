package utils.system;

import haxe.exceptions.NotImplementedException;
#if cpp
import cpp.vm.Gc;

#if windows
@:cppFileCode('
#include <windows.h>
#include <psapi.h>
')
#elseif linux
@:cppFileCode('#include <stdio.h>')
#elseif mac
@:cppFileCode('
#include <unistd.h>
#include <sys/resource.h>
#include <mach/mach.h>
')
#end
#end
class MemoryUtil {
	public static function clearMajor(?minor:Bool = false):Void {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
		#else
		openfl.system.System.gc();
		#end
	}
	public static function enable(on:Bool = true):Void {
		#if cpp
		Gc.enable(on);
		cpp.NativeGc.enable(on);
		#else
		throw new NotImplementedException();
		#end
	}
	/**
	 * Manually perform garbage collection once.
	 * Should only be called from the main thread.
	 * @param major `true` to perform major collection, whatever that means.
	 */
	public static function collect(major:Bool = false):Void {
		#if cpp
		Gc.run(major);
		#else
		throw new NotImplementedException();
		#end
	}

	/**
	 * Returns the current resident set size (physical memory use) measured
	 * in bytes, or zero if the value cannot be determined on this OS.
	 * @return gets Current Process Memory.
	 */
	#if cpp
	#if windows
	@:functionCode('
		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) return pmc.WorkingSetSize;
	')
	#elseif linux
	@:functionCode('
		long rss = 0L;
		FILE* fp = NULL;

		if ((fp = fopen("/proc/self/statm", "r")) == NULL) return 0L;
		if (fscanf(fp, "%*s%ld", &rss) != 1) {
			fclose(fp);
			return 0L;
		}
		fclose(fp);
		return rss * sysconf(_SC_PAGESIZE);
	')
	#elseif mac
	@:functionCode("
		struct mach_task_basic_info info;
		mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
		if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &infoCount) == KERN_SUCCESS) return info.resident_size;
	")
	#end
	#end
	public static function getProcessMEM():Float return 0;
}