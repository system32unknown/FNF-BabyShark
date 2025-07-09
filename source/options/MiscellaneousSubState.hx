package options;

class MiscellaneousSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('miscs_menu', 'Miscellaneous Settings');
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		var opt:Option = new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS');
		addOption(opt);
		opt.onChange = onChangeFPSCounter;

		var opt:Option = new Option('Memory Counter:', 'If you choose none, hides Memory Counter.', 'memCounterType', STRING, ['MEM', 'MEM/PEAK', 'NONE']);
		addOption(opt);
		opt.onChange = onChangeFPSCounter;

		addOption(new Option('Memory Mode:', '', 'memModeType', STRING, ['GC', 'APP']));

		addOption(new Option('Clean Assets When State Switch', 'If checked, unused assets will be automatically removed from memory when switching states.\n[WARNING: THE GAME FREEZE ON SONG LOAD FOR LOW CHANCE.]', 'autoCleanAssets'));

		#if CHECK_FOR_UPDATES addOption(new Option('Check for Updates', 'On Release builds, turn this on to check for updates when you start the game.', 'checkForUpdates')); #end
		#if desktop addOption(new Option('Discord Rich Presence', "Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC')); #end

		super();
	}
}

function onChangeFPSCounter() {
	if (Main.fpsVar == null) return;
	Main.fpsVar.visible = Settings.data.showFPS;
	Main.fpsVar.memDisplayType = Settings.data.memCounterType;
	Main.fpsVar.memType = Settings.data.memModeType;
}