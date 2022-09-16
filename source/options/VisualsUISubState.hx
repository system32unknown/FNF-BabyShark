package options;

import flixel.FlxG;
import utils.ClientPrefs;

using StringTools;

class VisualsUISubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Note Splashes',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'noteSplashes',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			'Time Left',
			['Time Left', 'Time Elapsed', 'Song Name', 'ElapsedPosition', 'LeftPosition', 'NameLeft', 'NameElapsed', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Icon Bounce:',
			"What should the Icon Bounces?",
			'IconBounceType',
			'string',
			'Psych',
			['Vanilla', 'Psych', 'PsychOld', 'Andromeda', 'DaveAndBambi', 'Purgatory', 'Micdup', 'RadicalOne', 'Custom']);
		addOption(option);

		var option:Option = new Option('Health Types:',
			"What should the Health Types?",
			'HealthTypes',
			'string',
			'Psych',
			['Vanilla', 'Psych', 'Exe']);
		addOption(option);

		var option:Option = new Option('Score Styles:',
			"What should change the Score Text?",
			'ScoreTextStyle',
			'string',
			'BabyShark',
			['Kade', 'Psych', 'BabyShark', 'FPSPlus']);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Combo Counter',
			'If checked, the combo counter will be shown.',
			'ShowCombo',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show ms Timing',
			'If checked, the ms timing will be shown.',
			'ShowMsTiming',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Late/Early',
			'If checked, the Late/Early counter will be shown.',
			'ShowLateEarly',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show NPS Display',
			'If checked, Shows your current Notes Per Second on the info bar.',
			'ShowNPSCounter',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Judgements Counter',
			'If checked, the Judgements counter will be shown.\nLike Andromeda Engine.',
			'ShowJudgementCount',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Max Combo',
			'If checked, the Max Combo will be shown.',
			'ShowMaxCombo',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Lane Underlay',
			'If checked, the Lane underlay will be shown.',
			'ShowLU',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Hide Opponent LU',
			'If checked, the Opponent LU will be hidden.',
			'HiddenOppLU',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Lane Underlay Transparency',
			'How transparent your lane is, higher = more visible.',
			'LUAlpha',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'Tea Time',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic() {
		if(ClientPrefs.getPref('pauseMusic') == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))));

		changedMusic = true;
	}

	override function destroy()
	{
		if(changedMusic) FlxG.sound.playMusic(Paths.music('freakyMenu'));
		super.destroy();
	}
}