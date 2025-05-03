package backend;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

@:noCustomClass
class Controls {
	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx
	public static final default_binds:Map<String, Array<FlxKey>> = [
		'note_1' 		=> [SPACE],
		'note_3a'		=> [SPACE],
		'note_5a'		=> [SPACE],

		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'note_6a'		=> [S],
		'note_6b'		=> [D],
		'note_6c'		=> [F],
		'note_6d'		=> [J],
		'note_6e'		=> [K],
		'note_6f'		=> [L],
		
		'note_7a'		=> [S],
		'note_7b'		=> [D],
		'note_7c'		=> [F],
		'note_7d'		=> [SPACE],
		'note_7e'		=> [J],
		'note_7f'		=> [K],
		'note_7g'		=> [L],
		
		'note_8a'		=> [A],
		'note_8b'		=> [S],
		'note_8c'		=> [D],
		'note_8d'		=> [F],
		'note_8e'		=> [H],
		'note_8f'		=> [J],
		'note_8g'		=> [K],
		'note_8h'		=> [L],
		
		'note_9a'		=> [A],
		'note_9b'		=> [S],
		'note_9c'		=> [D],
		'note_9d'		=> [F],
		'note_9e'		=> [SPACE],
		'note_9f'		=> [H],
		'note_9g'		=> [J],
		'note_9h'		=> [K],
		'note_9i'		=> [L],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static var binds:Map<String, Array<Int>> = default_binds;

	static var _save:FlxSave;

	public static function justPressed(name:String):Bool return _getKeyStatus(name, JUST_PRESSED);
	public static function pressed(name:String):Bool return _getKeyStatus(name, PRESSED);
	public static function released(name:String):Bool return _getKeyStatus(name, JUST_RELEASED);

	// backend functions to reduce repetitive code
	static function _getKeyStatus(name:String, state:flixel.input.FlxInput.FlxInputState):Bool {
		var binds:Array<FlxKey> = binds[name];
		if (binds == null) {
			Logs.warn('Keybind "$name" doesn\'t exist.');
			return false;
		}

		var keyHasState:Bool = false;
		for (key in binds) {
			@:privateAccess
			if (FlxG.keys.getKey(key).hasState(state)) {
				keyHasState = true;
				break;
			}
		}
		return keyHasState;
	}

	public static function save() {
		_save.data.binds = binds;
		_save.flush();
	}

	public static function load() {
		if (_save == null) {
			_save = new FlxSave();
			_save.bind('controls', Util.getSavePath());
		}

		if (_save.data.binds != null) {
			var loadedKeys:Map<String, Array<FlxKey>> = _save.data.binds;
			for (control => keys in loadedKeys) {
				if (!binds.exists(control)) continue;
				binds.set(control, keys);
			}
		}
		reloadVolumeKeys();
	}

	public static function convertStrumKey(arr:Array<String>, key:FlxKey):Int {
		if (key == NONE) return -1;
		for (i in 0...arr.length) {
			for (possibleKey in binds[arr[i]]) {
				if (key == possibleKey) return i;
			}
		}
		return -1;
	}

	public static function reset() {
		for (key in binds.keys()) {
			if (!default_binds.exists(key)) continue;
			binds.set(key, default_binds.get(key).copy());
		}
	}

	public static function reloadVolumeKeys() {
		Main.muteKeys = binds.get('volume_mute').copy();
		Main.volumeDownKeys = binds.get('volume_down').copy();
		Main.volumeUpKeys = binds.get('volume_up').copy();
		toggleVolumeKeys();
	}

	public static function toggleVolumeKeys(turnOn:Bool = true) {
		final emptyArray:Array<FlxKey> = [];
		FlxG.sound.muteKeys = turnOn ? Main.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = turnOn ? Main.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = turnOn ? Main.volumeUpKeys : emptyArray;
	}
}