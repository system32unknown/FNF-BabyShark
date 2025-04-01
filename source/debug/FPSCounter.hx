package debug;

import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

/**
	The FPS class provides an easy-to-use monitor to display
	the current framerate of an OpenFL project
**/
class FPSCounter extends openfl.text.TextField {
	public var fontName:String = "_sans";

	var timeColor:Float = 0;
	public var checkLag:Bool = true;
	public var updateRate:Float = 60;
	public var memType:String = "";

	public var fpsManager:FPSUtil;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memory(get, never):Float;
	inline function get_memory():Float return openfl.system.System.totalMemoryNumber;
	var mempeak:Float = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = mouseEnabled = false;
		text = "FPS: 0";
		defaultTextFormat = new openfl.text.TextFormat(fontName, 12, -1, JUSTIFY);
		fpsManager = new FPSUtil();
	}

	public dynamic function preUpdateText():Void {
		if (Settings.data.rainbowFps) {
			timeColor = (timeColor % 360.) + (1. / (Settings.data.framerate / 120));
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else if (checkLag) {
			if (fpsManager.lagged()) textColor = FlxColor.RED;
			else textColor = FlxColor.WHITE;
		}
	}

	var deltaTimeout:Float = .0;
	override function __enterFrame(deltaTime:Float):Void {
		if (!Settings.data.showFPS || !visible || FlxG.autoPause && !stage.nativeWindow.active) return;
		fpsManager.update(deltaTime);
		preUpdateText();
		if (memory > mempeak && memType == "MEM/PEAK") mempeak = memory;

		deltaTimeout += deltaTime;
		if (deltaTimeout < 1000 / updateRate) return;

		updateText();
		deltaTimeout = 0.0;
	}

	// so people can override it in hscript
	public var fpsStr:String = "";
	public dynamic function updateText():Void {
		fpsStr = 'FPS: ${fpsManager.curFPS}\n';
		if (memType == "MEM" || memType == "MEM/PEAK") {
			fpsStr += 'MEM: ' + FlxStringUtil.formatBytes(memory);
			if (memType == "MEM/PEAK") fpsStr += ' / ' + FlxStringUtil.formatBytes(mempeak);
		}
		text = fpsStr;
	}

	public inline function positionFPS(X:Float, Y:Float, isWide:Bool = false, ?scale:Float = 1) {
		scaleX = scaleY = (scale < 1 ? scale : 1);
		if (isWide) {
			x = X;
			y = Y;
		} else {
			x = FlxG.game.x + X;
			y = FlxG.game.y + Y;
		}
	}
}