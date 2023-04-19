package;

import flixel.custom.system.CustomLog;
import flixel.FlxG;

import haxe.Exception;

import openfl.Lib;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;

import states.TitleState;
import utils.Controls;
import utils.system.MemoryUtil;
import utils.GameVersion;
import game.FunkinGame;
import ui.Overlay;

import data.api.github.GithubAPI;
import data.api.FunkinInternet;

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

class Main extends Sprite
{
	public static var COMMIT_HASH(default, never):String = GithubAPI.getLatestCommits();
	public static var engineVersion:GameVersion = new GameVersion(0, 1, 0);
	public static var funkinNet:FunkinInternet = new FunkinInternet();

	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1., // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};
	public static var overlayVar:Overlay;

	// You can pretty much ignore everything from here on - your code should go in your states.
	public static function main():Void {
		Lib.current.addChild(new Main());
	}

	public function new() {
		super();
		utils.system.PlatformUtil.setDPIAware();

		stage != null ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}
		setupGame();
	}

	function setupGame():Void {
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;
		if (game.zoom == -1.) {
			game.zoom = Math.min(stageWidth / game.width, stageHeight / game.height);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		CustomLog.init();
		utils.FunkinCache.init();

		Controls.instance = new Controls();
		addChild(new FunkinGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom,#end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		addChild(overlayVar = new Overlay());
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		#if (CRASH_HANDLER && !hl)
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		#if (CRASH_HANDLER && hl)
		hl.Api.setErrorHandler(onCrash);
		#end

		#if discord_rpc
		if (!DiscordClient.isInitialized) {
			DiscordClient.initialize();
			lime.app.Application.current.window.onClose.add(function() {
				DiscordClient.shutdown();
			});
		}
		#end

		FlxG.fixedTimestep = false;
		FlxG.signals.preStateSwitch.add(() -> {
			Paths.clearStoredCache();
		});
		FlxG.signals.postStateSwitch.add(() -> {
			Paths.clearUnusedCache();
			
			MemoryUtil.clearMajor();
			MemoryUtil.clearMajor(true);
			MemoryUtil.clearMajor();
		});
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:Dynamic):Void
	{
		var message:String = "";
		if ((e is UncaughtErrorEvent))
			message = e.error;
		else message = try Std.string(e) catch(_:Exception) "Unknown";

		var errMsg:String = "";
		final callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_").replace(":", "'");

		final path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack) {
			switch (stackItem) {
				case FilePos(_, file, line, _): errMsg += file + " (line " + line + ")\n";
				default: Sys.println(stackItem);
			}
		}

		errMsg += '\nUncaught Error: $message\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng';

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		#if hl
		var flags:haxe.EnumFlags<hl.UI.DialogFlags> = new haxe.EnumFlags<hl.UI.DialogFlags>();
		flags.set(IsError);
		hl.UI.dialog("Alter Engine: Error!", errMsg, flags);
		#else
		lime.app.Application.current.window.alert(errMsg, "Alter Engine: Error!");
		#end
		
		#if discord_rpc
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
