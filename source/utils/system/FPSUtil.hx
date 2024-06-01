package utils.system;

class FPSUtil {
    @:noCompletion var times:Array<Float>;
	@:noCompletion var curCount(default, null):Int;

    public var totalFPS(default, null):Float;
	public var curFPS(default, null):Float;
	public var fpsInterval:Float;

    public function new(fpsInterval:Float = 1000) {
		totalFPS = curFPS = curCount = 0;
		this.fpsInterval = fpsInterval;
		times = [];
	}

    public function update() {
		final now:Float = haxe.Timer.stamp() * fpsInterval;
		times.push(now);
		while (times[0] < now - fpsInterval) times.shift();

		curCount = times.length;
		curFPS = Math.min(FlxG.drawFramerate, curCount);
		totalFPS = Math.round(curFPS + curCount / 8);
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

	inline public static function fpsLerp(a:Float, b:Float, ratio:Float):Float
		return FlxMath.lerp(b, a, getFPSAdjust('codename', ratio));
	public function checkFPSLag():Bool return curFPS < FlxG.drawFramerate * .5;
}