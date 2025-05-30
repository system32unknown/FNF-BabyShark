package utils;

class MathUtil {
	/**
	 * Rounds a floating-point number down to a specified number of decimal places.
	 * @param value The number to round down.
	 * @param decimals The number of decimal places.
	 * @return The rounded down number.
	 */
	public static function floorDecimal(value:Float, precision:Float = 2):Float {
		value *= (precision = Math.pow(10, precision));
		return Math.floor(value) / precision;
	}

	/**
	 * Returns an array containing the minimum and maximum of two given values.
	 * @param v1 The first value.
	 * @param v2 The second value.
	 * @return An array where the first element is the minimum and the second is the maximum.
	 */
	inline public static function getMinAndMax(v1:Float, v2:Float):Array<Float> {
		return [Math.min(v1, v2), Math.max(v1, v2)];
	}

	/**
	 * Perform a framerate-independent linear interpolation between the base value and the target.
	 * @param current The current value.
	 * @param target The target value.
	 * @param elapsed The time elapsed since the last frame.
	 * @param duration The total duration of the interpolation. Nominal duration until remaining distance is less than `precision`.
	 * @param precision The target precision of the interpolation. Defaults to 1% of distance remaining.
	 * @see https://x.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return A value between the current value and the target value.
	 */
	public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float {
		if (current == target) return target;
		var result:Float = FlxMath.lerp(current, target, 1 - Math.pow(precision, elapsed / duration));

		// TODO: Is there a better way to ensure a lerp which actually reaches the target?
		// Research a framerate-independent PID lerp.
		if (Math.abs(result - target) < (precision * target)) result = target;
		return result;
	}

	/**
	 * Linearly interpolates between two values with an optional exponent for easing.
	 * @param a The start value.
	 * @param b The end value.
	 * @param m The interpolation factor (0 to 1).
	 * @param e The exponent to apply for easing. Default is 1 (linear interpolation).
	 * @return The interpolated value with applied easing.
	 */
	inline public static function interpolate(a:Float, b:Float, m:Float, e:Float = 1):Float {
		m = FlxMath.bound(m, 0, 1);
		return FlxMath.lerp(a, b, Math.pow(m, e));
	}

	/**
	 * Calculates the mean (average) of a list of float values.
	 * Zero values are skipped in the summation, but still included in the count,
	 * which may result in an inaccurate average if many zeros are present.
	 *
	 * @param values An array of Float values.
	 * @return The arithmetic mean of the values, or 0.0 if the array is empty.
	 */
	public static function mean(values:Array<Float>):Float {
		if (values.length == 0) return 0.0;

		final amount:Int = values.length;
		var result:Float = 0.0;

		var value:Float = 0;
		for (i in 0...amount) {
			value = values[i];
			if (value == 0) continue;
			result += value;
		}

		return result / amount;
	}

	public static function invSqrt(x:Float):Float {
		var xt:Int = Std.int(x);
		var half:Float = x * .5;
		var i:Int = xt;
		i = 0x5f3759df - (i >> 1);
		var xt:Float = cast(i);
		return xt * (1.5 - (half * xt * xt));
	}
}
