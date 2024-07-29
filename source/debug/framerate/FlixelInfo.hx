package debug.framerate;

class FlixelInfo extends FramerateCategory {
	public function new() {
		super("Flixel Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		_text = 'State: ${Type.getClassName(Type.getClass(FlxG.state))}';
		if (FlxG.state.subState != null) _text += '\nSub: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';
		_text += '\nObjs:${FlxG.state.members.length}, Cams:${FlxG.cameras.list.length}, Snds:${FlxG.sound.list.length}';

		if (this.text.text != _text) this.text.text = _text;
		super.__enterFrame(t);
	}
}