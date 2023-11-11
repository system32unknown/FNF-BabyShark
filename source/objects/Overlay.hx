package objects;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import utils.system.MemoryUtil;
import utils.system.FPSUtil;
import utils.MathUtil;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Overlay extends TextField {
	public static var instance:Overlay;
	public var fontName:String = Assets.getFont("assets/fonts/Proggy.ttf").fontName;

 	@:noCompletion @:noPrivateAccess var timeColor = 0;

    public var FPS:FPSUtil;
    public var memory:Dynamic = 0;

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
		FPS = new FPSUtil();
	}

	var deltaTimeout:Float = .0;
	@:noCompletion override function __enterFrame(dt:Float):Void {
		super.__enterFrame(Std.int(dt));
		if (deltaTimeout > 1000) {
			deltaTimeout = .0;
			return;
		}
		FPS.update();

		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else textColor = FlxColor.WHITE;

		memory = MemoryUtil.getGCMEM();

		text = '${FPS.currentFPS} FPS ${(ClientPrefs.getPref('FPSStats')) ? '[${MathUtil.truncateFloat((1 / FPS.currentCount) * 1000)}ms, DT: ${Math.round(dt)}]' : ''}\n';
		if (ClientPrefs.getPref('showMEM'))
			text += '${MemoryUtil.getInterval(memory)}';
		visible = ClientPrefs.getPref('showFPS');

		deltaTimeout += dt;
	}
}
