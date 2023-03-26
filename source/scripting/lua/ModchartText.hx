package scripting.lua;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class ModchartText extends FlxText {
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float) {
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
	}
}