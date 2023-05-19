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

	public static function getFPSAdjust(type:String = 'PSYCH', fps:Float) {
		return switch (type.toLowerCase()) {
			case 'andromeda': FlxG.elapsed / (1 / 60) * fps;
			case 'psychold': FlxMath.bound(1 - (fps * 30), 0, 1);
			case 'codename': FlxMath.bound(fps * 60 * FlxG.elapsed, 0, 1);
			case 'forever': fps * (60 / FlxG.drawFramerate);
			default: 0;
		};
	}

	inline public static function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, getFPSAdjust('codename', ratio));
	}
}