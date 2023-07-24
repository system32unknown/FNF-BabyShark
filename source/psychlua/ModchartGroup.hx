package psychlua;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class ModchartGroup extends FlxTypedSpriteGroup<ModchartSprite> {
	public var wasAdded:Bool;
	public function new(x:Float, y:Float, maxSize:Int) {
		super(x, y, maxSize);
		antialiasing = ClientPrefs.getPref('Antialiasing');
	}
}