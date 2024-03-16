package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

class ClientPrefs {
	static var isHardCInited:Bool = false;
	static var isStreMInited:Bool = false;

	public static var prefs:Map<String, Dynamic> = [
		'downScroll' => false,
		'middleScroll' => false,
		'opponentStrums' => true,
		'FPSStats' => true,
		'showFPS' => true,
		'memCounterType' => "MEM/PEAK",
		'flashing' => true,
		'Antialiasing' => true,
		'splashOpacity' => .6,
		'lowQuality' => false,
		'shaders' => true,
		'framerate' => 60,
		'camZooms' => true,
		'camMovement' => true,
		'hideHud' => false,
		'ShowMsTiming' => false,
		'ShowComboCounter' => false,
		'ShowNPS' => false,
		'SmoothHealth' => false,
		'loadingScreen' => false,
		'complexAccuracy' => false,
		'ShowLateEarly' => false,
		'NoteDiffTypes' => "Simple",
		'ShowJudgement' => true,
		'IconBounceType' => 'Psych',
		'RatingDisplay' => 'World',
		'RainbowFps' => false,
		'comboStacking' => false,
		'showKeybindsOnStart' => false,
		'hardwareCache' => false,
		'streamMusic' => false,
		'AntiMash' => false,
		'noteOffset' => 0,
		'ghostTapping' => true,
		'HealthTypes' => 'Vanilla',
		'timeBarType' => 'Name Time Position',
		'noReset' => false,
		'AltDiscordImg' => false,
		'AltDiscordImgCount' => 0,
		'UpdateCamSection' => false,
		'healthBarAlpha' => 1,
		'hitsoundVolume' => 0,
		'autoPause' => true,
		'autoPausePlayState' => true,
		'hitsoundTypes' => 'Tick',
		'pauseMusic' => 'Tea Time',
		'unlockedCharacters' => ['bf', 'bf-pixel', 'bf-christmas', 'bs', 'bs-pixel', 'alter-holding-bs', 'pico-player', 'nate-player'],
		'discordRPC' => true,

		'noteSkin' => 'Default',
		'splashSkin' => 'Psych',

		'arrowRGBExtra' => [
			[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
			[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
			[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
			[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
			[0xFF999999, 0xFFFFFFFF, 0xFF201E31],
			[0xFFFFFF00, 0xFFFFFFFF, 0xFF993300],
			[0xFF8b4aff, 0xFFFFFFFF, 0xFF3b177d],
			[0xFFFF0000, 0xFFFFFFFF, 0xFF660000],
			[0xFF0033ff, 0xFFFFFFFF, 0xFF000066]
		],
		'arrowRGBPixelExtra' => [
			[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
			[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
			[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
			[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000],
			[0xFFb6b6b6, 0xFFFFFFFF, 0xFF444444],
			[0xFFffd94a, 0xFFfffff9, 0xFF663500],
			[0xFFB055BC, 0xFFf4f4ff, 0xFF4D0060],
			[0xFFdf3e23, 0xFFffe6e9, 0xFF440000],
			[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D]
		],

		// Gameplay settings
		'comboOffset' => [[0, 0], [0, 0], [0, 0]],
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
			if(FlxG.save.data.framerate == null)
				framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 60, 240));

			if (framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}, 'keyboard' => (controls:Map<String, Array<FlxKey>>) -> {
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
		}, 'showFPS' => (bool:Bool) -> if(Main.fpsVar != null) Main.fpsVar.visible = bool,
		'memCounterType' => (type:String) -> if(Main.fpsVar != null) Main.fpsVar.memCounterType = type
	];

	// Flixel data to load, i.e 'mute' or 'volume'
	public static var flixelData:Map<String, String> = [
		'volume' => 'volume',
		'mute' => 'muted',
		'autoPause' => 'autoPause',
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
		//Key Bind, Name for ControlsSubState
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
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static function loadDefaultKeys() defaultKeys = keyBinds.copy();

	public static function resetKeys() {
		for (key in keyBinds.keys()) if(defaultKeys.exists(key)) keyBinds.set(key, defaultKeys.get(key).copy());
	}

	public static function clearInvalidKeys(key:String) {
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
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
				if (setting == 'autoPause')
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
						if (loadTo.exists(name)) loadTo.set(name, value);
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
		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if(!customDefaultValue) defaultValue = defaultgameplaySettings.get(name);
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys() {
		Main.muteKeys = keyBinds.get('volume_mute').copy();
		Main.volumeDownKeys = keyBinds.get('volume_down').copy();
		Main.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(turnOn:Bool = true) {
		FlxG.sound.muteKeys = turnOn ? Main.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? Main.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? Main.volumeUpKeys : [];
	}

	inline public static function getPref(name:String, ?defaultValue:Dynamic):Dynamic {
		if (prefs.exists(name)) return prefs.get(name);
		return defaultValue;
	}
}