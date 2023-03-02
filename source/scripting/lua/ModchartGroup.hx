package scripting.lua;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import utils.ClientPrefs;

class ModchartGroup extends FlxTypedSpriteGroup<ModchartSprite> {
	public var wasAdded:Bool;
	public function new(x:Float, y:Float, maxSize:Int) {
		super(x, y, maxSize);
		antialiasing = ClientPrefs.getPref('globalAntialiasing');
	}
}