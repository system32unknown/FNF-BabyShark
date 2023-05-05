package utils;

class MathUtil {
	public static function truncateFloat(number:Float, ?precision:Int = 3):Float {
        var num = number;
        num = num * Math.pow(10, precision);
        num = Math.round(num) / Math.pow(10, precision);
        return num;
    }

	public static function floorDecimal(value:Float, decimals:Int):Float {
		if(decimals < 1) return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals) tempMult *= 10;
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}
}