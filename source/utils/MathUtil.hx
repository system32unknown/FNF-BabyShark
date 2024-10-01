package utils;

class MathUtil {
	public static function truncateFloat(number:Float, ?precision:Int = 3):Float {
        var num:Float = number;
        num *= Math.pow(10, precision);
        num = Math.round(num) / Math.pow(10, precision);
        return num;
    }

	public static function floorDecimal(value:Float, decimals:Int):Float {
		if (decimals < 1) return Math.floor(value);

		var tempMult:Float = 1;
		for (_ in 0...decimals) tempMult *= 10;
		return Math.floor(value * tempMult) / tempMult;
	}

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
}