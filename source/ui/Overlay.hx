package ui;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import flixel.util.FlxColor;
import flixel.FlxG;
import utils.MathUtil;
import utils.ClientPrefs;
import utils.MemoryUtil;

class Overlay extends TextField {
	public static var instance:Overlay;
	public var fontName:String = Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

	//FPS
    public var currentFPS(default, null):Int = 0;

	//Memory
    var memory:Int = 0;
    var mempeak:Int = 0;

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
	}

	//Yoinked from codename engine
	override function __enterFrame(dt:Int):Void {
		if (alpha <= .05) return;
		super.__enterFrame(dt);

		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		currentFPS = Math.floor(MathUtil.fpsLerp(currentFPS, FlxG.elapsed == 0 ? 0 : (1 / FlxG.elapsed), .25));

		memory = MemoryUtil.getMemUsage(ClientPrefs.getPref('MEMType'));
		if (memory > mempeak) mempeak = memory;

		text = '$currentFPS FPS ${ClientPrefs.getPref('MSFPSCounter') ? '[MS: $dt]' : ''}\n';
		if (ClientPrefs.getPref('showMEM'))
			text += '${MemoryUtil.getInterval(memory)} / ${MemoryUtil.getInterval(mempeak)}\n';

		visible = ClientPrefs.getPref('showFPS');
	}
}
