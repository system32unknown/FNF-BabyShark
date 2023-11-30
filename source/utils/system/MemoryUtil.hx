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
		#elseif (java || neko)
		Gc.run(true);
		#end
	}

	public static function getInterval(num:Float):String {
		final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB'];
		
		var size:Float = num;
		var data = 0;
		while (size > 1024 && data < intervalArray.length - 1) {
			data++;
			size /= 1024;
		}

		size = Math.round(size * 100) / 100;
		return '$size ${intervalArray[data]}';
	}

	inline public static function getMEM():Dynamic {
		#if cpp
		return getTotalMEM();
		#else
		return 0;
		#end
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