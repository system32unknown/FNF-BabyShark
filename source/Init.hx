package;

import flixel.addons.transition.FlxTransitionableState;
import states.FlashingState;
class Init extends flixel.FlxState {
	override function create():Void {
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		Controls.load();
		backend.Highscore.load();

		FlxTransitionableState.skipNextTransOut = true;
		Paths.clearStoredMemory();
		utils.FunkinCache.init();

		#if LUA_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		Language.reloadPhrases();
		#if DISCORD_ALLOWED DiscordClient.prepare(); #end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.cameras.useBufferLocking = true;
		FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;

		#if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end

		if (FlxG.save.data != null) {
			if (FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if (FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		super.create();
		
		if (FlxG.save.data.flashing == null && !FlashingState.leftState) {
			MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
			FlxG.switchState(() -> new FlashingState());
			return;
		}
		
		FlxG.switchState(flixel.util.typeLimit.NextState.fromType(Main.game.initialState));
	}
}