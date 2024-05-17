package utils;

class ArraySortUtil {
	/**
	 * Sorts the input array using the merge sort algorithm.
	 * Stable and guaranteed to run in linearithmic time `O(n log n)`,
	 * but less efficient in "best-case" situations.
	 *
	 * @param input The array to sort in-place.
	 * @param compare The comparison function to use.
	 */
	public static function mergeSort<T>(input:Array<T>, compare:CompareFunction<T>):Void {
		if (input == null || input.length <= 1) return;
		if (compare == null) throw 'No comparison function provided.';

		// Haxe implements merge sort by default.
		haxe.ds.ArraySort.sort(input, compare);
	}

	/**
	 * Sorts the input array using the quick sort algorithm.
	 * More efficient on smaller arrays, but is inefficient `O(n^2)` in "worst-case" situations.
	 * Not stable; relative order of equal elements is not preserved.
	 *
	 * @see https://stackoverflow.com/questions/33884057/quick-sort-stackoverflow-error-for-large-arrays
	 *      Fix for stack overflow issues.
	 * @param input The array to sort in-place.
	 * @param compare The comparison function to use.
	 */
	public static function quickSort<T>(input:Array<T>, compare:CompareFunction<T>):Void {
		if (input == null || input.length <= 1) return;
		if (compare == null) throw 'No comparison function provided.';

		quickSortInner(input, 0, input.length - 1, compare);
	}

	/**
	 * Internal recursive function for the quick sort algorithm.
	 * Written with ChatGPT!
	 */
	static function quickSortInner<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Void {
		// When low == high, the array is empty or too small to sort.

		// EDIT: Recurse on the smaller partition, and loop for the larger partition.
		while (low < high) {
			// Designate the first element in the array as the pivot, then partition the array around it.
			// Elements less than the pivot will be to the left, and elements greater than the pivot will be to the right.
			// Return the index of the pivot.
			var pivot:Int = quickSortPartition(input, low, high, compare);
			if ((pivot) - low <= high - (pivot + 1)) {
				quickSortInner(input, low, pivot, compare);
				low = pivot + 1;
			} else {
				quickSortInner(input, pivot + 1, high, compare);
				high = pivot;
			}
		}
	}

	/**
	 * Internal function for sorting a partition of an array in the quick sort algorithm.
	 * Written with ChatGPT!
	 */
	static function quickSortPartition<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Int {
		// Designate the first element in the array as the pivot.
		var pivot:T = input[low];
		// Designate two pointers, used to divide the array into two partitions.
		var i:Int = low - 1;
		var j:Int = high + 1;

		while (true) {
			// Move the left pointer to the right until it finds an element greater than the pivot.
			do {
				i++;
			} while (compare(input[i], pivot) < 0);

			// Move the right pointer to the left until it finds an element less than the pivot.
			do {
				j--;
			} while (compare(input[j], pivot) > 0);

			// If i and j have crossed, the array has been partitioned, and the pivot will be at the index j.
			if (i >= j) return j;

			// Else, swap the elements at i and j, and start over.
			// This slowly moves the pivot towards the middle of the partition,
			// while moving elements less than the pivot to the left and elements greater than the pivot to the right.
			var temp:T = input[i];
			input[i] = input[j];
			input[j] = temp;
		}

		// Don't expect to get here.
		return -1;
	}

	/**
	 * Gets the index of a possible new element of an Array of T using an efficient algorithm.
	 * @param array Array of T to check in
	 * @param getVal Function that returns the position value of T
	 * @return Index
	 */
    public static inline function binarySearch<T>(array:Array<T>, val:Float, getVal:T -> Float):Int {
		if (array.length <= 0) return 0; // if the array is empty, it should be equal to zero (the beginning)
		if (getVal(array[0]) > val) return 0; // in case its the minimum
		if (getVal(array[array.length - 1]) < val) return array.length; // in case its the maximum

		// binary search
		var iMin:Int = 0;
		var iMax:Int = array.length - 1;

		var i:Int = 0;
		var mid:Float;
		while(iMin <= iMax) {
			i = Math.floor((iMin + iMax) / 2);
			mid = getVal(array[i]);
			if (mid < val) iMin = i + 1
			else if (mid > val) iMax = i - 1;
			else {
				iMin = i;
				break;
			}
		}
		return iMin;
	}

	/**
	 * Adds to a sorted array, using binary search.
	 * @param array Array to add to
	 * @param val Value to add
	 * @param getVal Function that returns the value that needs to be sorted
	 */
    public static inline function addSorted<T>(array:Array<T>, val:T, getVal:T->Float) {
		if (val != null) array.insert(binarySearch(array, getVal(val), getVal), val);
	}

	/**
	 * Sorts the input array using the insertion sort algorithm.
	 * Stable and is very fast on nearly-sorted arrays,
	 * but is inefficient `O(n^2)` in "worst-case" situations.
	 *
	 * @param input The array to sort in-place.
	 * @param compare The comparison function to use.
	 */
	public static function insertionSort<T>(input:Array<T>, compare:CompareFunction<T>):Void {
		if (input == null || input.length <= 1) return;
		if (compare == null) throw 'No comparison function provided.';

		// Iterate through the array, starting at the second element.
		for (i in 1...input.length) {
			// Store the current element.
			var current:T = input[i];
			// Store the index of the previous element.
			var j:Int = i - 1;

			// While the previous element is greater than the current element,
			// move the previous element to the right and move the index to the left.
			while (j >= 0 && compare(input[j], current) > 0) {
				input[j + 1] = input[j];
				j--;
			}

			input[j + 1] = current; // Insert the current element into the array.
		}
	}
}

/**
 * A comparison function.
 * Returns a negative number if the first argument is less than the second,
 * a positive number if the first argument is greater than the second,
 * or zero if the two arguments are equal.
 */
typedef CompareFunction<T> = T -> T -> Int;