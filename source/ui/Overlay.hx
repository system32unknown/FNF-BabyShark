package ui;

import cpp.NativeGc;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if !cpp
import openfl.system.System;
#end
import flixel.util.FlxColor;
import utils.ClientPrefs;

/**
	The Advanced FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class Overlay extends TextField
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

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

	public function new(x:Float = 4, y:Float = 2)
	{
		super();

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = false;
		
		defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont("assets/fonts/vcr.ttf").fontName, 14, 0xFFFFFF);
		text = "";
	}

	public static function getInterval(num:UInt):String {
		var size:Float = num;
		var data = 0;
		while (size > 1024 && data < intervalArray.length - 1) {
			data++;
			size = size / 1024;
		}

		size = Math.round(size * 100) / 100;
		return size + " " + intervalArray[data] + " \n";
	}

	override function __enterFrame(dt:Float):Void {
		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		}

		var now:Float = Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.getPref('framerate')) currentFPS = ClientPrefs.getPref('framerate');

		if (currentCount != cacheCount) {
			text = '';
			text += (ClientPrefs.getPref('showFPS') ? 'FPS: $currentFPS${ClientPrefs.getPref('MSFPSCounter') ? ' [MS: $dt]' : ''}\n' : "");

			var memory:Int = #if cpp Std.int(NativeGc.memInfo(0)) #else System.totalMemory #end;
			if (memory > peak) peak = memory;

			if (ClientPrefs.getPref('showMEM')) {
				text += "MEM: " + getInterval(memory);
				text += "MEM Peak: " + getInterval(peak);
			}

			if ((text != null || text != '') && Main.overlayVar != null)
				Main.overlayVar.visible = fullVisible;
		}

		cacheCount = currentCount;
	}
}
