package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import states.TitleState;

class ClientPrefs {
	static var isHardCInited:Bool = false;
	static var isStreMInited:Bool = false;

	public static var prefs:Map<String, Dynamic> = [
		'downScroll' => false,
		'middleScroll' => false,
		'opponentStrums' => true,
		'FPSStats' => false,
		'showFPS' => true,
		'showMEM' => true,
		'flashing' => true,
		'Antialiasing' => true,
		'noteSkin' => 'Default',
		'splashSkin' => 'Psych',
		'splashOpacity' => .6,
		'lowQuality' => false,
		'shaders' => true,
		'framerate' => 60,
		'camZooms' => true,
		'camMovement' => true,
		'hideHud' => false,
		'ShowMsTiming' => false,
		'ShowCombo' => false,
		'ShowNPSCounter' => false,
		'complexAccuracy' => false,
		'ShowLateEarly' => false,
		'NoteDiffTypes' => "Simple",
		'ScoreType' => 'Kade',
		'ShowJudgementCount' => true,
		'IconBounceType' => 'Vanilla',
		'RatingDisplay' => 'World',
		'RainbowFps' => false,
		'comboStacking' => false,
		'showKeybindsOnStart' => false,
		'hardwareCache' => false,
		'streamMusic' => false,
		'AntiMash' => false,
		'noteOffset' => 0,
		'arrowHSV' => [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
		'ghostTapping' => true,
		'HealthTypes' => 'Vanilla',
		'timeBarType' => 'Time Left',
		'noReset' => false,
		'movemissjudge' => false,
		'AltDiscordImg' => false,
		'UpdateCamSection' => false,
		'healthBarAlpha' => 1,
		'hitsoundVolume' => 0,
		'autoPause' => true,
		'fullscreen' => false,
		'hitsoundTypes' => 'Tick',
		'pauseMusic' => 'Tea Time',
		'discordRPC' => true,
		// Gameplay settings
		'comboOffset' => [[0, 0], [0, 0], [0, 0], [0, 0]],
		'ratingOffset' => 0,
		'epicWindow' => 15,
		'sickWindow' => 45,
		'goodWindow' => 90,
		'okWindow' => 135,
		'safeFrames' => 10
	];

	// For custom functions after the save data is loaded
	public static var loadFunctions:Map<String, Dynamic -> Void> = [
		'framerate' => function(framerate:Int) {
			if (framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}, 'keyboard' => function(controls:Map<String, Array<FlxKey>>) {
			reloadVolumeKeys();
		}, 'hardwareCache' => function(bool:Bool) {
			if (!isHardCInited) {
				Paths.hardwareCache = bool;
				isHardCInited = true;
			}
		}, 'streamMusic' => function(bool:Bool) {
			if (!isStreMInited) {
				Paths.streamMusic = bool;
				isStreMInited = true;
			}
		}
	];

	// Flixel data to load, i.e 'mute' or 'volume'
	public static var flixelData:Map<String, String> = [
		'volume' => 'volume',
		'mute' => 'muted',
		'autoPause' => 'autoPause',
		'fullscreen' => 'fullscreen',
	];

	// Maps like gameplaySettings
	public static var mapData:Map<String, Array<Dynamic>> = [
		'gameplaySettings' => [ClientPrefs, 'gameplaySettings'],
		'keyboard' => [ClientPrefs, 'keyBinds'],
	];

	// For stuff that needs to be in the controls save
	public static var separateSaves:Array<String> = [
		'keyboard'
	];

	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.,
		'scrolltype' => 'multiplicative',
		
		'songspeed' => 1.,
		'healthgain' => 1.,
		'healthloss' => 1.,
		'instakill' => false,
		'practice' => false,
		'botplay' => false
	];

	public static var defaultgameplaySettings:Map<String, Dynamic> = gameplaySettings.copy();
	public static var defaultprefs:Map<String, Dynamic> = prefs.copy();

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],

		'1_key_0'		=> [SPACE, W],

		'2_key_0'		=> [A, NONE],
		'2_key_1'		=> [D, S],
	
		'3_key_0'		=> [A, NONE],
		'3_key_1'		=> [S, NONE],
		'3_key_2'		=> [D, NONE],
	
		'4_key_0'		=> [A, LEFT],
		'4_key_1'		=> [S, DOWN],
		'4_key_2'		=> [W, UP],
		'4_key_3'		=> [D, RIGHT],
	
		'5_key_0'		=> [A, LEFT],
		'5_key_1'		=> [S, DOWN],
		'5_key_2'		=> [SPACE, NONE],
		'5_key_3'		=> [W, UP],
		'5_key_4'		=> [D, RIGHT],
	
		'6_key_0'		=> [S, NONE],
		'6_key_1'		=> [D, NONE],
		'6_key_2'		=> [F, NONE],
		'6_key_3'		=> [J, NONE],
		'6_key_4'		=> [K, NONE],
		'6_key_5'		=> [L, NONE],
	
		'7_key_0'		=> [S, NONE],
		'7_key_1'		=> [D, NONE],
		'7_key_2'		=> [F, NONE],
		'7_key_3'		=> [SPACE, NONE],
		'7_key_4'		=> [J, NONE],
		'7_key_5'		=> [K, NONE],
		'7_key_6'		=> [L, NONE],
	
		'8_key_0'		=> [A, NONE],
		'8_key_1'		=> [S, NONE],
		'8_key_2'		=> [D, NONE],
		'8_key_3'		=> [F, NONE],
		'8_key_4'		=> [H, NONE],
		'8_key_5'		=> [J, NONE],
		'8_key_6'		=> [K, NONE],
		'8_key_7'		=> [L, NONE],
	
		'9_key_0'		=> [A, NONE],
		'9_key_1'		=> [S, NONE],
		'9_key_2'		=> [D, NONE],
		'9_key_3'		=> [F, NONE],
		'9_key_4'		=> [SPACE, NONE],
		'9_key_5'		=> [H, NONE],
		'9_key_6'		=> [J, NONE],
		'9_key_7'		=> [K, NONE],
		'9_key_8'		=> [L, NONE],
	
		'10_key_0'		=> [A, NONE],
		'10_key_1'		=> [S, NONE],
		'10_key_2'		=> [D, NONE],
		'10_key_3'		=> [F, NONE],
		'10_key_4'		=> [G, NONE],
		'10_key_5'		=> [SPACE, NONE],
		'10_key_6'		=> [H, NONE],
		'10_key_7'		=> [J, NONE],
		'10_key_8'		=> [K, NONE],
		'10_key_9'		=> [L, NONE],
	
		'11_key_0'		=> [A, NONE],
		'11_key_1'		=> [S, NONE],
		'11_key_2'		=> [D, NONE],
		'11_key_3'		=> [F, NONE],
		'11_key_4'		=> [G, NONE],
		'11_key_5'		=> [SPACE, NONE],
		'11_key_6'		=> [H, NONE],
		'11_key_7'		=> [J, NONE],
		'11_key_8'		=> [K, NONE],
		'11_key_9'		=> [L, NONE],
		'11_key_10'		=> [PERIOD, NONE],
	
		// submitted by @btoad on discord (formerly: btoad#2337)
		'12_key_0'		=> [A, NONE],
		'12_key_1'		=> [S, NONE],
		'12_key_2'		=> [D, NONE],
		'12_key_3'		=> [F, NONE],
		'12_key_4'		=> [C, NONE],
		'12_key_5'		=> [V, NONE],
		'12_key_6'		=> [N, NONE],
		'12_key_7'		=> [M, NONE],
		'12_key_8'		=> [H, NONE],
		'12_key_9'		=> [J, NONE],
		'12_key_10'		=> [K, NONE],
		'12_key_11'		=> [L, NONE],
	
		'13_key_0'		=> [A, NONE],
		'13_key_1'		=> [S, NONE],
		'13_key_2'		=> [D, NONE],
		'13_key_3'		=> [F, NONE],
		'13_key_4'		=> [C, NONE],
		'13_key_5'		=> [V, NONE],
		'13_key_6'		=> [SPACE, NONE],
		'13_key_7'		=> [N, NONE],
		'13_key_8'		=> [M, NONE],
		'13_key_9'		=> [H, NONE],
		'13_key_10'		=> [J, NONE],
		'13_key_11'		=> [K, NONE],
		'13_key_12'		=> [L, NONE],
	
		'14_key_0'		=> [A, NONE],
		'14_key_1'		=> [S, NONE],
		'14_key_2'		=> [D, NONE],
		'14_key_3'		=> [F, NONE],
		'14_key_4'		=> [C, NONE],
		'14_key_5'		=> [V, NONE],
		'14_key_6'		=> [T, NONE],
		'14_key_7'		=> [Y, NONE],
		'14_key_8'		=> [N, NONE],
		'14_key_9'		=> [M, NONE],
		'14_key_10'		=> [H, NONE],
		'14_key_11'		=> [J, NONE],
		'14_key_12'		=> [K, NONE],
		'14_key_13'		=> [L, NONE],
	
		'15_key_0'		=> [A, NONE],
		'15_key_1'		=> [S, NONE],
		'15_key_2'		=> [D, NONE],
		'15_key_3'		=> [F, NONE],
		'15_key_4'		=> [C, NONE],
		'15_key_5'		=> [V, NONE],
		'15_key_6'		=> [T, NONE],
		'15_key_7'		=> [Y, NONE],
		'15_key_8'		=> [U, NONE],
		'15_key_9'		=> [N, NONE],
		'15_key_10'		=> [M, NONE],
		'15_key_11'		=> [H, NONE],
		'15_key_12'		=> [J, NONE],
		'15_key_13'		=> [K, NONE],
		'15_key_14'		=> [L, NONE],
	
		'16_key_0'		=> [A, NONE],
		'16_key_1'		=> [S, NONE],
		'16_key_2'		=> [D, NONE],
		'16_key_3'		=> [F, NONE],
		'16_key_4'		=> [Q, NONE],
		'16_key_5'		=> [W, NONE],
		'16_key_6'		=> [E, NONE],
		'16_key_7'		=> [R, NONE],
		'16_key_8'		=> [Y, NONE],
		'16_key_9'		=> [U, NONE],
		'16_key_10'		=> [I, NONE],
		'16_key_11'		=> [O, NONE],
		'16_key_12'		=> [H, NONE],
		'16_key_13'		=> [J, NONE],
		'16_key_14'		=> [K, NONE],
		'16_key_15'		=> [L, NONE],
	
		'17_key_0'		=> [A, NONE],
		'17_key_1'		=> [S, NONE],
		'17_key_2'		=> [D, NONE],
		'17_key_3'		=> [F, NONE],
		'17_key_4'		=> [Q, NONE],
		'17_key_5'		=> [W, NONE],
		'17_key_6'		=> [E, NONE],
		'17_key_7'		=> [R, NONE],
		'17_key_8'		=> [SPACE, NONE],
		'17_key_9'		=> [Y, NONE],
		'17_key_10'		=> [U, NONE],
		'17_key_11'		=> [I, NONE],
		'17_key_12'		=> [O, NONE],
		'17_key_13'		=> [H, NONE],
		'17_key_14'		=> [J, NONE],
		'17_key_15'		=> [K, NONE],
		'17_key_16'		=> [L, NONE],
	
		'18_key_0'		=> [A, NONE],
		'18_key_1'		=> [S, NONE],
		'18_key_2'		=> [D, NONE],
		'18_key_3'		=> [F, NONE],
		'18_key_4'		=> [SPACE, NONE],
		'18_key_5'		=> [H, NONE],
		'18_key_6'		=> [J, NONE],
		'18_key_7'		=> [K, NONE],
		'18_key_8'		=> [L, NONE],
		'18_key_9'		=> [Q, NONE],
		'18_key_10'		=> [W, NONE],
		'18_key_11'		=> [E, NONE],
		'18_key_12'		=> [R, NONE],
		'18_key_13'		=> [T, NONE],
		'18_key_14'		=> [Y, NONE],
		'18_key_15'		=> [U, NONE],
		'18_key_16'		=> [I, NONE],
		'18_key_17'		=> [O, NONE],
		
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
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static function loadDefaultKeys() {defaultKeys = keyBinds.copy();}

	public static function clearInvalidKeys(key:String) {
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
	}

	public static function resetKeys() {
		for (key in keyBinds.keys()) if(defaultKeys.exists(key)) keyBinds.set(key, defaultKeys.get(key).copy());
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
		save.bind('controls', CoolUtil.getSavePath());

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
			if (value != null) {
				if (setting == 'autoPause' || setting == 'fullscreen')
					Reflect.setField(FlxG, name, value);
				else Reflect.setField(FlxG.sound, name, value);
			}
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
		save.bind('controls', CoolUtil.getSavePath());
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
							if (loadTo.exists(name)) loadTo.set(name, value);
						}
						if (loadFunctions.exists(name)) loadFunctions.get(name)(loadTo); // Call the load function
						continue;
					}
				}
			}
		}
		#if desktop Discord.check(); #end
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if(!customDefaultValue) defaultValue = defaultgameplaySettings.get(name);
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys() {
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(turnOn:Bool) {
		if(turnOn) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		} else {
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
	}

	inline public static function getPref(name:String, ?defaultValue:Dynamic):Dynamic {
		if (prefs.exists(name)) return prefs.get(name);
		return defaultValue;
	}
}