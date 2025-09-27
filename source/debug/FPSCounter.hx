package debug;

import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

import _external.memory.Memory;

/**
 * The FPS class provides an easy-to-use monitor to display
 * the current framerate of an OpenFL project
 */
class FPSCounter extends openfl.text.TextField {
	public var fontName:String = "_sans";

	public var checkLag:Bool = true;
	public var updateRate:Float = 60;
	public var memDisplay:String = "";
	public var memType:String = "";

	public var fpsManager:FPSUtil;

	/**
	 * The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	 */
	public var gcMEM(get, never):Float;
	@:noCompletion function get_gcMEM():Float {
		var mem:Float = openfl.system.System.totalMemoryNumber;
		if (mem > gcPeakMEM) gcPeakMEM = mem;
		return mem;
	}
	var gcPeakMEM:Float = 0;

	public var taskMEM(get, never):Float;
	@:noCompletion function get_taskMEM():Float {
		var mem:Float = Memory.getCurrentUsage();
		if (mem > taskPeakMEM) taskPeakMEM = mem;
		return mem;
	}
	var taskPeakMEM:Float = 0;

	@:noCompletion var lastText:String = null;

	public function new(x:Float = 0, y:Float = 0) {
		super();

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = mouseEnabled = false;
		text = "0FPS";
		defaultTextFormat = new openfl.text.TextFormat(fontName, 12, -1, JUSTIFY);
		antiAliasType = NORMAL;
		sharpness = 100;
		multiline = true;
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
		var newStr:String = '${fpsManager.curFPS}FPS';
		if (memDisplay != 'NONE') {
			if (memDisplay == 'GC' || memDisplay == 'BOTH') newStr += '\nGC MEM: ' + FlxStringUtil.formatBytes(gcMEM) + ' / ' + FlxStringUtil.formatBytes(gcPeakMEM);
			if (memDisplay == 'TASK' || memDisplay == 'BOTH') newStr += '\nTASK MEM: ' + FlxStringUtil.formatBytes(taskMEM) + ' / ' + FlxStringUtil.formatBytes(taskPeakMEM);
		}

		if (newStr != lastText) {
			text = newStr;
			lastText = newStr;
		}
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