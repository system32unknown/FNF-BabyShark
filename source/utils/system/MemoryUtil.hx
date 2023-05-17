package utils.system;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
import openfl.system.System;

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
			size = size / 1024;
		}

		size = Math.round(size * 100) / 100;
		return '$size ${intervalArray[data]}';
	}

	inline public static function Gcenable(?enabled:Bool = true) {
		#if (cpp || hl)
		Gc.enable(enabled);
		#end
	}

	inline public static function getMEM():Float {
		#if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#elseif sys
		return cast(cast(System.totalMemory, UInt), Float);
		#else
		return 0;
		#end
	}
}