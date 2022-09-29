package openfl.display;

import openfl.text.TextField;
import openfl.text.TextFormat;
#if openfl
import openfl.system.System;
#end
import flixel.math.FlxMath;

import utils.ClientPrefs;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	private var memoryMegas:Float = 0;
	private var peakMegas:Float = 0;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		
		defaultTextFormat = new TextFormat("VCR OSD Mono", 14, color);
		autoSize = LEFT;
		multiline = true;

		cacheCount = 0;
		currentTime = 0;
		times = [];
	}

	// Event Handlers
	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000) {
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.getPref('framerate')) currentFPS = ClientPrefs.getPref('framerate');

		if (currentCount != cacheCount) {
			text = '';
			text += (ClientPrefs.getPref('showFPS') ? "FPS: " + currentFPS + "\n" : "");

			#if openfl
			memoryMegas = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 1));
			if (memoryMegas > peakMegas) peakMegas = memoryMegas;
			#end

			if (ClientPrefs.getPref('showMEM')) {
				text += "MEM: " + memoryMegas + " MB\n";
				text += "MEM Peak: " + memoryMegas + " MB\n";
			}

			if (text != null || text != '') {
				if (Main.fpsVar != null)
					Main.fpsVar.visible = true;
			}

			textColor = 0xFFFFFFFF;
			if (memoryMegas > 3000 || currentFPS <= ClientPrefs.getPref('framerate') / 2) {
				textColor = 0xFFFF0000;
			}
		}

		cacheCount = currentCount;
	}
}
