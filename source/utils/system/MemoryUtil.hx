package utils.system;

#if cpp
import cpp.vm.Gc;
#end

#if (cpp && windows)
@:cppFileCode('
#include <windows.h>
#include <psapi.h>
')
#end
class MemoryUtil {
	public static function clearMajor(?minor:Bool = false) {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
		#else
		if (!gc_Enabled) openfl.system.System.gc();
		#end
	}
	static var gc_Enabled:Bool = false;
	public static function gcEnable(enabled:Bool = false) {
		Gc.enable(gc_Enabled = enabled);
	}

 	/**
    * Returns the amount of memory currently used by the program, in bytes.
    * On Windows, this returns the process memory usage. Otherwise this returns the amount of memory the garbage collector is allowed to use.
    */
	#if (cpp && windows)
	@:functionCode('
		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) return pmc.WorkingSetSize;
	')
	#end
	public static function getProcessMEM():Float {
		return 0;
	}
}