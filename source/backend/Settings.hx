package backend;

@:structInit
@:publicFields
class SaveVariables {
	var downScroll:Bool = false;
	var middleScroll:Bool = false;
	var opponentStrums:Bool = true;
	var flashing:Null<Bool> = true;
	var autoPause:Bool = true;
	var antialiasing:Bool = true;
	var noteSkin:String = 'Default';
	var splashSkin:String = 'Psych';
	var splashAlpha:Float = .6;
	var splashCount:Int = 2;
	var lowQuality:Bool = false;
	var shaders:Bool = true;
	var framerate:Int = 60;
	var updateStepLimit:Int = 1;
	var camZooms:Bool = true;
	var hideHud:Bool = false;
	var noteOffset:Int = 0;
	var arrowRGBExtra:Array<Array<FlxColor>> = [
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
	var arrowRGBPixelExtra:Array<Array<FlxColor>> = [
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

	var showFPS:Bool = true;
	var memCounterType:String = "MEM/PEAK";
	var rainbowFps:Bool = false;
	var camMovement:Bool = false;
	var ghostTapping:Bool = true;
	var noReset:Bool = false;
	var healthBarAlpha:Float = 1;
	var hitsoundVolume:Float = 0;
	var pauseMusic:String = 'Tea Time';
	var comboStacking:Bool = false;
	var showComboCounter:Bool = false;
	var showNPS:Bool = false;
	var smoothHealth:Bool = false;
	var noteDiffTypes:String = "Simple";
	var accuracyType:String = 'Judgement';
	var iconBopType:String = 'Psych';
	var ratingDisplay:String = 'World';
	var cacheOnGPU:Bool = false;
	var vsync:Bool = false;
	var autoCleanAssets:Bool = true;
	var healthTypes:String = 'Vanilla';
	var timeBarType:String = 'Name Time Position';
	var altDiscordImg:Bool = false;
	var altDiscordImgCount:Int = 0;
	var autoPausePlayState:Bool = true;
	var lightStrum:Bool = true;
	var holdAnim:Bool = true;
	var hitsoundTypes:String = 'Tick';
	var checkForUpdates:Bool = true;
	var skipGhostNotes:Bool = false;
	var ghostRange:Float = .01;
	var unlockedCharacters:Array<String> = ['bf', 'bf-pixel', 'bf-christmas', 'bs', 'bs-pixel', 'alter-holding-bs', 'pico-player', 'nate-player'];
	var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.,
		'scrolltype' => 'multiplicative',

		'songspeed' => 1.,
		'healthgain' => 1.,
		'healthloss' => 1.,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
	];

	var comboOffset:Array<Array<Int>> = [[0, 0], [0, 0]];
	var ratingOffset:Int = 0;

	// Optimizer
	var processFirst:Bool = true;
	var optimizeSpawnNote:Bool = true;
	var skipSpawnNote:Bool = true;
	var disableGC:Bool = false;
	var updateSpawnNote:Bool = false;

	var epicWindow:Int = 22;
	var sickWindow:Int = 45;
	var goodWindow:Int = 90;
	var okWindow:Int = 135;
	var safeFrames:Float = 10;
	var discordRPC:Bool = false;
	var language:String = 'en-US';
}

class Settings {
	public static final default_data:SaveVariables = {};
	public static var data:SaveVariables = {};

	public static function save() {
		for (key in Reflect.fields(data)) {
			// ignores variables with getters
			if (Reflect.hasField(data, 'get_$key')) continue;
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}
		FlxG.save.flush();
	}

	public static function load() {
		FlxG.save.bind('settings', Util.getSavePath());

		final fields:Array<String> = Type.getInstanceFields(SaveVariables);
		for (setting in Reflect.fields(FlxG.save.data)) {
			if (setting == 'gameplaySettings' || !fields.contains(setting)) continue;

			if (Reflect.hasField(data, 'set_$setting')) Reflect.setProperty(data, setting, Reflect.field(FlxG.save.data, setting));
			else Reflect.setField(data, setting, Reflect.field(FlxG.save.data, setting));
		}
		if (FlxG.save.data.gameplaySettings != null) {
			final map:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in map) data.gameplaySettings.set(name, value);
		}

		if (Main.fpsVar != null) {
			Main.fpsVar.visible = data.showFPS;
			Main.fpsVar.memType = data.memCounterType;
		}
		FlxG.autoPause = data.autoPause;

		if (FlxG.save.data.framerate == null) data.framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate * 2, 60, 240));

		// flixel automatically saves your volume!
		FlxG.sound.volume = FlxG.save.data.volume ?? 1;
		FlxG.sound.muted = FlxG.save.data.muted ?? false;

		#if DISCORD_ALLOWED DiscordClient.check(); #end
	}

	public static inline function reset() {
		data = default_data;
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if (!customDefaultValue) defaultValue = default_data.gameplaySettings[name];
		return (data.gameplaySettings.exists(name) ? data.gameplaySettings[name] : defaultValue);
	}
}