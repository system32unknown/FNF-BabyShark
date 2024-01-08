package utils;

class MathUtil {
	inline public static function quantize(f:Float, snap:Float) {
		final m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	public static function truncateFloat(number:Float, ?precision:Int = 3):Float {
        var num = number;
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

	public static function getMinAndMax(value1:Float, value2:Float):Array<Float> {
		var minAndMaxs = new Array<Float>();

		var min = Math.min(value1, value2);
		var max = Math.max(value1, value2);

		minAndMaxs.push(min);
		minAndMaxs.push(max);

		return minAndMaxs;
	}
}