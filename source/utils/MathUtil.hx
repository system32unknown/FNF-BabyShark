package utils;

class MathUtil {
	inline public static function quantize(f:Float, snap:Float) {
		return Math.fround(f * snap) / snap;
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

	inline public static function getMinAndMax(v1:Float, v2:Float):Array<Float> {
		return [Math.min(v1, v2), Math.max(v1, v2)];
	}

    public static function fastInverseSquareRoot(x: Float):Float {
        var i:Int = cast(x);
        var y:Float = x;
        var x2:Float = x * .5;

        i = 0x5f3759df - (i >> 1); // what the fuck?
        y = cast(i);

        y = y * (1.5 - (x2 * y * y));
        return y;
    }
}