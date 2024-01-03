package objects;

class MenuItem extends FlxSprite {
	public var targetY:Float = 0;

	public function new(x:Float, y:Float, weekName:String = '') {
		super(x, y, Paths.image('storymenu/$weekName'));
		antialiasing = ClientPrefs.getPref('Antialiasing');
	}

	public var isFlashing(default, set):Bool = false;
	var _flashingElapsed:Float = 0.0;
	final _flashColor:Int = 0xFF33ffff;
	final flashes_ps:Int = 6;

	inline function set_isFlashing(flashing:Bool = true):Bool {
		_flashingElapsed = 0.;
		color = (flashing ? _flashColor : FlxColor.WHITE);
		return isFlashing = flashing;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		y = FlxMath.lerp((targetY * 120) + 480, y, Math.exp(-elapsed * 10.2));
		if (isFlashing) {
			_flashingElapsed += elapsed;
			color = (Math.floor(_flashingElapsed * FlxG.updateFramerate * flashes_ps) % 2 == 0) ? _flashColor : FlxColor.WHITE;
		}
	}
}
