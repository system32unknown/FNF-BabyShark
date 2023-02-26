package utils;

import flixel.FlxG;
import flixel.math.FlxMath;

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

	inline public static function adjustFPS(adjust:Float):Float {
		return FlxG.elapsed / (1 / 60) * adjust;
	}

	inline public static function ratioFPS(ratio:Float):Float {
		return boundTo(ratio * 60 * FlxG.elapsed, 0, 1);
	}

	inline public static function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, ratioFPS(ratio));
	}
}