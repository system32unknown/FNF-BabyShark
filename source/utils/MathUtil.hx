package utils;

import flixel.math.FlxMath;
import flixel.FlxG;

class MathUtil {
	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

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

	inline public static function adjustFPS(from:Float, to:Float, ratio:Float):Float
		return FlxMath.lerp(from, to, ratioFPS(ratio));

	inline public static function ratioFPS(ratio:Float):Float
		return MathUtil.boundTo(ratio * 60 * FlxG.elapsed, 0, 1);
}