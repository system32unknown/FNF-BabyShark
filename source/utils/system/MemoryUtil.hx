package utils.system;

#if cpp
import cpp.vm.Gc;
#elseif sys
import openfl.system.System;
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
		System.gc();
		#end
	}

	inline public static function getMEM():Dynamic {
		return #if cpp getTotalMEM() #else 0 #end;
	}

	public static function getGCMEM():Float {
		#if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#elseif sys
		return cast(System.totalMemory, UInt);
		#else
		return 0;
		#end
	}

	@:functionCode("
		PROCESS_MEMORY_COUNTERS info;
		if (GetProcessMemoryInfo(GetCurrentProcess(), &info, sizeof(info)))
			return (size_t)info.WorkingSetSize;
	")
	public static function getTotalMEM():Int return 0;
}