package options;

class OptimizeSubState extends BaseOptionsMenu {
	var cacheCount:Option;
	public function new() {
		title = Language.getPhrase('optimize_menu', 'Optimizations Settings');
		rpcTitle = 'Optimizations Settings Menu'; // for Discord Rich Presence

		addOption(new Option('Process Notes before Spawning', "If checked, the game processes notes before spawning any.\nIt boosts game performance massively.\nIt is recommended to enable this option.", 'processFirst'));
		addOption(new Option('Note Skipping', "If checked, the game can skip notes.\nIt boosts game performance massively, but only in specific scenarios.\nIf you don't understand, enable this.", 'skipSpawnNote'));
		addOption(new Option('Insta-Check Spawned Notes', "If checked, it judges whether or not to do hit logic\nimmediately after a note is spawned. It boosts game performance massively,\nbut only in specific scenarios. If you don't understand, enable this.", 'optimizeSpawnNote'));
		addOption(new Option('Update Process for Spawned Note', "If checked, the game runs update logic on notes immediately after spawning.\nIt boosts game performance in specific scenarios.\nIf you don't understand, enable this.", 'updateSpawnNote'));
		addOption(new Option('Disable Garbage Collector', "If checked, You can play the main game without GC lag.\nIt only works on loading/playing charts.", 'disableGC'));
		super();
	}
}