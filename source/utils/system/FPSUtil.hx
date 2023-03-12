package utils.system;

import utils.MathUtil;
import haxe.Timer;
import flixel.FlxG;

class FPSUtil {
    @:noCompletion var times:Array<Float> = [];
    public var currentFPS(default, null):Int;
    public function new() {}

    public function update() {
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

        switch (ClientPrefs.getPref("FPSType")) {
            case "elapsed": currentFPS = Math.floor(MathUtil.fpsLerp(currentFPS, FlxG.elapsed == 0 ? 0 : (1 / FlxG.elapsed), .25));
            case "times": currentFPS = times.length;
        }
    }
}