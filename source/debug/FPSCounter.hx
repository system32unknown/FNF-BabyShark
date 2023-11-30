package debug;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import utils.system.MemoryUtil;
import utils.system.FPSUtil;
import utils.MathUtil;

class FPSCounter extends TextField {
	public static var instance:FPSCounter;
	public var fontName:String = Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

    public var fpsManager:FPSUtil;
    public var memory(get, never):Dynamic;
	var mempeak:Dynamic = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();
		if (instance == null) instance = this;
		else throw "Cannot create another instance.";

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		multiline = wordWrap = false;
		selectable = mouseEnabled = false;
		text = "";
		defaultTextFormat = new TextFormat(fontName, 16, -1);
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

		updateText(dt);
		deltaTimeout += dt;
	}

	public dynamic function updateText(dt:Float):Void {
		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		text = '${fpsManager.currentFPS} FPS ${(ClientPrefs.getPref('FPSStats')) ? '[${MathUtil.truncateFloat((1 / fpsManager.currentCount) * 1000)}ms]' : ''}\n';
		if (memType == "MEM" || memType == "MEM/PEAK")
			text += '${MemoryUtil.getInterval(memory)}' + (memType == "MEM/PEAK" ? ' / ${MemoryUtil.getInterval(mempeak)}' : '');
	}

	inline function get_memory():Dynamic {
		var mem:Float = MemoryUtil.getGCMEM();
		if (mem > mempeak) mempeak = mem;
		return mem;
	}
}
