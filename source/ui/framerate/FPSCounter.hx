package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import haxe.Timer;
import utils.ClientPrefs;

class FPSCounter extends Sprite {
    public var fpsText:TextField;

    public var currentFPS(default, null):Int = 0;

	@:noCompletion var cacheCount:Int = 0;
	@:noCompletion var times:Array<Float> = [];

    public function new() {
        super();

        fpsText = new TextField();

        fpsText.autoSize = LEFT;
        fpsText.x = text.y = 0;
        fpsText.text = "FPS";
        fpsText.multiline = text.wordWrap = false;
        fpsText.defaultTextFormat = new TextFormat(Overlay.instance.fontName, 14, -1);
        addChild(fpsText);
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
            fpsText.text = '${Math.floor(currentFPS)}FPS [$dt MS]';
		}
		cacheCount = currentCount;
    }
}