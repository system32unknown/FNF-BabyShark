package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;

import states.TitleState;
import backend.Logs;
import utils.system.MemoryUtil;
import utils.GameVersion;
import utils.FunkinGame;
import objects.Overlay;

#if (target.threaded && sys) import sys.thread.ElasticThreadPool; #end

class Main extends Sprite {
	public static var engineVer:GameVersion = new GameVersion(0, 1, 0);

	var init_game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var current:Main;
	public static var overlayVar:Overlay;

	public static function main():Void
		Lib.current.addChild(new Main());

	public function new() {
		current = this;
		super();
		utils.system.PlatformUtil.setDPIAware();
		stage != null ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	#if (target.threaded && sys)
	public var threadPool:ElasticThreadPool;
	#end

	function setupGame():Void {
		Logs.init();
		utils.FunkinCache.init();
		#if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		addChild(new FunkinGame(init_game.width, init_game.height, init_game.initialState, init_game.framerate, init_game.framerate, init_game.skipSplash, init_game.startFullscreen));
		addChild(overlayVar = new Overlay());
		
		#if (target.threaded && sys)
		threadPool = new ElasticThreadPool(12, 30);
		#end

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		FlxG.signals.preStateSwitch.add(() -> Paths.clearStoredCache());
		FlxG.signals.postStateSwitch.add(() -> {
			Paths.clearUnusedCache();

			MemoryUtil.clearMajor();
			MemoryUtil.clearMajor(true);
			MemoryUtil.clearMajor();
		});
		FlxG.signals.postGameReset.add(states.TitleState.onInit);
		FlxG.signals.gameResized.add((w, h) ->  {
			if (FlxG.cameras != null) for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
				   	resetSpriteCache(cam.flashSprite);
			}
			if (FlxG.game != null) resetSpriteCache(FlxG.game);
			@:privateAccess FlxG.game.soundTray._defaultScale = (w / FlxG.width) * 2;
	   	});

		#if CRASH_HANDLER backend.CrashHandler.init(); #end
		#if discord_rpc Discord.start(); #end
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
