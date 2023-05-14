package ui;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import utils.system.MemoryUtil;
import utils.system.FPSUtil;

class Overlay extends TextField {
	public static var instance:Overlay;
	public var fontName:String = Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

	//FPS
    public var FPS:FPSUtil;
	public var advMode:Bool = false;

	//Memory
    var memory:Dynamic = 0;
    var mempeak:Dynamic = 0;

	public function new(x:Float = 0, y:Float = 0) {
		super();
		if (instance == null) instance = this;
		else throw "Cannot create another instance.";

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		multiline = wordWrap = false;
		text = "";
		defaultTextFormat = new TextFormat(fontName, 16, -1);
		FPS = new FPSUtil();
	}

	public function checkFPSLag(maxMB:Int = 3000) {
		if (memory > maxMB || FPS.currentFPS <= ClientPrefs.getPref('framerate') / 2)
			return true;
		return false;
	}

	//Yoinked from codename engine
	override function __enterFrame(dt:Int):Void {
		if (alpha <= .05) return;
		super.__enterFrame(dt);
		FPS.update();

		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		memory = MemoryUtil.getMEM();
		if (memory > mempeak) mempeak = memory;

		text = '${FPS.currentFPS} FPS ${ClientPrefs.getPref('MSFPSCounter') ? '[MS: $dt]' : ''}\n';
		if (ClientPrefs.getPref('showMEM'))
			text += '${MemoryUtil.getInterval(memory)} / ${MemoryUtil.getInterval(mempeak)}\n';

		visible = ClientPrefs.getPref('showFPS');
	}
}
