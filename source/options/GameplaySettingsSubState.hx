package options;

import flixel.FlxG;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Downscroll',
			'If checked, notes go Down instead of Up, simple enough.',
			'downScroll',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Antimash',
			"If unchecked, antimash will not do anything.",
			'AntiMash',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Hitsound Type',
			"What should the hitsounds like?",
			'hitsoundTypes',
			'string',
			'Psych',
			['Tick', 'Snap', 'DaveAndBambi']);
		addOption(option);
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them.',
			'hitsoundVolume',
			'percent',
			0);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Enable Cutscenes', '',
			'EnableCutScene',
		'bool', true);
		addOption(option);

		var option:Option = new Option('Note Diff Type:',
			'Choose the type of Note Diffs.',
			'NoteDiffTypes',
			'string',
			'Simple',
			['Psych', 'Simple']);
		addOption(option);
		
		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Epic! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Epic!" in milliseconds.',
			'epicWindow',
			'int',
			10);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 1;
		option.maxValue = 10;
		addOption(option);
		
		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float',
			10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		super();
	}

	function onChangeHitsoundVolume() {
		FlxG.sound.play(Paths.sound('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}'), ClientPrefs.getPref('hitsoundVolume'));
	}
}