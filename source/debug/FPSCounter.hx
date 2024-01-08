package debug;

import flixel.util.FlxStringUtil;
import utils.system.FPSUtil;

class FPSCounter extends openfl.text.TextField {
	public static var instance:FPSCounter;
	public var fontName:String = openfl.utils.Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

    public var fpsManager:FPSUtil;
    public var memory(get, never):Float;
	var mempeak:Float = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();
		if (instance == null) instance = this;
		else throw "Cannot create another instance.";

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = mouseEnabled = false;
		text = "0 FPS";
		defaultTextFormat = new openfl.text.TextFormat(fontName, 16, -1);
		fpsManager = new FPSUtil();
	}

	var deltaTimeout:Float = .0;
    var memType:String = "";
	override function __enterFrame(dt:Float):Void {
		if (deltaTimeout > 1000) {
			deltaTimeout = .0;
			return;
		}
        memType = ClientPrefs.getPref('showMEM');
		visible = ClientPrefs.getPref('showFPS');

		fpsManager.update();
		if (memory > mempeak) mempeak = memory;

		updateText(dt);
		deltaTimeout += dt;
	}

	public dynamic function updateText(dt:Float):Void {
		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		text = '${fpsManager.currentFPS} FPS ${(ClientPrefs.getPref('FPSStats')) ? '[${utils.MathUtil.truncateFloat((1 / fpsManager.currentCount) * 1000)}ms]' : ''}\n';
		if (memType == "MEM" || memType == "MEM/PEAK")
			text += '${FlxStringUtil.formatBytes(memory)}' + (memType == "MEM/PEAK" ? ' / ${FlxStringUtil.formatBytes(mempeak)}' : '');
	}

	inline function get_memory():Float
		return utils.system.MemoryUtil.getGCMEM();
}
