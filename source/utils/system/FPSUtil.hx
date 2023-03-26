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
}