package scripting.lua;

import flixel.FlxSprite;

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function new(?x:Float = 0, ?y:Float = 0) {
		super(x, y);
		antialiasing = ClientPrefs.getPref('globalAntialiasing');
	}
}