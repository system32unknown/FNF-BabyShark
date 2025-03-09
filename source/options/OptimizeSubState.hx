package options;

class OptimizeSubState extends BaseOptionsMenu {
	var cacheCount:Option;
	public function new() {
		title = Language.getPhrase('optimize_menu', 'Optimizations Settings');
		rpcTitle = 'Optimizations Settings Menu'; // for Discord Rich Presence

		addOption(new Option('Process Notes before Spawning', "If checked, it process notes before they spawn.\nIt boosts game performance vastly.\nIt is recommended to enable this option.", 'processFirst'));
		addOption(new Option('Skip Process for Spawned Note', "If checked, enables Skip Note Function.\nIt boosts game performance vastly, but it only works in specific situations.\nIf you don't understand, enable this.", 'skipSpawnNote'));
		addOption(new Option('Optimize Process for Spawned Note', "If checked, it judges whether or not to do hit process\nimmediately when a note spawned. It boosts game performance vastly,\nbut it only works in specific situations. If you don't understand, enable this.", 'optimizeSpawnNote'));
		addOption(new Option('Update Process for Spawned Note', "", 'updateSpawnNote'));
		addOption(new Option('Show Pop-Up Counter', 'If unchecked, the popup counter wont be shown.', 'showComboCounter'));
		addOption(new Option('Pop-Up Stacking', "If unchecked, score pop-ups won't stack, but the game now uses a recycling system,\nso it doesn't have a huge effect anymore.", 'comboStacking'));
		addOption(new Option('Disable Garbage Collector', "If checked, You can play the main game without GC lag.\nIt only works on loading/playing charts.", 'disableGC'));
		super();
	}
}