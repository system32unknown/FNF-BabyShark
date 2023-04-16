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
	public static var disableCount:Int = 0;

	public static function askDisable() {
		disableCount++;
		if (disableCount > 0)
			Gcenable(false);
		else Gcenable();
	}
	public static function askEnable() {
		disableCount--;
		if (disableCount > 0)
			Gcenable(false);
		else Gcenable();
	}

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

	public static function getMEMtype():Dynamic {
		switch (ClientPrefs.getPref('MEMType')) {
			case 'Cast': return cast(cast(System.totalMemory, UInt), Float);
			case 'Cpp': return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		}
		return 0;
	}
}