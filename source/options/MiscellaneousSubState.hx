package options;

import flixel.FlxG;

using StringTools;

class MiscellaneousSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Miscellaneous';
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		var option:Option = new Option('FPS Counter',
			'If unchecked, hides the FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Memory Counter',
			'If unchecked, hides the Memory Counter.',
			'showMEM',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Watermarks',
			"If checked, enables all watermarks from the engine.",
			'ShowWatermark',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Dynamic Camera Movement',
			"If unchecked, \nthe camera won't move in the direction in which the characters sing.",
			'camMovement', 
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Always convert non-EK charts',
			'If unchecked, charts that are not EK will be converted.',
			'convertEK',
			'bool',
			true);
		addOption(option);

		super();
	}
}