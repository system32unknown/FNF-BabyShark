package backend;

@:structInit class SaveVariables {
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = .6;
	public var splashCount:Int = 2;
	public var splashOpponent:Bool = false;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var noteOffset:Int = 0;
	public var arrowRGBExtra:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
		[0xFF999999, 0xFFFFFFFF, 0xFF201E31],
		[0xFFFFFF00, 0xFFFFFFFF, 0xFF993300],
		[0xFF8b4aff, 0xFFFFFFFF, 0xFF3b177d],
		[0xFFFF0000, 0xFFFFFFFF, 0xFF660000],
		[0xFF0033ff, 0xFFFFFFFF, 0xFF000066]
	];
	public var arrowRGBPixelExtra:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000],
		[0xFFb6b6b6, 0xFFFFFFFF, 0xFF444444],
		[0xFFffd94a, 0xFFfffff9, 0xFF663500],
		[0xFFB055BC, 0xFFf4f4ff, 0xFF4D0060],
		[0xFFdf3e23, 0xFFffe6e9, 0xFF440000],
		[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D]
	];

	public var showFPS:Bool = false;
	public var memCounterType:String = "MEM/PEAK";
	public var rainbowFps:Bool = false;
	public var camMovement:Bool = true;
	public var ghostTapping:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var comboStacking:Bool = false;
	public var showComboCounter:Bool = false;
	public var showNPS:Bool = false;
	public var smoothHealth:Bool = false;
	public var noteDiffTypes:String = "Simple";
	public var accuracyType:String = 'Judgement';
	public var iconBounceType:String = 'Psych';
	public var ratingDisplay:String = 'World';
	public var useEpics:Bool = true;
	public var cacheOnGPU:Bool = false;
	public var healthTypes:String = 'Vanilla';
	public var timeBarType:String = 'Name Time Position';
	public var altDiscordImg:Bool = false;
	public var altDiscordImgCount:Int = 0;
	public var autoPausePlayState:Bool = true;
	public var lightStrum:Bool = true;
	public var hitsoundTypes:String = 'Tick';
	public var checkForUpdates:Bool = true;
	public var skipGhostNotes:Bool = false;
	public var unlockedCharacters:Array<String> = ['bf', 'bf-pixel', 'bf-christmas', 'bs', 'bs-pixel', 'alter-holding-bs', 'pico-player', 'nate-player'];
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.,
		'scrolltype' => 'multiplicative',

		'songspeed' => 1.,
		'healthgain' => 1.,
		'healthloss' => 1.,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
	];

	public var comboOffset:Array<Array<Int>> = [[0, 0], [0, 0]];
	public var ratingOffset:Int = 0;

	// Optimizer
	public var processFirst:Bool = false;
	public var showNotes:Bool = true;

	public var botPlayPlace:String = "Near the Health Bar";

	public var epicWindow:Int = 22;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var okWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var discordRPC:Bool = false;
	public var language:String = 'en-US';
}

class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	public static function save() {
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();
	}

	public static function load() {
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
		
		if(Main.fpsVar != null) {
			Main.fpsVar.visible = data.showFPS;
			Main.fpsVar.memType = data.memCounterType;
		}
		FlxG.autoPause = data.autoPause;

		if(FlxG.save.data.framerate == null)
			data.framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 60, 240));
		if(data.framerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		} else {
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(FlxG.save.data.gameplaySettings != null) {
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap) data.gameplaySettings.set(name, value);
		}

		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
		if(FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	public static inline function reset() {
		data = defaultData;
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}
}