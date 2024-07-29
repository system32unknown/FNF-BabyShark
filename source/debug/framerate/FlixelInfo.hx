package debug.framerate;

class FlixelInfo extends FramerateCategory {
	public function new() {
		super("Flixel Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		_text = 'State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		_text += '\nSubstate: ' + (FlxG.state.subState != null ? Type.getClassName(Type.getClass(FlxG.state.subState)) : 'None');

		if (this.text.text != _text) this.text.text = _text;
		super.__enterFrame(t);
	}
}