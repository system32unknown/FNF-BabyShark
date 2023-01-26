package utils;

#if cpp
import cpp.vm.Gc;
import cpp.NativeGc;
#end
import openfl.system.System;

class MiscUtil {
    static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB'];

	public static function getInterval(num:UInt):String {
		var size:Float = num;
		var data = 0;
		while (size > 1024 && data < intervalArray.length - 1) {
			data++;
			size = size / 1024;
		}

		size = Math.round(size * 100) / 100;
		return '$size ${intervalArray[data]}';
	}

	public static function getMemoryUsage(type:String):Int {
		var mem = 0;
		switch (type) {
			case "cpp": mem = Std.int(NativeGc.memInfo(0));
			case "system": mem = System.totalMemory;
			case "gc": mem = Std.int(Gc.memInfo64(Gc.MEM_INFO_USAGE));
		}
		return mem;
	}
}