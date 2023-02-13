package options;

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

		var option:Option = new Option('Rainbow Fps',
			'',
			'RainbowFps',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Rainbow Fps Speed',
			'',
			'RainbowSpeed',
			'int',
			1);
		addOption(option);
		option.displayFormat = '%v%';
		option.scrollSpeed = 15;
		option.minValue = 1;
		option.maxValue = 20;

		var option:Option = new Option('MS on FPS Counter',
			'',
			'MSFPSCounter',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Enable Week 7 Cutscene', '',
			'week7CutScene',
		'bool', true);
		addOption(option);

		#if cpp
		var option:Option = new Option('MEM Type',
			'',
			'MEMType',
			'string',
			'system',
			['cpp', 'system', 'gc']);
		addOption(option);
		#end

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

		var option:Option = new Option('Alternate Discord Large Image',
			'',
			'AltDiscordImg',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('HaxeFlixel Start up',
			'',
			'FlxStartup',
			'bool',
			true);
		addOption(option);

		super();
	}
}