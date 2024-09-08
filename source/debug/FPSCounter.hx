package debug;

import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

/**
	The FPS class provides an easy-to-use monitor to display
	the current framerate of an OpenFL project
**/
class FPSCounter extends openfl.text.TextField {
    public var fontName:String = openfl.utils.Assets.getFont("assets/fonts/Proggy.ttf").fontName;

	var timeColor:Int = 0;
	public var checkLag:Bool = true;
	public var memType:String = "";

    public var fpsManager:FPSUtil;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
    public var memory(get, never):Float;
	inline function get_memory():Float {
		return utils.system.MemoryUtil.getMEM();
	}
	var mempeak:Float = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = mouseEnabled = false;
		text = "0 FPS";
		defaultTextFormat = new openfl.text.TextFormat(fontName, 16, -1);
		fpsManager = new FPSUtil();
	}

	public dynamic function updateText():Void {
		text = '${fpsManager.curFPS}FPS [${Std.int((1 / fpsManager.curFPS) * 1000)}ms]\n';
		if (memType == "MEM" || memType == "MEM/PEAK") text += '${FlxStringUtil.formatBytes(memory)}' + (memType == "MEM/PEAK" ? ' / ${FlxStringUtil.formatBytes(mempeak)}' : '');
	}
	public dynamic function preUpdateText():Void {
		if (ClientPrefs.data.rainbowFps) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else if (checkLag) {
			if (fpsManager.lagged()) textColor = FlxColor.RED;
			else textColor = FlxColor.WHITE;
		}
	}

	var deltaTimeout:Float = .0;
	override function __enterFrame(dt:Float) {
		fpsManager.update();
		preUpdateText();
		if (memory > mempeak) mempeak = memory;

		if (deltaTimeout < 1000) {
			deltaTimeout += dt;
			return;
		}
		updateText();
		deltaTimeout = .0;
	}
}