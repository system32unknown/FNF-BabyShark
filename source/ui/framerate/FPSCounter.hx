package ui.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

import haxe.Timer;
import utils.ClientPrefs;

class FPSCounter extends Sprite {
    public var fpsNum:TextField;
    public var fpsText:TextField;

    public var currentFPS(default, null):Int = 0;

	@:noCompletion var cacheCount:Int = 0;
	@:noCompletion var times:Array<Float> = [];

    public function new() {
        super();
        fpsNum = new TextField();
        fpsText = new TextField();

        for (text in [fpsNum, fpsText]) {
            text.autoSize = LEFT;
            text.x = text.y = 0;
            text.text = "FPS";
            text.multiline = text.wordWrap = false;
            text.defaultTextFormat = new TextFormat(Overlay.instance.fontName, text == fpsNum ? 18 : 14, -1);
            addChild(text);
        }
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
			fpsNum.text = Std.string(Math.floor(currentFPS));
            fpsText.text = 'FPS [$dt MS]';

            fpsText.x = fpsNum.x + fpsNum.width;
            fpsText.y = (fpsNum.y + fpsNum.height) - fpsText.height;
		}
		cacheCount = currentCount;
    }
}