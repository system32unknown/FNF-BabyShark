package ui.framerate;

import openfl.text.TextFormat;
import openfl.text.TextField;

import haxe.Timer;
import utils.ClientPrefs;

class FPSCounter extends TextField {
    public var currentFPS(default, null):Int = 0;

	@:noCompletion var cacheCount:Int = 0;
	@:noCompletion var times:Array<Float> = [];

    public function new() {
        super();

        autoSize = LEFT;
        x = y = 0;
        text = "FPS: 0";
        multiline = wordWrap = false;
        defaultTextFormat = new TextFormat(Overlay.instance.fontName, 14, -1);
    }

    public override function __enterFrame(dt:Int) {
        if (alpha <= .05) return;
        super.__enterFrame(dt);

		var now:Float = Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.getPref('framerate')) currentFPS = ClientPrefs.getPref('framerate');

		if (currentCount != cacheCount) {
            text = 'FPS: ${Math.floor(currentFPS)} [$dt MS]';
		}
		cacheCount = currentCount;
    }
}