package debug;

import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

/**
	The FPS class provides an easy-to-use monitor to display
	the current framerate of an OpenFL project
**/
class FPSCounter extends openfl.text.TextField {
    public var fontName:String = Paths.font("Proggy.ttf");

	var timeColor:Float = 0;
	public var checkLag:Bool = true;
	public var updateRate:Float = 50;
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
		text = "0FPS";
		defaultTextFormat = new openfl.text.TextFormat(fontName, 16, -1, JUSTIFY);
		fpsManager = new FPSUtil();
	}

	public dynamic function preUpdateText():Void {
		if (ClientPrefs.data.rainbowFps) {
			timeColor = (timeColor % 360.) + (1. / (ClientPrefs.data.framerate / 120));
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else if (checkLag) {
			if (fpsManager.lagged()) textColor = FlxColor.RED;
			else textColor = FlxColor.WHITE;
		}
	}

	var deltaTimeout:Float = .0;
	override function __enterFrame(dt:Float) {
		fpsManager.update(dt);
		preUpdateText();
		if (memory > mempeak) mempeak = memory;

		deltaTimeout += dt;
		if (deltaTimeout < 1 / updateRate) return;
		updateText();
		deltaTimeout = .0;
	}
	public dynamic function updateText():Void {
		text = '${fpsManager.curFPS}FPS\n';
		if (utils.system.MemoryUtil.isGcOn)
			if (memType == "MEM" || memType == "MEM/PEAK") text += '${FlxStringUtil.formatBytes(memory)}' + (memType == "MEM/PEAK" ? '/${FlxStringUtil.formatBytes(mempeak)}' : '');
		else text += "GC OFF";
	}
}