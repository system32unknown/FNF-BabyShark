package utils;

class ArrayUtil {
	static function removeDuplicates<T>(arr:Array<T>):Array<T> {
		var uniqueArray:Array<T> = [];
    	var map:haxe.ds.StringMap<Bool> = new haxe.ds.StringMap<Bool>();

		// Remove duplicates
		for (elem in arr) {
			if (!map.exists(Std.string(elem))) {
				map.set(Std.string(elem), true);
				uniqueArray.push(elem);
			}
		}

		haxe.ds.ArraySort.sort(uniqueArray, (a:Dynamic, b:Dynamic) -> return (a == b) ? 0 : (a > b) ? 1 : -1);
		return uniqueArray;
	}

	inline public static function dynamicArray<T>(v:T, len:Int):Array<T> return [for (_ in 0...len) v];
}