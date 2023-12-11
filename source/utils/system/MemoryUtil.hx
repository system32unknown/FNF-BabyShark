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
		#elseif hl
		Gc.major();
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
		#elseif hl
		return hl.Gc.stats().totalAllocated;
		#elseif (js && html5)
		return untyped #if haxe4 js.Syntax.code #else __js__ #end ("(window.performance && window.performance.memory) ? window.performance.memory.usedJSHeapSize : 0");
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