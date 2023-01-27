package utils;

#if cpp
import cpp.vm.Gc;
import cpp.NativeGc;
#end
import openfl.system.System;

class MemoryUtil {
	public static function clearMajor() {
		#if cpp
		Gc.run(true);
		Gc.compact();
		#end
	}

	public static function getMemUsage(type:String):Int {
		var mem = 0;
		switch (type) {
			case "cpp": mem = Std.int(NativeGc.memInfo(0));
			case "system": mem = cast(System.totalMemory, UInt);
			case "gc": mem = Std.int(Gc.memInfo64(Gc.MEM_INFO_USAGE));
		}
		return mem;
	}
}