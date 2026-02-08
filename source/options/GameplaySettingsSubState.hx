package options;

import utils.MathUtil;
class GameplaySettingsSubState extends BaseOptionsMenu {
	var stepRate:Option;
	var ghostRate:Option;
	var hitVolume:Option;
	var rateHold:Float;

	public static final defaultBPM:Float = 15;
	public function new() {
		title = Language.getPhrase('gameplay_menu', 'Gameplay Settings');
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		addOption(new Option('Downscroll', 'If checked, notes go Down instead of Up, simple enough.', 'downScroll'));
		addOption(new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll'));
		addOption(new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums'));

		addOption(new Option('Note Diff Type:', '', 'noteDiffTypes', STRING, ['Psych', 'Simple']));
		addOption(new Option('Accuracy Type:', "The way accuracy is calculated. \nNote = Depending on if a note is hit or not.\nJudgement = Depending on Judgement.\nMillisecond = Depending on milliseconds.", 'accuracyType', STRING, ['Note', 'Judgement', 'Millisecond']));

		var option:Option = new Option('Update Count of stepHit:', 'In this setting, you can set the stepHit to be accurate up to ${Settings.data.updateStepLimit != 0 ? Std.string(Settings.data.updateStepLimit * defaultBPM * Settings.data.framerate) : "Infinite"} BPM.', 'updateStepLimit', INT);
		option.scrollSpeed = 20;
		option.minValue = 0;
		option.maxValue = 1000;
		option.decimals = 0;
		option.onChange = () -> {
			stepRate.scrollSpeed = MathUtil.interpolate(20., 1000., (holdTime - .5) / 3., 3.);
			descText.text = stepRate.description = 'In this settings, you can set the stepHit to be accurate up to ${stepRate.getValue() != 0 ? Std.string(stepRate.getValue() * defaultBPM * Settings.data.framerate) : "Infinite"} BPM.';
		}
		addOption(option);
		stepRate = option;
		addOption(new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.", 'ghostTapping'));

		addOption(new Option('Remove Overlapped Notes', "If checked, the game will remove notes which are hidden behind the others.\nRange is controlled by the option below.", 'skipGhostNotes'));
		var option:Option = new Option(' - Threshold:', "Threshold of the option above.\nYou can set it in millisecond.", 'ghostRange', FLOAT);
		option.displayFormat = '%v ms';
		option.scrollSpeed = .1;
		option.minValue = .001;
		option.maxValue = 1000;
		option.changeValue = .001;
		option.decimals = 3;
		addOption(option);
		option.onChange = () -> ghostRate.scrollSpeed = MathUtil.interpolate(.1, 1000., (holdTime - .5) / 8., 5.);
		ghostRate = option;

		var option:Option = new Option('Auto Pause', "If checked, the game automatically pauses if the screen isn't on focus.", 'autoPause');
		addOption(option);
		option.onChange = () -> FlxG.autoPause = Settings.data.autoPause;
		addOption(new Option('Auto Pause Playstate', "If checked, in playstate, gameplay and notes will pause if it's unfocused.", 'autoPausePlayState'));

		addOption(new Option('Remove Epic Judgement', "If checked, removes the Perfect judgement.", 'noEpic'));

		addOption(new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset'));
		addOption(new Option('Dynamic Camera Movement', "If unchecked, \nthe camera won't move in the direction in which the characters sing.", 'camMovement'));

		var option:Option = new Option('Hitsound Type:', "What should the hitsounds like?", 'hitsoundTypes', STRING, ['Tick', 'Snap', 'Dave']);
		addOption(option);
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Hitsound Volume', 'Funny notes do a \"Tick!\" when you hit them.', 'hitsoundVolume', PERCENT);
		addOption(option);
		option.scrollSpeed = 1;
		option.minValue = .0;
		option.maxValue = 1;
		option.changeValue = .01;
		option.decimals = 2;
		option.onChange = onChangeHitsoundVolume;
		hitVolume = option;

		var option:Option = new Option('Rating Offset', 'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.', 'ratingOffset', INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		if (!Settings.data.noEpic) {
			var option:Option = new Option('Epic Hit Window', 'Changes the amount of time you have\nfor hitting a "Epic!" in milliseconds.', 'epicWindow', INT);
			option.displayFormat = '%vms';
			option.scrollSpeed = 15;
			option.minValue = 15;
			option.maxValue = 22;
			addOption(option);
		}
		
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

	function onChangeHitsoundVolume():Void {
		if (holdTime - rateHold > .05 || holdTime <= .5) {
			rateHold = holdTime;
			FlxG.sound.play(Paths.sound('hitsounds/${Std.string(Settings.data.hitsoundTypes).toLowerCase()}'), hitVolume.getValue());
		}
	}
}