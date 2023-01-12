package options;

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

		var option:Option = new Option('Rainbow Fps',
			'',
			'RainbowFps',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('MS on FPS Counter',
			'',
			'MSFPSCounter',
			'bool',
			true);
		addOption(option);

		#if cpp
		var option:Option = new Option('MEM Type',
			'',
			'MEMType',
			'string',
			'Time Left',
			['cpp', 'system']);
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

		var option:Option = new Option('Beat Icon In Freeplay',
			'',
			'BeatIconFreeplay',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Haxeflixel Splash',
			'Not implemented. I\'ll figure it later.',
			'showSplash',
			'bool',
			true);
		addOption(option);

		super();
	}
}