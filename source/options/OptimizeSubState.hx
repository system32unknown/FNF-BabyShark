package options;

class OptimizeSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('optimize_menu', 'Optimize Settings');
		rpcTitle = 'Optimize Settings Menu'; //for Discord Rich Presence

		addOption(new Option('Do Note Process before Spawning Notes', "Well, It's literally, yes.\nIt boosts game perfomance vastly, It works anytime yeah.\nIf you don't get it, enable this.", 'processFirst'));
		addOption(new Option('Separate Process for Too Slow Note', "If checked, Separate note hit processes for too slow one and not.\nIt boosts game perfomance vastly, but it effects at limited scene.\nIf you don't get it, enable this.", 'separateHitProcess'));
		addOption(new Option('Skip Process for Spawned Note', "If checked, enables Skip Note Function.\nIt boosts game perfomance vastly, but it effects at limited scene.\nIf you don't get it, enable this.", 'skipSpawnNote'));
		addOption(new Option('Optimize Process for Spawned Note', "If checked, It judges whether or not to do hit process\nimmediately when a note spawned. If you don't get it, enable this.", 'optimizeSpawnNote'));
		addOption(new Option('Show Popup Counter', 'If unchecked, the popup counter wont be shown.', 'showComboCounter'));
		addOption(new Option('Popup Stacking', "If unchecked, The popup won't stack. but it's using recycling system,\nso it doesn't have effects so much.", 'comboStacking'));
		addOption(new Option('Disable Garbage Collector', "If checked, You can play the main game without GC lag.\nIt's only works while load & playing chart.", 'disableGC'));
        super();
    }
}