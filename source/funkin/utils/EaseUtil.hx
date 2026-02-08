package funkin.utils;

@:nullSafety
class EaseUtil {
	public static function easeInOutCirc(x:Float):Float {
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
		return Math.isNaN(result) ? 1.0 : result;
	}

	public static function easeInOutBack(x:Float, c:Float = 1.70158):Float {
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		var result:Float = (x < 0.5) ? (2 * x * x * ((c + 1) * 2 * x - c)) / 2 : (1 - 2 * (1 - x) * (1 - x) * ((c + 1) * 2 * (1 - x) - c)) / 2;
		return Math.isNaN(result) ? 1.0 : result;
	}

	public static function easeInBack(x:Float, c:Float = 1.70158):Float {
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		return (1 + c) * x * x * x - c * x * x;
	}

	public static function easeOutBack(x:Float, c:Float = 1.70158):Float {
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
	}

	/**
	 * Returns an ease function that eases via steps.
	 * Useful for "retro" style fades (week 6!)
	 * @param steps how many steps to ease over
	 * @return Float->Float
	 */
	public static inline function stepped(steps:Int):Float->Float {
		return (t:Float) -> {
			return Math.floor(t * steps) / steps;
		}
	}

	/**
	 * Combines multiple easing functions into one composite function.
	 * The resulting ease will blend the given array of easing functions sequentially.
	 * @param eases An array of easing functions to combine.
	 * @return A combined Float->Float, or null if no eases were provided.
	 */
	public static function easeCombine(eases:Array<Float->Float>):Null<Float->Float> {
		if (eases.length < 1) return null;

		return (v:Float) -> {
			if (v * eases.length >= eases.length) return v;
			var index:Int = Math.floor(v * eases.length);
			v = (index / eases.length) + (eases[index]((v - (index / eases.length)) * eases.length) / eases.length);
			return v;
		}
	}
}