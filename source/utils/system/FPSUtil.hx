package utils.system;

class FPSUtil {
	@:noCompletion var times:Array<Int>;
	@:noCompletion var sum:Int;
	@:noCompletion var sliceCnt:Int;

	/**
	 * The current frame rate, expressed using frames-per-second.
	 */
	public var curFPS(default, null):Int;

	/**
	 * The total accumulated frame rate, potentially used for averaging over time.
	 */
	public var totalFPS(default, null):Int;

	/**
	 * The raw frame rate over a short period.
	 */
	public var avgFPS(default, null):Float;

	public var clampFPS:Bool = true;

	/**
	 * Internal counter used for frame rate calculations or caching.
	 */
	var cacheCount:Int;

	public function new() {
		curFPS = 0;
		avgFPS = 0;
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

		var curCount:Int = times.length;
		totalFPS = Math.round(curFPS + curCount / 8);
		if (curCount != cacheCount) {
			avgFPS = curCount > 0 ? 1000 / (sum / curCount) : 0.0;
			var roundAvgFPS = Math.round(avgFPS);
			curFPS = clampFPS ? (roundAvgFPS < FlxG.drawFramerate ? roundAvgFPS : FlxG.drawFramerate) : roundAvgFPS;
		}
		cacheCount = curCount;
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

	/**
	 * Adjusts the value based on the reference FPS.
	 */
	public static inline function fpsAdjust(value:Float, ?referenceFps:Float = 60):Float {
		return value * (referenceFps * FlxG.elapsed);
	}

	/**
	 * Lerp function that can be run in update and is consistent independent of the game's framerate.
	 * 
	 * @param	a				Source value.
	 * @param	b				Target value.
	 * @param	ratio			The ratio at which the values are interpolated.
	 * @param	referenceFps	An optional parameter that makes the lerp act as if it was running at that framerate.
	 * @param	snap			An optional parameter that determines whether to snap `a` to `b` if their difference is within `snapTolerance`.
	 * @param	snapTolerance	An optional parameter that adjusts the difference needed to snap `a` to `b`.
	 */
	public static inline function fpsAdjustedLerp(a:Float, b:Float, ratio:Float, ?referenceFps:Float = 60, ?snap:Bool = false, ?snapTolerance:Float = 0.001):Float {
		var v:Float = dampen(a, b, Math.pow(1 - ratio, referenceFps));
		return (snap && Util.inRange(v, b, snapTolerance)) ? b : v;
	}

	/**
	 * The dampening fuction used in `fpsAdjustedLerp`.
	 * 
	 * @param	a				Source value.
	 * @param	b				Target value.
	 * @param	smoothing		The proportion of `a` left after 1 second.
	 */
	public static inline function dampen(a:Float, b:Float, smoothing:Float):Float {
		return FlxMath.lerp(a, b, 1 - Math.pow(smoothing, FlxG.elapsed));
	}

	public function lagged():Bool {
		return curFPS < FlxG.drawFramerate * .5;
	}
}