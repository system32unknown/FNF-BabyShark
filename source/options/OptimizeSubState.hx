package options;

class OptimizeSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('optimize_menu', 'Optimize Settings');
		rpcTitle = 'Optimize Settings Menu'; //for Discord Rich Presence

		addOption(new Option('Do Note Process before Spawning Notes', "Well, It's literally, yes.\nIt boosts game perfomance vastly, It works anytime yeah.\nIf you don't get it, enable this.", 'processFirst'));
		addOption(new Option('Skip Process for Spawned Note', "If checked, enables Skip Note Function.\nIt boosts game perfomance vastly, but it effects at limited scene.\nIf you don't get it, enable this.", 'skipSpawnNote'));
		addOption(new Option('Optimize Process for Spawned Note', "If checked, It judges whether or not to do hit process\nimmediately when a note spawned. If you don't get it, enable this.", 'optimizeSpawnNote'));
		addOption(new Option('Show Popup Counter', 'If unchecked, the popup counter wont be shown.', 'showComboCounter'));
		addOption(new Option('Popup Stacking', "If unchecked, The popup won't stack. but it's using recycling system,\nso it doesn't have effects so much.", 'comboStacking'));
		addOption(new Option('Better Recycling', "If checked, It uses NoteGroup's recycle system.\nIt boosts game perfomance vastly, It works anytime yeah.", 'betterRecycle'));

		var option:Option = new Option('Cache Notes:', "Enables recycling of a specified number of items before playing.\nIt cuts time of newing instances. 0 is for disabled.\nIt needs RAM depending this value.", 'cacheNotes', INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.decimals = 0;
		option.onChange = onChangeCount;
		cacheCount = option;
		addOption(option);
		addOption(new Option('Disable Garbage Collector', "If checked, You can play the main game without GC lag.\nIt's only works while load & playing chart.", 'disableGC'));
        super();
    }
}