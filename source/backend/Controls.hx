package backend;

import flixel.input.keyboard.FlxKey;

//Keeping same use cases on stuff for it to be easier to understand/use
class Controls {
	public var UI_UP_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	function get_UI_UP_P() return justPressed('ui_up');
	function get_UI_DOWN_P() return justPressed('ui_down');
	function get_UI_LEFT_P() return justPressed('ui_left');
	function get_UI_RIGHT_P() return justPressed('ui_right');
	function get_NOTE_UP_P() return justPressed('note_up');
	function get_NOTE_DOWN_P() return justPressed('note_down');
	function get_NOTE_LEFT_P() return justPressed('note_left');
	function get_NOTE_RIGHT_P() return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	function get_UI_UP() return pressed('ui_up');
	function get_UI_DOWN() return pressed('ui_down');
	function get_UI_LEFT() return pressed('ui_left');
	function get_UI_RIGHT() return pressed('ui_right');
	function get_NOTE_UP() return pressed('note_up');
	function get_NOTE_DOWN() return pressed('note_down');
	function get_NOTE_LEFT() return pressed('note_left');
	function get_NOTE_RIGHT() return pressed('note_right');

	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	function get_UI_UP_R() return justReleased('ui_up');
	function get_UI_DOWN_R() return justReleased('ui_down');
	function get_UI_LEFT_R() return justReleased('ui_left');
	function get_UI_RIGHT_R() return justReleased('ui_right');
	function get_NOTE_UP_R() return justReleased('note_up');
	function get_NOTE_DOWN_R() return justReleased('note_down');
	function get_NOTE_LEFT_R() return justReleased('note_left');
	function get_NOTE_RIGHT_R() return justReleased('note_right');

	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	function get_ACCEPT() return justPressed('accept');
	function get_BACK() return justPressed('back');
	function get_PAUSE() return justPressed('pause');
	function get_RESET() return justPressed('reset');

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	
	public function justPressed(key:String) {
		return FlxG.keys.anyJustPressed(keyboardBinds[key]);
	}
	public function pressed(key:String) {
		return FlxG.keys.anyPressed(keyboardBinds[key]);
	}

	public function justReleased(key:String) {
		return FlxG.keys.anyJustReleased(keyboardBinds[key]);
	}

	public static var instance:Controls;

	public function new() {
		keyboardBinds = ClientPrefs.keyBinds;
	}
}