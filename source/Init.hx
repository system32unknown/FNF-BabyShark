package;

class Init extends flixel.FlxState {
	override function create():Void {
		FlxTransitionableState.skipNextTransOut = true;
		Paths.clearStoredMemory();
		utils.FunkinCache.init();

		#if LUA_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();
		Language.reloadPhrases();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.cameras.useBufferLocking = true;
		FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;

		#if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		backend.Highscore.load();

		if(FlxG.save.data != null) {
			if(FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if(FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}
		
		FlxG.switchState(Type.createInstance(Main.game.initialState, []));
	}
}