package options;

class OptimizeSubState extends BaseOptionsMenu {
	var cacheCount:Option;
	public function new() {
		title = Language.getPhrase('optimize_menu', 'Optimizations Settings');
		rpcTitle = 'Optimizations Settings Menu'; //for Discord Rich Presence

		addOption(new Option('Process Notes before Spawning', "If checked, it process notes before they spawn.\nIt boosts game performance vastly.\nIt is recommended to enable this option.", 'processFirst'));
		addOption(new Option('Skip Process for Spawned Note', "If checked, enables Skip Note Function.\nIt boosts game performance vastly, but it only works in specific situations.\nIf you don't understand, enable this.", 'skipSpawnNote'));
		addOption(new Option('Optimize Process for Spawned Note', "If checked, it judges whether or not to do hit process\nimmediately when a note spawned. It boosts game performance vastly,\nbut it only works in specific situations. If you don't understand, enable this.", 'optimizeSpawnNote'));
		addOption(new Option('Show Pop-Up Counter', 'If unchecked, the popup counter wont be shown.', 'showComboCounter'));
		addOption(new Option('Pop-Up Stacking', "If unchecked, score pop-ups won't stack, but the game now uses a recycling system,\nso it doesn't have a huge effect anymore.", 'comboStacking'));

		addOption(new Option('Better Recycling', "If checked, the game will use NoteGroup's recycle system.\nIt boosts game performance massively.", 'betterRecycle'));
		var option:Option = new Option('Cache Notes:', "Enables recycling of a specified number of items before playing.\nIt cuts time of newing instances. To diable, set the value to 0.\nYou need the same amount of RAM as the value chosen.", 'cacheNotes', INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.decimals = 0;
		option.onChange = () -> {
			cacheCount.scrollSpeed = utils.MathUtil.interpolate(30, 50000, (holdTime - .5) / 10, 3);
		};
		cacheCount = option;
		addOption(option);

		addOption(new Option('Disable Garbage Collector', "If checked, You can play the main game without GC lag.\nIt only works on loading/playing charts.", 'disableGC'));
        super();
    }
}