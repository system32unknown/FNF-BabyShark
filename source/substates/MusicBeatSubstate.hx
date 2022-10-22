package substates;

import utils.Controls;
import utils.PlayerSettings;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player.controls;

	public function new() {
		super();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}
