package ui;

import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import flixel.util.FlxColor;
import utils.ClientPrefs;
import utils.MemoryUtil;

class Overlay extends TextField {
	public static var instance:Overlay;
	public var fontName:String = Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

	//FPS
    public var currentFPS(default, null):Int = 0;
	@:noCompletion var cacheCount:Int = 0;
	@:noCompletion var times:Array<Float> = [];

	//Memory
    var memory:UInt = 0;
    var mempeak:UInt = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();
		if (instance == null) instance = this;
		else throw "Cannot create another instance.";

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		multiline = wordWrap = false;
		text = "";
		defaultTextFormat = new TextFormat(fontName, 16, -1);
	}

	override function __enterFrame(dt:Int):Void {
		super.__enterFrame(dt);
		if (alpha <= .05) return;

		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		var now:Float = Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.getPref('framerate'))
			currentFPS = ClientPrefs.getPref('framerate');

		memory = MemoryUtil.getMemUsage(ClientPrefs.getPref('MEMType'));
		if (memory > mempeak)mempeak = memory;

		if (currentCount != cacheCount) {
			text = '';
			text += 'FPS: $currentFPS ${ClientPrefs.getPref('MSFPSCounter') ? '[MS: $dt]' : ''}\n';
			if (ClientPrefs.getPref('showMEM'))
				text += 'MEM: ${MemoryUtil.getInterval(memory)}/${MemoryUtil.getInterval(mempeak)}\n';
		}

		cacheCount = currentCount;
		visible = ClientPrefs.getPref('showFPS');
	}
}
