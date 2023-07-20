package utils;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import states.TitleState;
import game.Achievements;

class SaveVariables {
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var FPSStats:Bool = false;
	public var showFPS:Bool = true;
	public var showMEM:Bool = true;
	public var flashing:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashOpacity:Float = .6;
	public var lowQuality:Bool = false;
	public var camMovement:Bool = true;
	public var shaders:Bool = true;
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var noteOffset:Int = 0;
	public var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public var LUType:String = 'Never';
	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var ShowMsTiming:Bool = false;
	public var ShowCombo:Bool = false;
	public var ShowNPSCounter:Bool = false;
	public var ShowLateEarly:Bool = false;
	public var NoteDiffTypes:String = "Simple";
	public var ScoreType:String = 'Kade';
	public var ShowJudgementCount:Bool = true;
	public var IconBounceTyp:String = 'Vanilla';
	public var RatingDisplay:String = 'World';
	public var RainbowFps:Bool = false;
	public var comboStacking:Bool = true;
	public var showKeybindsOnStart:Bool = false;
	public var hardwareCache:Bool =  false;
	public var streamMusic:Bool = false;
	public var LUAlpha:Float = 0;
	public var AntiMash:Bool = false;
	public var HealthTypes:String = 'Vanilla';
	public var movemissjudge:Bool = false;
	public var AltDiscordImg:Bool = false;
	public var UpdateCamSection:Bool = false;
	public var hitsoundTypes:String = 'Tick';
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 

		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false
	];

	public var comboOffset:Array<Array<Int>> = [[0, 0], [0, 0], [0, 0], [0, 0]];
	public var ratingOffset:Int = 0;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var discordRPC:Bool = true;

	public function new() { }
}

class ClientPrefs {
	public static var isHardCInited:Bool = false;
	public static var isStreMInited:Bool = false;

	public static var data:SaveVariables = null;
	public static var defaultData:SaveVariables = null;

	#if MODS_ALLOWED
	public static var modsOptsSaves:Map<String, Map<String, Dynamic>> = [];
	#end

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
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
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
	public static var defaultKeys:Map<String, Array<FlxKey>> = keyBinds;
	public static function saveSettings() {
		for (key in Reflect.fields(data)) Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
	
		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		if(data == null) data = new SaveVariables();
		if(defaultData == null) defaultData = new SaveVariables();

		for (key in Reflect.fields(data)) {
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key)) {
				var value:Dynamic = Reflect.field(FlxG.save.data, key);
				Reflect.setField(data, key, value);
				if (loadFunctions.exists(key)) loadFunctions.get(key)(value); // Call the load function
			}
		}

		if(FlxG.save.data.gameplaySettings != null) {
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		var save:FlxSave = new FlxSave();
		save.bind('controls', CoolUtil.getSavePath());
		if (save != null) {
			if(save.data.keyboard != null) {
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls) {
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
				}
			}
		}

		FlxSprite.defaultAntialiasing = getPref('Antialiasing');
		#if desktop Discord.check(); #end
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
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
		if (Reflect.hasField(data, name)) return Reflect.field(data, name);
		return defaultValue;
	}
}
