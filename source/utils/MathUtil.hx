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

    public static function fastInverseSquareRoot(x: Float): Float {
        var i:Int = cast(x);
        var y:Float = x;

        // The magic number 0x5f3759df helps in the approximation
        // Adjust the iteration count for better accuracy
        var threehalfs:Float = 1.5;
        var half:Float = 0.5;
        var iterations:Int = 2;

        i = 0x5f3759df - (i >> 1);
        y = cast(i);

        // Newton-Raphson iteration
        for (_ in 0...iterations) {
            y *= (threehalfs - (half * x * y * y));
        }

        return y;
    }
}