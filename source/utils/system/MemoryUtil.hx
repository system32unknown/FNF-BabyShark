package utils.system;

#if cpp
import cpp.vm.Gc;
#elseif sys
import openfl.system.System;
#end

class MemoryUtil {
	public static function clearMajor(?minor:Bool = false) {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
		#else
		System.gc();
		#end
	}

    public static function getMEM():Float {
        #if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#elseif sys
		return cast(System.totalMemory, UInt);
		#else
		return 0;
		#end
    }
}