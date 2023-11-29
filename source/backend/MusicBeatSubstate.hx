package backend;

import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState {
	var controls(get, never):Controls;
	inline function get_controls():Controls return Controls.instance;
}