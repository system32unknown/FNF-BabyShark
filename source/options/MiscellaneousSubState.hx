package options;

class MiscellaneousSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Miscellaneous';
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		var option:Option = new Option('FPS Counter',
			'If unchecked, hides the FPS Counter.',
			'showFPS', 'bool', true);
		addOption(option);

		var option:Option = new Option('Memory Counter',
			'If unchecked, hides the Memory Counter.',
			'showMEM', 'bool', true);
		addOption(option);

		var option:Option = new Option('Rainbow FPS',
			'', 'RainbowFps',
			'bool', true);
		addOption(option);

		var option:Option = new Option('MS on FPS Counter',
			'', 'MSFPSCounter',
			'bool', true);
		addOption(option);

		var option:Option = new Option('Alternate Discord Large Image',
			'',
			'AltDiscordImg',
			'bool',
			true);
		addOption(option);

		#if desktop
		var option:Option = new Option('Hardware Caching',
			'If checked, the game will use GPU to store images for to maintain MEM usage. ' +
			'Restart the game for to apply changes.' +
			'\n[UNCHECK THIS IF IMAGES ARE NOT SHOWING]',
			'hardwareCache',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Streaming Music',
			'If checked, the game will simultaneously load music data while its playing, this also make looped musics seamlessly loop. ' +
			'Restart the game for to apply changes.' +
			'\n[UNCHECK THIS IF GAME IS CRASHING]',
			'streamMusic',
			'bool',
			false);
		addOption(option);
		#end

		super();
	}
}