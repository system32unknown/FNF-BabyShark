package utils.system;

class FPSUtil {
    @:noCompletion var times:Array<Float> = [];
	@:noCompletion var cacheCount:Int;
    public var currentFPS(default, null):Int;
	public var currentCount(default, null):Int;
    public function new() {}

    public function update() {
		var now:Float = haxe.Timer.stamp();
		times.push(now);
		while (times[0] < now - 1) times.shift();

		currentCount = times.length;
		currentFPS = Math.round(currentCount);

		if (currentCount == cacheCount) {
			cacheCount = currentCount;
			return;
		}
    }

	public static function getFPSAdjust(type:String, fps:Float) {
		return switch (type.toLowerCase()) {
			case 'andromeda': FlxG.elapsed / (1 / 60) * fps;
			case 'psychold': FlxMath.bound(1 - (fps * 30), 0, 1);
			case 'kade': FlxMath.bound(1 - (fps * 70), 0, 1);
			case 'codename': FlxMath.bound(fps * 60 * FlxG.elapsed, 0, 1);
			case 'forever': fps * (60 / FlxG.drawFramerate);
			case 'yoshi': FlxMath.lerp(1.15, 1, FlxEase.cubeOut(fps % 1));
			case 'micdup': .09 / (fps / 60);
			default: 0;
		};
	}

	inline public static function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, getFPSAdjust('codename', ratio));
	}

	public function checkFPSLag() {
		return currentFPS <= ClientPrefs.getPref('framerate') / 2;
	}
}