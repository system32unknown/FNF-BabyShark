package utils.system;

import haxe.Timer;

class FPSUtil {
    @:noCompletion var times:Array<Float> = [];
    public var currentFPS(default, null):Int;
    public function new() {}

    public function update() {
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

        currentFPS = times.length;
    }

	inline public static function adjustFPS(adjust:Float):Float {
		return FlxG.elapsed / (1 / 60) * adjust;
	}

	inline public static function ratioFPS(ratio:Float):Float {
		return MathUtil.boundTo(ratio * 60 * FlxG.elapsed, 0, 1);
	}

	inline public static function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, ratioFPS(ratio));
	}
}