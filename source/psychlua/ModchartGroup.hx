package psychlua;

class ModchartGroup extends flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup<ModchartSprite> {
	public var wasAdded:Bool;
	public function new(x:Float, y:Float, maxSize:Int) {
		super(x, y, maxSize);
		antialiasing = ClientPrefs.getPref('Antialiasing');
	}
}