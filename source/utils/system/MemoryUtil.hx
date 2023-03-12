package utils.system;

#if cpp
import cpp.vm.Gc;
#end

class MemoryUtil {
	public static function clearMajor(?minor:Bool = false) {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
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
}