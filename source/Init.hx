package;

import flixel.addons.transition.FlxTransitionableState;
import states.FlashingState;

#if DEBUG_TRACY
import cpp.vm.tracy.TracyProfiler;
import openfl.events.Event;
#end

class Init extends flixel.FlxState {
	override function create():Void {
		#if cpp
		untyped __cpp__("setbuf(stdout, 0)");
		#end

		#if AWARDS_ALLOWED Awards.load(); #end
		Controls.load();
		backend.Highscore.load();
		Settings.load();

		FlxTransitionableState.skipNextTransOut = true;
		Paths.clearStoredMemory();
		utils.FunkinCache.init();

		Mods.pushGlobalMods();
		Mods.loadTopMod();

		Language.reloadPhrases();
		#if DISCORD_ALLOWED DiscordClient.prepare(); #end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;

		if (FlxG.save.data != null) {
			if (FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if (FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		if (Settings.data.flashing && !FlxG.save.data.seenFlashWarning) {
			MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
			FlxG.switchState(() -> new FlashingState());
			return;
		}

		
		#if DEBUG_TRACY
		FlxG.stage.addEventListener(Event.EXIT_FRAME, (e:Event) -> TracyProfiler.frameMark());
		TracyProfiler.setThreadName("main");
		#end

		FlxG.switchState(Main.game.initialState);
	}
}