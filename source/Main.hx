package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import flixel.input.keyboard.FlxKey;

import states.TitleState;
import backend.Logs;
import utils.system.MemoryUtil;
import utils.GameVersion;
import utils.FunkinGame;
import debug.FPSCounter;

#if (target.threaded && sys) import sys.thread.ElasticThreadPool; #end

class Main extends Sprite {
	public static var engineVer:GameVersion = new GameVersion(0, 1, 0);

	public static var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var current:Main;
	public static var fpsVar:FPSCounter;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public function new() {
		current = this;
		super();
		utils.system.PlatformUtil.setDPIAware();
		setupGame();
	}

	#if (target.threaded && sys)
	public var threadPool:ElasticThreadPool;
	#end

	function setupGame():Void {
		Logs.init();

		addChild(new FunkinGame(game.width, game.height, Init, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		addChild(fpsVar = new FPSCounter());
		
		#if (target.threaded && sys) threadPool = new ElasticThreadPool(12, 30); #end

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		#if CRASH_HANDLER backend.CrashHandler.init(); #end
		#if DISCORD_ALLOWED DiscordClient.prepare(); #end

		FlxG.signals.preStateSwitch.add(() -> Paths.clearStoredCache());
		FlxG.signals.postStateSwitch.add(() -> {
			Paths.clearUnusedCache();

			MemoryUtil.clearMajor();
			MemoryUtil.clearMajor(true);
			MemoryUtil.clearMajor();
		});
		FlxG.signals.gameResized.add((w, h) -> {
			if (FlxG.cameras != null) for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
				   	resetSpriteCache(cam.flashSprite);
			}
			if (FlxG.game != null) resetSpriteCache(FlxG.game);
			@:privateAccess FlxG.game.soundTray._defaultScale = (w / FlxG.width) * 2;
	   	});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		if (sprite == null) return;
		@:privateAccess {
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = sprite.__cacheBitmapData2 = sprite.__cacheBitmapData3 = null;
			sprite.__cacheBitmapColorTransform = null;
		}
	}
}
