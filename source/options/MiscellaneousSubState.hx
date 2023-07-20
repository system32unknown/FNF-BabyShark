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

		var option:Option = new Option('More Stats FPS',
			'', 'FPSStats',
			'bool', true);
		addOption(option);

		var option:Option = new Option('Alternate Discord Large Image',
			'',
			'AltDiscordImg',
			'bool',
			true);
		addOption(option);

		super();
	}
}