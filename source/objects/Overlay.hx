package objects;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import utils.system.MemoryUtil;
import utils.system.FPSUtil;
import utils.MathUtil;

class Overlay extends TextField {
	public static var instance:Overlay;
	public var fontName:String = Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

    public var fpsManager:FPSUtil;
    public var memory(get, never):Dynamic;

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
	override function __enterFrame(dt:Float):Void {
		if (deltaTimeout > 1000) {
			deltaTimeout = .0;
			return;
		}
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

		text = '${fpsManager.currentFPS} FPS ${(ClientPrefs.getPref('FPSStats')) ? '[${MathUtil.truncateFloat((1 / fpsManager.currentCount) * 1000)}ms, DT: ${Math.round(dt)}]' : ''}\n';
		if (ClientPrefs.getPref('showMEM'))
			text += '${MemoryUtil.getInterval(memory)}';
	}

	inline function get_memory():Dynamic
		return MemoryUtil.getGCMEM();
}
