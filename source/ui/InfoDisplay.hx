package ui;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import utils.ClientPrefs;
import utils.MathUtil;

/**
	The Advanced FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class InfoDisplay extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int = 0;

	public var fullVisible:Bool = true;
	var peak:UInt = 0;

	@:noCompletion var cacheCount:Int = 0;
	@:noCompletion var times:Array<Float> = [];

	static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB'];

	public function new(x:Float = 4, y:Float = 2)
	{
		super();

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = false;
		
		defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont("assets/fonts/vcr.ttf").fontName, 14, 0xFFFFFF);
		text = "";

		addEventListener(Event.ENTER_FRAME, update);
	}

	public static function getInterval(num:UInt):String {
		var size:Float = num;
		var data = 0;
		while (size > 1024 && data < intervalArray.length - 1) {
			data++;
			size = size / 1024;
		}

		size = MathUtil.truncateFloat(size, 10);
		return size + " " + intervalArray[data] + " \n";
	}

	function update(_:Event):Void {
		var now:Float = Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.getPref('framerate')) currentFPS = ClientPrefs.getPref('framerate');

		if (currentCount != cacheCount) {
			text = '';
			text += (ClientPrefs.getPref('showFPS') ? "FPS: " + currentFPS + "\n" : "");

			var memory:Int = System.totalMemory;
			if (memory > peak) peak = memory;

			if (ClientPrefs.getPref('showMEM')) {
				text += "MEM: " + getInterval(memory);
				text += "MEM Peak: " + getInterval(peak);
			}

			if ((text != null || text != '') && Main.infoVar != null)
				Main.infoVar.visible = fullVisible;
		}

		cacheCount = currentCount;
	}
}
