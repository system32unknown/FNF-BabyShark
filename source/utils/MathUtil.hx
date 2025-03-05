package utils;

class MathUtil {
	public static function floorDecimal(value:Float, decimals:Int):Float {
		if (decimals < 1) return Math.floor(value);
		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
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

    inline public static function interpolate(a:Float, b:Float, m:Float, e:Float = 1) {
		m = FlxMath.bound(m, 0, 1);
		return FlxMath.lerp(a, b, Math.pow(m, e));
	}

    public static function rotate(x:Float, y:Float, radians:Float, ?point:FlxPoint):FlxPoint {
		var s:Float = Math.sin(radians);
		var c:Float = Math.cos(radians);

		if (Math.abs(s) < .001) s = 0;
		if (Math.abs(c) < .001) c = 0;

		var p:FlxPoint = point ?? FlxPoint.weak();
		p.set((x * c) - (y * s), (x * s) + (y * c));
		return p;
	}

    inline public static function square(angle:Float):Float {
		var fAngle:Float = angle % (Math.PI * 2);
		return fAngle >= Math.PI ? -1. : 1.;
	}

	inline public static function triangle(angle:Float):Float {
		var fAngle:Float = angle % (Math.PI * 2.);
		if (fAngle < 0.0) fAngle += Math.PI * 2.;
		
		var result:Float = fAngle / Math.PI;
		if (result < .5) {
			return 2. * result;
		} else if (result < 1.5) {
			return -2. * result + 2.;
		} else return 2. * result - 4.;
	}
}