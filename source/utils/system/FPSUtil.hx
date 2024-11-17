package utils.system;

class FPSUtil {
    @:noCompletion var times:Array<Int>;
	@:noCompletion var sum:Int;
	@:noCompletion var sliceCnt:Int;

	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var curFPS(default, null):Float;
    public function new() {
		curFPS = sum = sliceCnt = 0;
		times = [];
	}

    public function update(dt:Float):Void {
		var delta:Int = Math.round(dt);
		times.push(delta);
		sum += delta;

		while (sum > 1000) {
			sum -= times[sliceCnt];
			++sliceCnt;
		}
		if (sliceCnt > 0) times.splice(0, sliceCnt);

		curFPS = times.length > 0 ? 1000 / (sum / times.length) : 0.0;
    }

	public static function getFPSAdjust(type:String, fps:Float):Float {
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
	public function lagged():Bool return curFPS < FlxG.drawFramerate * .5;
}