package utils.system;

#if cpp
import cpp.vm.Gc;
#end

class MemoryUtil {
	public static function clearMajor(?minor:Bool = false) {
		#if cpp
		Gc.run(!minor);
		if (!minor) Gc.compact();
		#else
		if (!gc_Enabled) openfl.system.System.gc();
		#end
	}
	static var gc_Enabled:Bool = false;
	public static function gcEnable(enabled:Bool = false) {
		Gc.enable(gc_Enabled = enabled);
	}
}