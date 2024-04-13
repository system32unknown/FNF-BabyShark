package debug;

import flixel.util.FlxStringUtil;
import utils.system.FPSUtil;

class FPSCounter extends openfl.text.TextField {
	public static var instance:FPSCounter;
	public var fontName:String = openfl.utils.Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor:Int = 0;

    public var fpsManager:FPSUtil;
    public var memory(get, never):Float;
	inline function get_memory():Float return utils.system.MemoryUtil.getGCMEM();
	var mempeak:Float = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();
		if (instance == null) instance = this;

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = mouseEnabled = false;
		text = "0 FPS";
		defaultTextFormat = new openfl.text.TextFormat(fontName, 16, -1);
		fpsManager = new FPSUtil();
	}

	var deltaTimeout:Float = .0;
    public var memCounterType:String = "";
	override function __enterFrame(dt:Float):Void {
		if (deltaTimeout > 1000) {
			deltaTimeout = .0;
			return;
		}

		fpsManager.update();
		if (memory > mempeak) mempeak = memory;

		updateText(dt);
		deltaTimeout += dt;
	}

	public dynamic function updateText(dt:Float):Void {
		if (ClientPrefs.data.rainbowFps) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		text = '${fpsManager.curFPS}FPS ${(ClientPrefs.data.fpsStats) ? '[${utils.MathUtil.truncateFloat((1 / fpsManager.curCount) * 1000)}ms]' : ''}\n';
		if (memCounterType == "MEM" || memCounterType == "MEM/PEAK")
			text += '${FlxStringUtil.formatBytes(memory)}' + (memCounterType == "MEM/PEAK" ? ' / ${FlxStringUtil.formatBytes(mempeak)}' : '');
	}
}
