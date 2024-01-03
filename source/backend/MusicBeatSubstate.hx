package backend;

class MusicBeatSubstate extends flixel.FlxSubState {
	var controls(get, never):Controls;
	inline function get_controls():Controls return Controls.instance;
}