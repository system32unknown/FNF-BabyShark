package utils.tools;

/**
 * A static extension which provides utility functions for Arrays.
 */
class ArrayTools {
	/**
	 * Return true only if both arrays contain the same elements (possibly in a different order).
	 * @param a The first array to compare.
	 * @param b The second array to compare.
	 * @return Weather both arrays contain the same elements.
	 */
	public static function isEqualUnordered<T>(a:Array<T>, b:Array<T>):Bool {
		if (a.length != b.length) return false;
		for (element in a) if (!b.contains(element)) return false;
		for (element in b) if (!a.contains(element)) return false;
		return true;
	}

	/**
	 * Returns true if `superset` contains all elements of `subset`.
	 * @param superset The array to query for each element.
	 * @param subset The array containing the elements to query for.
	 * @return Weather `superset` contains all elements of `subset`.
	 */
	public static function isSuperset<T>(superset:Array<T>, subset:Array<T>):Bool {
		// Shortcuts.
		if (subset.length == 0) return true;
		if (subset.length > superset.length) return false;

		// Check each element.
		for (element in subset) if (!superset.contains(element)) return false;
		return true;
	}

	/**
	 * Returns true if `superset` contains all elements of `subset`.
	 * @param subset The array containing the elements to query for.
	 * @param superset The array to query for each element.
	 * @return Weather `superset` contains all elements of `subset`.
	 */
	public static function isSubset<T>(subset:Array<T>, superset:Array<T>):Bool {
		// Switch it around.
		return isSuperset(superset, subset);
	}

	/**
	 * Deep flattens an array.
	 * Example: `deepFlatten([1, [2, 3], 4])` will return `[1, 2, 3, 4]`
	 * @param arr Array to flatten
	 * @param result Result array
	 */
	public static function deepFlatten(arr:Array<Dynamic>, ?result:Array<Dynamic>):Array<Dynamic> {
		if (arr == null) return [];
		if (result == null) result = [];
		for (e in arr) {
			if (Std.isOfType(e, Array)) deepFlatten(e, result);
			else result.push(e);
		}
		return result;
	}
}
