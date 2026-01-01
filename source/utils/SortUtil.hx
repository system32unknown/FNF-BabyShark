package utils;

import flixel.util.FlxSort;
import flixel.FlxBasic;

@:nullSafety
class SortUtil {
	public static function byID(Obj1:Dynamic, Obj2:Dynamic):Int {
		if (Obj1 == null || Obj2 == null) return 0;
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);
	}

	public static function byStrumTime(Obj1:Dynamic, Obj2:Dynamic):Int {
		if (Obj1 == null || Obj2 == null) return 0;
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public static inline function byZIndex(order:Int, a:FlxBasic, b:FlxBasic):Int {
		if (a == null || b == null) return 0;
		return FlxSort.byValues(order, a.zIndex, b.zIndex);
	}
}