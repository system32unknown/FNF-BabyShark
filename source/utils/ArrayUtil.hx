package utils;

class ArrayUtil {
	public static function removeDuplicates<T>(arr:Array<T>):Array<T> {
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

	public static function isEqualUnordered<T>(a:Array<T>, b:Array<T>):Bool {
	  	if (a.length != b.length) return false;
	  	for (element in a) if (!b.contains(element)) return false;
	  	for (element in b) if (!a.contains(element)) return false;
	  	return true;
	}

	public static function isSuperset<T>(superset:Array<T>, subset:Array<T>):Bool {
	  	// Shortcuts.
	  	if (subset.length == 0) return true;
	  	if (subset.length > superset.length) return false;
	
	 	// Check each element.
	 	for (element in subset) if (!superset.contains(element)) return false;
	 	return true;
	}	

	inline public static function dynamicArray<T>(v:T, len:Int):Array<T> return [for (_ in 0...len) v];
}