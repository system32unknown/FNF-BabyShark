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
		'ShowComboCounter' => false,
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

		'note_elev1'	=> [A, NONE],
		'note_elev2'	=> [S, NONE],
		'note_elev3'	=> [D, NONE],
		'note_elev4'	=> [F, NONE],
		'note_elev5'	=> [G, NONE],
		'note_elev6'	=> [SPACE, NONE],
		'note_elev7'	=> [H, NONE],
		'note_elev8'    => [J, NONE],
		'note_elev9'	=> [K, NONE],
		'note_elev10'	=> [L, NONE],
		'note_elev11'	=> [PERIOD, NONE],
		
		'note_twel1'	=> [A, NONE],
		'note_twel2'	=> [S, NONE],
		'note_twel3'	=> [D, NONE],
		'note_twel4'	=> [F, NONE],
		'note_twel5'	=> [C, NONE],
		'note_twel6'	=> [V, NONE],
		'note_twel7'	=> [N, NONE],
		'note_twel8'    => [M, NONE],
		'note_twel9'	=> [H, NONE],
		'note_twel10'	=> [J, NONE],
		'note_twel11'	=> [K, NONE],
		'note_twel12'	=> [L, NONE],

		'note_thir1'	=> [A, NONE],
		'note_thir2'	=> [S, NONE],
		'note_thir3'	=> [D, NONE],
		'note_thir4'	=> [F, NONE],
		'note_thir5'	=> [C, NONE],
		'note_thir6'	=> [V, NONE],
		'note_thir7'	=> [SPACE, NONE],
		'note_thir8'	=> [N, NONE],
		'note_thir9'    => [M, NONE],
		'note_thir10'	=> [H, NONE],
		'note_thir11'	=> [J, NONE],
		'note_thir12'	=> [K, NONE],
		'note_thir13'	=> [L, NONE],

		'note_fourt1'	=> [A, NONE],
		'note_fourt2'	=> [S, NONE],
		'note_fourt3'	=> [D, NONE],
		'note_fourt4'	=> [F, NONE],
		'note_fourt5'	=> [C, NONE],
		'note_fourt6'	=> [V, NONE],
		'note_fourt7'	=> [T, NONE],
		'note_fourt8'   => [Y, NONE],
		'note_fourt9'	=> [N, NONE],
		'note_fourt10'	=> [M, NONE],
		'note_fourt11'	=> [H, NONE],
		'note_fourt12'	=> [J, NONE],
		'note_fourt13'	=> [K, NONE],
		'note_fourt14'	=> [L, NONE],

		'note_151'	=> [A, NONE],
		'note_152'	=> [S, NONE],
		'note_153'	=> [D, NONE],
		'note_154'	=> [F, NONE],
		'note_155'	=> [C, NONE],
		'note_156'	=> [V, NONE],
		'note_157'	=> [T, NONE],
		'note_158'  => [Y, NONE],
		'note_159'  => [U, NONE],
		'note_1510'	=> [N, NONE],
		'note_1511'	=> [M, NONE],
		'note_1512'	=> [H, NONE],
		'note_1513'	=> [J, NONE],
		'note_1514'	=> [K, NONE],
		'note_1515'	=> [L, NONE],

		'note_161'	=> [A, NONE],
		'note_162'	=> [S, NONE],
		'note_163'	=> [D, NONE],
		'note_164'	=> [F, NONE],
		'note_165'	=> [Q, NONE],
		'note_166'	=> [W, NONE],
		'note_167'	=> [E, NONE],
		'note_168'  => [R, NONE],
		'note_169'  => [Y, NONE],
		'note_1610'	=> [U, NONE],
		'note_1611'	=> [I, NONE],
		'note_1612'	=> [O, NONE],
		'note_1613'	=> [H, NONE],
		'note_1614'	=> [J, NONE],
		'note_1615'	=> [K, NONE],
		'note_1616'	=> [L, NONE],

		'note_171'	=> [A, NONE],
		'note_172'	=> [S, NONE],
		'note_173'	=> [D, NONE],
		'note_174'	=> [F, NONE],
		'note_175'	=> [Q, NONE],
		'note_176'	=> [W, NONE],
		'note_177'	=> [E, NONE],
		'note_178'  => [R, NONE],
		'note_179'  => [SPACE, NONE],
		'note_1710' => [Y, NONE],
		'note_1711'	=> [U, NONE],
		'note_1712'	=> [I, NONE],
		'note_1713'	=> [O, NONE],
		'note_1714'	=> [H, NONE],
		'note_1715'	=> [J, NONE],
		'note_1716'	=> [K, NONE],
		'note_1717'	=> [L, NONE],

		'note_181'	=> [A, NONE],
		'note_182'	=> [S, NONE],
		'note_183'	=> [D, NONE],
		'note_184'	=> [F, NONE],
		'note_185'	=> [SPACE, NONE],
		'note_186'	=> [H, NONE],
		'note_187'	=> [J, NONE],
		'note_188'	=> [K, NONE],
		'note_189'  => [L, NONE],
		'note_1810' => [Q, NONE],
		'note_1811'	=> [W, NONE],
		'note_1812'	=> [E, NONE],
		'note_1813'	=> [R, NONE],
		'note_1814'	=> [T, NONE],
		'note_1815'	=> [Y, NONE],
		'note_1816'	=> [U, NONE],
		'note_1817'	=> [I, NONE],
		'note_1818'	=> [O, NONE],
		
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