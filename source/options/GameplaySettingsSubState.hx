package options;

class GameplaySettingsSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('gameplay_menu', 'Gameplay Settings');
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		addOption(new Option('Downscroll', 'If checked, notes go Down instead of Up, simple enough.', 'downScroll', BOOL));
		addOption(new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll', BOOL));

		addOption(new Option('Note Diff Type:', '', 'noteDiffTypes', STRING, ['Psych', 'Simple']));
		addOption(new Option('Accuracy Type:', "The way accuracy is calculated. \nNote = Depending on if a note is hit or not.\nJudgement = Depending on Judgement.\nMillisecond = Depending on milliseconds.", 'accuracyType', STRING, ['Note', 'Judgement', 'Millisecond']));

		addOption(new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums', BOOL));
		addOption(new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.", 'ghostTapping', BOOL));

		var option:Option = new Option('Auto Pause', "If checked, the game automatically pauses if the screen isn't on focus.", 'autoPause', BOOL);
		addOption(option);
		option.onChange = () -> FlxG.autoPause = ClientPrefs.data.autoPause;
		addOption(new Option('Auto Pause Playstate', "If checked, in playstate, gameplay and notes will pause if it's unfocused.", 'autoPausePlayState', BOOL));

		addOption(new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset', BOOL));
		addOption(new Option('Dynamic Camera Movement', "If unchecked, \nthe camera won't move in the direction in which the characters sing.", 'camMovement', BOOL));

		var option:Option = new Option('Hitsound Type:', "What should the hitsounds like?", 'hitsoundTypes', STRING, ['Tick', 'Snap', 'Dave']);
		addOption(option);
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Hitsound Volume', 'Funny notes does \"Tick!\" when you hit them.', 'hitsoundVolume', PERCENT);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = .0;
		option.maxValue = 1;
		option.changeValue = .1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		addOption(new Option('Update Cam Section', 'If checked, camera will always update,\nwhich makes the camera more precise.', 'updateCamSection', BOOL));

		var option:Option = new Option('Rating Offset', 'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.', 'ratingOffset', INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Epic Hit Window', 'Changes the amount of time you have\nfor hitting a "Epic!" in milliseconds.', 'epicWindow', INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 1;
		option.maxValue = 15;
		addOption(option);
		
		var option:Option = new Option('Sick Hit Window', 'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.', 'sickWindow', INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window', 'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.', 'goodWindow', INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Ok Hit Window', 'Changes the amount of time you have\nfor hitting a "Ok" in milliseconds.', 'okWindow', INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames', 'Changes how many frames you have for\nhitting a note earlier or late.', 'safeFrames', FLOAT);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		super();
	}

	function onChangeHitsoundVolume() FlxG.sound.play(Paths.sound('hitsounds/${Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase()}'), ClientPrefs.data.hitsoundVolume);
}