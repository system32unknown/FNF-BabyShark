package utils.system;

class FPSUtil {
    @:noCompletion var times:Array<Int>;
	@:noCompletion var sum:Int;
	@:noCompletion var sliceCnt:Int;

	/**
	 * The current frame rate, expressed using frames-per-second.
	 */
	public var curFPS(default, null):Float;

    /**
	 * The raw frame rate over a short period.
     */
	public var curRawFPS(default, null):Float;

    public function new() {
		curFPS = curRawFPS = 0;
		sum = sliceCnt = 0;
		times = [];
	}

    /**
     * Updates the FPS calculations based on the given delta time.
     */
    public function update(dt:Float):Void {
		sliceCnt = 0;
		var delta:Int = Math.round(dt);
		times.push(delta);
		sum += delta;

		while (sum > 1000) {
			sum -= times[sliceCnt];
			++sliceCnt;
		}
		if (sliceCnt > 0) times.splice(0, sliceCnt);
		
		curRawFPS = times.length > 0 ? 1000 / (sum / times.length) : 0.0;
		curFPS = Math.round(curRawFPS);
    }

    /**
     * Adjusts FPS calculations based on different engine types.
     * @param type The engine type (e.g., 'andromeda', 'psychold', etc.).
     * @param fps The current FPS value to adjust.
     * @return The adjusted FPS value based on the selected method.
     */
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

	/**
	 * Alternative linear interpolation function for each frame use, without worrying about framerate changes.
	 * @param a Begin value.
	 * @param b End value.
	 * @param ratio Ratio.
	 * @return Float Final value.
	 */
	inline public static function fpsLerp(a:Float, b:Float, ratio:Float):Float
		return FlxMath.lerp(b, a, getFPSAdjust('codename', ratio));

	public function lagged():Bool return curFPS < FlxG.drawFramerate * .5;
}