package debug;

import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

/**
 *The FPS class provides an easy-to-use monitor to display
 *the current framerate of an OpenFL project
 */
class FPSCounter extends openfl.text.TextField {
	public var fontName:String = "_sans";

	public var checkLag:Bool = true;
	public var updateRate:Float = 60;
	public var memDisplayType:String = "";
	public var memType:String = "";

	public var fpsManager:FPSUtil;

	/**
	 * The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	 */
	public var memory(get, never):Float;
	@:noCompletion function get_memory():Float {
		var mem:Float = memType == 'GC' ? openfl.system.System.totalMemoryNumber : utils.system.MemoryUtil.appMemoryNumber;
		if (mem > mempeak && memDisplayType == "MEM/PEAK") mempeak = mem;
		return mem;
	}
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
		if (!checkLag) return;
		if (fpsManager.lagged()) textColor = FlxColor.RED;
		else textColor = FlxColor.WHITE;
	}

	var deltaTimeout:Float = .0;
	override function __enterFrame(deltaTime:Float):Void {
		if (!Settings.data.showFPS || !visible || FlxG.autoPause && !stage.nativeWindow.active) return;
		fpsManager.update(deltaTime);
		preUpdateText();

		deltaTimeout += deltaTime;
		if (deltaTimeout < 1000 / updateRate) return;

		updateText();
		deltaTimeout = 0.0;
	}

	// so people can override it in hscript
	public dynamic function updateText():Void {
		var fpsStr:String = '${fpsManager.curFPS}FPS';
		if (memDisplayType == "MEM" || memDisplayType == "MEM/PEAK") {
			fpsStr += '\n' + FlxStringUtil.formatBytes(memory);
			if (memDisplayType == "MEM/PEAK") fpsStr += ' / ' + FlxStringUtil.formatBytes(mempeak);
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