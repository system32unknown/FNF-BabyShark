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
}