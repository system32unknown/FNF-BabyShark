package;

import flixel.addons.transition.FlxTransitionableState;
import states.FlashingState;

// THIS IS FOR INITIALIZING STUFF BECAUSE FLIXEL HATES INITIALIZING STUFF IN MAIN
// GO TO MAIN FOR GLOBAL PROJECT/OPENFL STUFF
class Init extends flixel.FlxState {
	override function create():Void {
		FlxTransitionableState.skipNextTransOut = true;
		Paths.clearStoredMemory();

		@:privateAccess FlxG.game.getTimer = Main.getTimer;
		utils.FunkinCache.init();
		#if VIDEOS_ALLOWED hxvlc.util.Handle.init(); #end

		#if LUA_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();
		Language.reloadPhrases();
		backend.ColorBlindness.setFilter();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;

		#if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		backend.Highscore.load();

		if(FlxG.save.data != null) {
			if(FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if(FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		
		super.create();
		
		if (debug.Argument.parse(Sys.args())) return;
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(() -> new FlashingState());
		} else FlxG.switchState(Type.createInstance(Main.game.initialState, []));
	}
}