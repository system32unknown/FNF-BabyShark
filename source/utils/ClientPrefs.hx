package utils;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import states.TitleState;
import game.Achievements;
import utils.Controls.KeyboardScheme;

class ClientPrefs {
	public static var prefs:Map<String, Dynamic> = [
		'downScroll' => false,
		'middleScroll' => false,
		'opponentStrums' => true,
		'showFPS' => true,
		'showMEM' => true,
		'flashing' => true,
		'globalAntialiasing' => true,
		'noteSplashes' => true,
		'lowQuality' => false,
		'shaders' => true,
		'framerate' => 60,
		'camZooms' => true,
		'camMovement' => true,
		'hideHud' => false,
		'ShowMsTiming' => false,
		'ShowAverage' => false,
		'ShowCombo' => true,
		'ShowNPSCounter' => false,
		'ShowLateEarly' => false,
		'WinningIcon' => false,
		'ShowMaxCombo' => false,
		'MstimingTypes' => "Psych",
		'ShowJudgementCount' => false,
		'IconBounceType' => 'Psych',
		'RatingTypes' => 'Static',
		'comboStacking' => true,
		'convertEK' => false,
		'showKeybindsOnStart' => false,
		'ShowLU' => false,
		'HiddenOppLU' => false,
		'LUAlpha' => 0,
		'AntiMash' => false,
		'noteOffset' => 0,
		'arrowHSV' => [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
		'ghostTapping' => true,
		'HealthTypes' => 'Psych',
		'timeBarType' => 'Time Left',
		'ScoreTextStyle' => 'BabyShark',
		'scoreZoom' => true,
		'noReset' => false,
		'AltDiscordImg' => false,
		'healthBarAlpha' => 1,
		'hitsoundVolume' => 0,
		'hitsoundTypes' => 'Tick',
		'ShowWatermark' => true,
		'pauseMusic' => 'Tea Time',
		// Gameplay settings
		'comboOffset' => [[0, 0], [0, 0], [0, 0], [0, 0]],
		'ratingOffset' => 0,
		'pefectWindow' => 15,
		'sickWindow' => 45,
		'goodWindow' => 90,
		'badWindow' => 135,
		'safeFrames' => 10
	];

	// For custom functions after the save data is loaded
	public static var loadFunctions:Map<String, (Dynamic) -> Void> = [
		'framerate' => function(framerate:Int) {
			if (framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		},
		'customControls' => function(controls:Map<String, Array<FlxKey>>) {
			reloadControls();
		}
	];

	// Flixel data to load, i.e 'mute' or 'volume'
	public static var flixelData:Map<String, String> = [
		'volume' => 'volume',
		'mute' => 'muted'
	];

	// Maps like gameplaySettings
	public static var mapData:Map<String, Array<Dynamic>> = [
		'gameplaySettings' => [ClientPrefs, 'gameplaySettings'],
		'customControls' => [ClientPrefs, 'keyBinds'],

		'achievementsMap' => [Achievements, 'achievementsMap'],
		'henchmenDeath' => [Achievements, 'henchmenDeath']
	];

	// For stuff that needs to be in the controls_v2 save
	public static var separateSaves:Array<String> = [
		'customControls'
	];

	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false
	];

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_one1'		=> [SPACE, NONE],

		'note_two1'		=> [D, NONE],
		'note_two2'		=> [K, NONE],

		'note_three1'	=> [D, NONE],
		'note_three2'	=> [SPACE, NONE],
		'note_three3'	=> [K, NONE],

		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'note_five1'	=> [D, NONE],
		'note_five2'	=> [F, NONE],
		'note_five3'	=> [SPACE, NONE],
		'note_five4'	=> [J, NONE],
		'note_five5'	=> [K, NONE],

		'note_six1'		=> [S, NONE],
		'note_six2'		=> [D, NONE],
		'note_six3'		=> [F, NONE],
		'note_six4'		=> [J, NONE],
		'note_six5'		=> [K, NONE],
		'note_six6'		=> [L, NONE],

		'note_seven1'	=> [S, NONE],
		'note_seven2'	=> [D, NONE],
		'note_seven3'	=> [F, NONE],
		'note_seven4'	=> [SPACE, NONE],
		'note_seven5'	=> [J, NONE],
		'note_seven6'	=> [K, NONE],
		'note_seven7'	=> [L, NONE],

		'note_eight1'	=> [A, NONE],
		'note_eight2'	=> [S, NONE],
		'note_eight3'	=> [D, NONE],
		'note_eight4'	=> [F, NONE],
		'note_eight5'	=> [H, NONE],
		'note_eight6'	=> [J, NONE],
		'note_eight7'	=> [K, NONE],
		'note_eight8'	=> [L, NONE],

		'note_nine1'	=> [A, NONE],
		'note_nine2'	=> [S, NONE],
		'note_nine3'	=> [D, NONE],
		'note_nine4'	=> [F, NONE],
		'note_nine5'	=> [SPACE, NONE],
		'note_nine6'	=> [H, NONE],
		'note_nine7'	=> [J, NONE],
		'note_nine8'	=> [K, NONE],
		'note_nine9'	=> [L, NONE],

		'note_ten1'		=> [A, NONE],
		'note_ten2'		=> [S, NONE],
		'note_ten3'		=> [D, NONE],
		'note_ten4'		=> [F, NONE],
		'note_ten5'		=> [G, NONE],
		'note_ten6'		=> [SPACE, NONE],
		'note_ten7'		=> [H, NONE],
		'note_ten8'     => [J, NONE],
		'note_ten9'		=> [K, NONE],
		'note_ten10'	=> [L, NONE],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = keyBinds;

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
	}

	public static function saveSettings() {
		var save:Dynamic = FlxG.save.data;

		for (setting => value in prefs) {
			if (!separateSaves.contains(setting))
				Reflect.setField(save, setting, value);
		}
		for (savedAs => map in mapData) {
			if (!separateSaves.contains(savedAs))
				Reflect.setField(save, savedAs, Reflect.field(map[0], map[1]));
		}
	
		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'altertoriel'); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff

		for (name in separateSaves) {
			if (prefs.exists(name)) {
				Reflect.setField(save.data, name, prefs.get(name));
				continue;
			}
			if (mapData.exists(name)) {
				var map:Array<Dynamic> = mapData.get(name);
				Reflect.setField(save.data, name, Reflect.field(map[0], map[1]));
				continue;
			}
		}

		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		var save:Dynamic = FlxG.save.data;
		for (setting in prefs.keys()) {
			var value:Dynamic = Reflect.getProperty(save, setting);
			if (value != null && !separateSaves.contains(setting)) {
				prefs.set(setting, value);
				if (loadFunctions.exists(setting)) loadFunctions.get(setting)(value); // Call the load function
			}
		}
		
		for (setting => name in flixelData) {
			var value:Dynamic = Reflect.field(save, setting);
			if (value != null) Reflect.setField(FlxG.sound, name, value);
		}

		for (savedAs => map in mapData) {
			if (!separateSaves.contains(savedAs)) {
				var data:Map<Dynamic, Dynamic> = Reflect.field(save, savedAs);
				if (data != null) {
					var loadTo:Dynamic = Reflect.field(map[0], map[1]);
					for (name => value in data) {
						if (loadTo.exists(name))
							loadTo.set(name, value);
					}
					if (loadFunctions.exists(savedAs)) loadFunctions.get(savedAs)(loadTo); // Call the load function
				}
			}
		}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'altertoriel');
		if (save != null) {
			for (name in separateSaves) {
				var data:Dynamic = Reflect.field(save.data, name);
				if (data != null) {
					if (prefs.exists(name)) {
						prefs.set(name, data);
						continue;
					}
					if (mapData.exists(name)) {
						var map:Array<Dynamic> = mapData.get(name);
						var loadTo:Dynamic = Reflect.field(map[0], map[1]);

						for (name => value in cast(data, Map<Dynamic, Dynamic>)) {
							if (loadTo.exists(name))
								loadTo.set(name, value);
						}
						if (loadFunctions.exists(name)) loadFunctions.get(name)(loadTo); // Call the load function
						continue;
					}
				}
			}
		}
		loadDefaultKeys();
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	inline public static function getPref(name:String, ?defaultValue:Dynamic):Dynamic {
		if (prefs.exists(name)) return prefs.get(name);
		return defaultValue;
	}

	public static function reloadControls() {
		PlayerSettings.player.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));

		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var len:Int = copiedArray.length;
		var i:Int = 0;

		while (i < len) {
			if (copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				i--;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
