package objects;

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;
	public var flashingInt:Int = 0;

	public function new(x:Float, y:Float, weekName:String = '') {
		super(x, y);
		loadGraphic(Paths.image('storymenu/' + weekName));
		antialiasing = ClientPrefs.getPref('Antialiasing');
	}

	var isFlashing:Bool = false;
	public function startFlashing():Void
		isFlashing = true;

	var time:Float = 0;
	override function update(elapsed:Float) {
		super.update(elapsed);
		time += elapsed;
		y = FlxMath.lerp(y, (targetY * 120) + 480, FlxMath.bound(elapsed * 10.2, 0, 1));

		if (isFlashing) color = (time % .1 > .05) ? FlxColor.WHITE : 0xFF33ffff;
	}
}
