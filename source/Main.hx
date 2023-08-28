package;

import haxe.Exception;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;

import states.TitleState;
import backend.Log;
import utils.system.MemoryUtil;
import utils.GameVersion;
import utils.FunkinGame;
import objects.Overlay;

#if (target.threaded && sys)
import sys.thread.ElasticThreadPool;
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

class Main extends Sprite {
	public static var COMMIT_HASH(get, never):String;
	public static function get_COMMIT_HASH():String {
		return macro.GitCommitMacro.commitHash;
	}
	public static var engineVersion:GameVersion = new GameVersion(0, 1, 1);

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
		Log.init();
		utils.FunkinCache.init();
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		addChild(new FunkinGame(init_game.width, init_game.height, init_game.initialState, init_game.framerate, init_game.framerate, init_game.skipSplash, init_game.startFullscreen));
		addChild(overlayVar = new Overlay());
		
		#if (target.threaded && sys)
		threadPool = new ElasticThreadPool(12, 30);
		#end

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		FlxG.signals.preStateSwitch.add(() -> {Paths.clearStoredCache();});
		FlxG.signals.postStateSwitch.add(() -> {
			Paths.clearUnusedCache();
			MemoryUtil.clearMajor();
			MemoryUtil.clearMajor(true);
			MemoryUtil.clearMajor();
		});
		FlxG.signals.postGameReset.add(states.TitleState.onInit);
		FlxG.signals.gameResized.add((w, h) -> {
			if (FlxG.cameras != null) for (cam in FlxG.cameras.list) {
				@:privateAccess
				if (cam != null && cam._filters != null)
				   	resetSpriteCache(cam.flashSprite);
			}
			if (FlxG.game != null) resetSpriteCache(FlxG.game);
			@:privateAccess FlxG.game.soundTray._defaultScale = (w / FlxG.width) * 2;
	   	});

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if hl hl.Api.setErrorHandler(onCrash); #end
		#end

		#if discord_rpc Discord.start(); #end
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:Dynamic):Void {
		var message:String = "";
		if ((e is UncaughtErrorEvent)) message = e.error;
		else message = try Std.string(e) catch(_:Exception) "Unknown";

		var errMsg:String = "";
		final callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_").replace(":", "'");

		final path = './crash/PsychEngine_$dateNow.txt';

		for (stackItem in callStack) {
			switch (stackItem) {
				case FilePos(_, file, line, _): errMsg += file + " (line " + line + ")\n";
				default: Sys.println(stackItem);
			}
		}

		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n Crash Handler written by: sqirra-rng';

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		CoolUtil.callErrBox("Alter Engine: Error!", errMsg);
		
		#if discord_rpc
		Discord.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
