package utils;

import flixel.util.FlxSort;

class SortUtil {
    public static function byID(Obj1:Dynamic, Obj2:Dynamic):Int {
        return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);
    }
    public static function byStrumTime(Obj1:Dynamic, Obj2:Dynamic):Int {
        return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
    }
}