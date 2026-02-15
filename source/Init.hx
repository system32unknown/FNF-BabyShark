package;

import states.FlashingState;
import backend.NativeFileSystem;
#if DEBUG_TRACY
import cpp.vm.tracy.TracyProfiler;
import openfl.events.Event;
#end

@:nullSafety
class Init extends flixel.FlxState {
	/**
	 * Simply states whether the "core stuff" is ready or not.
	 * This is used to prevent re-initialization of specific core features.
	 */
	@:noCompletion
	static var _coreInitialized:Bool = false;

	override function create():Void {
		setupShit();

		flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
		startGame();
	}

	/**
	 * Setup a bunch of important Flixel stuff.
	 */
	function setupShit():Void {
		if (!_coreInitialized) {
			#if cpp untyped __cpp__("setbuf(stdout, 0)"); #end

			#if DEBUG_TRACY
			FlxG.stage.addEventListener(Event.EXIT_FRAME, (e:Event) -> TracyProfiler.frameMark());
			TracyProfiler.setThreadName("main");
			#end

			FlxG.fixedTimestep = false;
			FlxG.game.focusLostFramerate = 60;
			FlxG.keys.preventDefaultKeys = [TAB];
			FlxG.cameras.useBufferLocking = true;
			FlxG.inputs.resetOnStateSwitch = false;

			#if DISCORD_ALLOWED DiscordClient.prepare(); #end
			utils.plugins.EvacuateDebugPlugin.init();

			NativeFileSystem.openFlAssets = openfl.Assets.list();
			#if linux FlxG.signals.preStateCreate.add(state -> NativeFileSystem.excludePaths.resize(0)); #end

			_coreInitialized = true;
		}

		#if AWARDS_ALLOWED Awards.load(); #end
		Controls.load();
		backend.Highscore.load();
		Settings.load();

		Paths.clearStoredMemory();
		utils.FunkinCache.init();

		Mods.pushGlobalMods();
		Mods.loadTopMod();
		
		Language.reloadPhrases();
	}

	/**
	 * Start the game by moving to the title state and play the game as normal.
	 */
	function startGame():Void {
		if (FlxG.save.data != null) {
			if (FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if (FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		if (Settings.data.flashing && !FlxG.save.data.seenFlashWarning) {
			MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
			FlxG.switchState(() -> new FlashingState());
			return;
		}
		FlxG.switchState(Main.game.initialState);
	}
}