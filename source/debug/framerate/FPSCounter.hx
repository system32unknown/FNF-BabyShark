package debug.framerate;

import openfl.text.TextField;
import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

class FPSCounter extends openfl.display.Sprite {
	public var fpsTxt:TextField;
	var timeColor:Int = 0;
	public var checkLag:Bool = true;
	public var memType:String = "";

    public var fpsManager:FPSUtil;
    public var memory(get, never):Float;
	inline function get_memory():Float {
		return utils.system.MemoryUtil.getMEM();
	}
	var mempeak:Float = 0;

	public function new() {
		super();

		fpsTxt = new TextField();
		fpsTxt.autoSize = LEFT;
		fpsTxt.x = 0;
		fpsTxt.y = 0;
		fpsTxt.text = "0FPS";
		fpsTxt.selectable = fpsTxt.mouseEnabled = false;
		fpsTxt.defaultTextFormat = new openfl.text.TextFormat(Framerate.fontName, 16, -1);
		addChild(fpsTxt);
		
		fpsManager = new FPSUtil();
	}

	public dynamic function updateText():Void {
		fpsTxt.text = '${fpsManager.curFPS}FPS [${Std.int((1 / fpsManager.curFPS) * 1000)}ms]\n';
		if (memType == "MEM" || memType == "MEM/PEAK")
			fpsTxt.text += '${FlxStringUtil.formatBytes(memory)}' + (memType == "MEM/PEAK" ? ' / ${FlxStringUtil.formatBytes(mempeak)}' : '');
	}

	var deltaTimeout:Float = .0;
	public override function __enterFrame(dt:Float) {
		if (alpha <= .05) return;
		if (deltaTimeout > 1000) {
			deltaTimeout = .0;
			return;
		}

		fpsManager.update();
		if (memory > mempeak) mempeak = memory;

		if (ClientPrefs.data.rainbowFps) {
			timeColor = (timeColor % 360) + 1;
			fpsTxt.textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else if (checkLag) {
			if (fpsManager.checkFPSLag()) fpsTxt.textColor = FlxColor.RED;
			else fpsTxt.textColor = FlxColor.WHITE;
		}

		updateText();
		deltaTimeout += dt;
		
		super.__enterFrame(Std.int(dt));
	}
}