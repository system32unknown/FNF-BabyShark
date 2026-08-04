package;

import states.FlashingState;
import backend.NativeFileSystem;
import utils.FunkinCache;
import utils.WindowUtil;

@:nullSafety
class Init extends flixel.FlxState {
	/**
	 * Simply states whether the "core stuff" is ready or not.
	 * This is used to prevent re-initialization of specific core features.
	 */
	@:noCompletion
	static var _coreInitialized:Bool = false;

	override public function create():Void {
		setup();

		Settings.load();
		flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
		startGame();
	}

	/**
	 * Setup a bunch of important Flixel stuff.
	 */
	function setup():Void {
		if (!_coreInitialized) {
			#if cpp untyped __cpp__("setbuf(stdout, 0)"); #end

			// Setup window events (like callbacks for onWindowClose)
			WindowUtil.initWindowEvents();
			#if DEBUG_TRACY WindowUtil.initTracy(); #end

			FlxG.fixedTimestep = false;
			FlxG.game.soundTray.active = true;
			FlxG.game.focusLostFramerate = 30;
			FlxG.keys.preventDefaultKeys = [TAB];
			FlxG.cameras.useBufferLocking = true;
			FlxG.inputs.resetOnStateSwitch = false;

			#if DISCORD_ALLOWED DiscordClient.prepare(); #end
			utils.plugins.EvacuateDebugPlugin.init();
			FunkinCache.init();

			#if CRASH_HANDLER debug.CrashHandler.init(); #end

			NativeFileSystem.openFlAssets = openfl.Assets.list();
			_coreInitialized = true;
		}

		#if AWARDS_ALLOWED Awards.load(); #end
		Controls.load();
		backend.Highscore.load();

		Paths.clearStoredMemory();
		FunkinCache.instance.clearSecondLayer();

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