package options;

class VisualsUISubState extends BaseOptionsMenu {
	var changedMusic:Bool = false;
	public function new() {
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Splashes', "Set the alpha for the Note Splashes, usually shown when hitting \"Sick!\" notes.", 'splashOpacity', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		addOption(new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool'));
		addOption(new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string', ['Time Left', 'Time Elapsed', 'Song Name', 'Time Position', 'Name Left', 'Name Elapsed', 'Name Time Position', 'Name Percent', 'Disabled']));
		addOption(new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool'));
		addOption(new Option('Icon Bounce:', "What should the Icon Bounces?", 'IconBounceType', 'string', ['Old', 'Psych', 'Dave', 'GoldenApple', 'Custom']));
		addOption(new Option('Health Bar Type:', "What should the Health Bar Types?", 'HealthTypes', 'string', ['Vanilla', 'Psych']));
		addOption(new Option('Smooth Health', '', 'SmoothHealth', 'bool'));
		addOption(new Option('Rating Display:', 'Choose the type of rating you want to see.', 'RatingDisplay', 'string', ['Hud', 'World']));
		addOption(new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool'));
		addOption(new Option('Show Combo Counter', 'If checked, the combo counter will be shown.', 'ShowComboCounter', 'bool'));
		addOption(new Option('Show ms Timing', 'If checked, the ms timing will be shown.', 'ShowMsTiming', 'bool'));
		addOption(new Option('Show Late/Early', 'If checked, the Late/Early counter will be shown.', 'ShowLateEarly', 'bool'));
		addOption(new Option('Show NPS Display', 'If checked, Shows your current Notes Per Second on the info bar.', 'ShowNPS', 'bool'));
		addOption(new Option('Show Judgements Counter', 'If checked, the Judgements counter will be shown.', 'ShowJudgement', 'bool'));

		#if desktop addOption(new Option('Discord Rich Presence', "Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', 'bool')); #end
		addOption(new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', 'bool'));
		addOption(new Option('Show Keybinds on Start Song', "If checked, your keybinds will be shown on the strum that they correspond to when you start a song.", 'showKeybindsOnStart', 'bool'));

		var option:Option = new Option('Health Bar Opacity', 'How much opacity should the health bar and icons be.', 'healthBarAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		var option:Option = new Option('Pause Screen Song:', "What song do you prefer for the Pause Screen?", 'pauseMusic', 'string', ['None', 'Breakfast', 'Tea Time', 'Breakfast Dave']);
		addOption(option);
		option.onChange = () -> {
			if(ClientPrefs.getPref('pauseMusic') == 'None') FlxG.sound.music.volume = 0;
			else FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))));
	
			changedMusic = true;
		};

		super();
	}

	override function destroy() {
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		super.destroy();
	}
}