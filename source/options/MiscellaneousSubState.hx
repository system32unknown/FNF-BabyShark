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

		var option:Option = new Option('Rainbow FPS',
			'',
			'RainbowFps',
			'bool',
			true);
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

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
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

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord RPC:',
			'Change Discord Rich Presence',
			'discordRPC',
			'string',
			'Normal',
			['Deactivated', 'Normal', 'Hide Infos']);
		addOption(option);
		option.onChange = onChangeDiscord;
		#end

		super();
	}

	#if DISCORD_ALLOWED
	function onChangeDiscord() {
		DiscordClient.changePresence(rpcTitle, null);
	}
	#end
}