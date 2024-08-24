package debug;

import utils.system.FPSUtil;
import flixel.util.FlxStringUtil;

class FPSCounter extends openfl.text.TextField {
    public var fontName:String = openfl.utils.Assets.getFont("assets/fonts/Proggy.ttf").fontName;

	var timeColor:Int = 0;
	public var checkLag:Bool = true;
	public var memType:String = "";

    public var fpsManager:FPSUtil;
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
		if (memType == "MEM" || memType == "MEM/PEAK")
			text += '${FlxStringUtil.formatBytes(memory)}' + (memType == "MEM/PEAK" ? ' / ${FlxStringUtil.formatBytes(mempeak)}' : '');
	}

	var deltaTimeout:Float = .0;
	override function __enterFrame(dt:Float) {
		if (deltaTimeout > 1000) {
			deltaTimeout = .0;
			return;
		}

		fpsManager.update();
		if (memory > mempeak) mempeak = memory;

		if (ClientPrefs.data.rainbowFps) {
			timeColor = (timeColor % 360) + 1;
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		} else if (checkLag) {
			if (fpsManager.lagged()) textColor = FlxColor.RED;
			else textColor = FlxColor.WHITE;
		}

		updateText();
		deltaTimeout += dt;
		
		super.__enterFrame(Std.int(dt));
	}
}