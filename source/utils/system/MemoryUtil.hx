package utils.system;

#if cpp
import cpp.vm.Gc;
#end

@:cppFileCode("
#include <windows.h>
#include <psapi.h>
")
class MemoryUtil {
	inline public static function clearMajor(?minor:Bool = false) {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
		#else
		openfl.system.System.gc();
		#end
	}

	@:functionCode("
		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc)))
			return static_cast<int>(pmc.WorkingSetSize);
		else return 0;
	")
	public static function getMEM():Int return 0;
}