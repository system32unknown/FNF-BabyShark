package utils.system;

class FPSUtil {
    @:noCompletion var times:Array<Float> = [];
    public var currentFPS(default, null):Float;
	public var currentCount(default, null):Int;
    public function new() {}

    public function update() {
		var now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		currentCount = times.length;
		currentFPS = Math.min(FlxG.drawFramerate, currentCount);
    }

	public static function getFPSAdjust(type:String, fps:Float) {
		return switch (type.toLowerCase()) {
			case 'andromeda': FlxG.elapsed / (1 / 60) * fps;
			case 'psychold': Math.exp(-fps * 30);
			case 'kade': Math.exp(-fps * 70);
			case 'codename': Math.exp(-fps * 60 * FlxG.elapsed);
			case 'forever': fps * (60 / FlxG.drawFramerate);
			case 'yoshi': FlxMath.lerp(1.15, 1, FlxEase.cubeOut(fps % 1));
			case 'micdup': .09 / (fps / 60);
			default: 0;
		};
	}

	inline public static function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, getFPSAdjust('codename', ratio));
	}

	public function checkFPSLag()
		return currentFPS < FlxG.drawFramerate * .5;
}