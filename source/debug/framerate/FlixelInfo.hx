package debug.framerate;

class FlixelInfo extends FramerateCategory {
	public function new() {
		super("Flixel Info");
	}

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		var c:Int = 0;
		for(_ in FlxG.bitmap._cache.keys()) c++;

		_text = 'State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		if (FlxG.state.subState != null)
			_text += '\nSubstate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';
		_text += '\nObject Count: ${FlxG.state.members.length}';
		_text += '\nCamera Count: ${FlxG.cameras.list.length}';
		_text += '\nBitmap Count: $c';
		_text += '\nSound Count: ${FlxG.sound.list.length}';

		if (this.text.text != _text) this.text.text = _text;
		super.__enterFrame(t);
	}
}