package options;

class VisualsUISubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Splashes',
			"Set the alpha for the Note Splashes, usually shown when hitting \"Sick!\" notes.",
			'splashOpacity', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud', 'bool');
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType', 'string',
			['Time Left', 'Time Elapsed', 'Song Name', 'Time Position', 'Name Left', 'Name Elapsed', 'Name Time Position', 'Name Percent', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing', 'bool');
		addOption(option);

		var option:Option = new Option('Icon Bounce:',
			"What should the Icon Bounces?",
			'IconBounceType', 'string',
			['Vanilla', 'Kade', 'Psych', 'Dave', 'GoldenApple', 'Custom']);
		addOption(option);

		var option:Option = new Option('Health Bar Types:',
			"What should the Health Bar Types?",
			'HealthTypes', 'string', ['Vanilla', 'Psych']);
		addOption(option);

		var option:Option = new Option('Score Styles:',
			"", 'ScoreType',
			'string', ['Alter', 'Kade']);
		addOption(option);

		var option:Option = new Option('Rating Display:',
			'Choose the type of rating you want to see.',
			'RatingDisplay',
			'string', ['Hud', 'World']);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms', 'bool');
		addOption(option);

		var option:Option = new Option('Move \'Misses\' in Judgement Counter',
			'', 'movemissjudge', 'bool');
		addOption(option);

		var option:Option = new Option('Show Combo Counter',
			'If checked, the combo counter will be shown.',
			'ShowCombo', 'bool');
		addOption(option);

		var option:Option = new Option('Show ms Timing',
			'If checked, the ms timing will be shown.',
			'ShowMsTiming', 'bool');
		addOption(option);

		var option:Option = new Option('Show Late/Early',
			'If checked, the Late/Early counter will be shown.',
			'ShowLateEarly', 'bool');
		addOption(option);

		var option:Option = new Option('Show NPS Display',
			'If checked, Shows your current Notes Per Second on the info bar.',
			'ShowNPSCounter', 'bool');
		addOption(option);

		var option:Option = new Option('Show Judgements Counter',
			'If checked, the Judgements counter will be shown.',
			'ShowJudgementCount', 'bool');
		addOption(option);

		#if desktop
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC', 'bool');
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking', 'bool');
		addOption(option);

		var option:Option = new Option('Show Keybinds on Start Song',
			"If checked, your keybinds will be shown on the strum that they correspond to when you start a song.",
			'showKeybindsOnStart', 'bool');
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How much opacity should the health bar and icons be.',
			'healthBarAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic', 'string',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic() {
		if(ClientPrefs.getPref('pauseMusic') == 'None') FlxG.sound.music.volume = 0;
		else FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))));

		changedMusic = true;
	}

	override function destroy() {
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		super.destroy();
	}
}