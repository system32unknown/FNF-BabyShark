package options;

class OptimizeSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('optimize_menu', 'Optimize Settings');
		rpcTitle = 'Optimize Settings Menu'; //for Discord Rich Presence

		addOption(new Option('Show Notes', "If unchecked, appearTime sets to 0. All notes will process by skipped notes.\nalso It forces to turn on botplay.", 'showNotes'));
		addOption(new Option('Do Note Process before Spawning Notes', "Well, It's literally, yes.\nIt boosts game perfomance vastly, It works anytime yeah.\nIf you don't get it, enable this.", 'processFirst'));
        addOption(new Option('Light Strums', '', 'lightStrum'));
        addOption(new Option('Show Combo Counter', 'If checked, the combo counter will be shown.', 'showComboCounter'));

        super();
    }
}