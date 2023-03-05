package utils.system;

import utils.MathUtil;
import utils.ClientPrefs;
import flixel.FlxG;

class FPSUtil {
    var times:Array<Float>;
    var curTime:Float;
    public var currentFPS(default, null):Int;
    public function new() {
        times = [];
    }

    public function update(dt:Float) {
        curTime += dt;
        times.push(curTime);
        while (times[0] < curTime - 1000)
            times.shift();

        switch (ClientPrefs.getPref("FPSType")) {
            case "elapsed": currentFPS = Math.floor(MathUtil.fpsLerp(currentFPS, FlxG.elapsed == 0 ? 0 : (1 / FlxG.elapsed), .25));
            case "times":  Math.round(times.length / 2);
        }
    }
}