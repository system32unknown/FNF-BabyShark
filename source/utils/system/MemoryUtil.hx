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
		#elseif hl
		Gc.major();
		#else
		openfl.system.System.gc();
		#end
	}

    inline public static function getMEM():Float {
        #if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#elseif sys
		return cast(openfl.system.System.totalMemory, UInt);
		#else
		return 0;
		#end
    }

	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	public static function getTotalRam():Float return 0;
}