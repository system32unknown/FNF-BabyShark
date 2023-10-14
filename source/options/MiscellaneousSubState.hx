package options;

class MiscellaneousSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Miscellaneous';
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		addOption(new Option('FPS Counter', 'If unchecked, hides the FPS Counter.', 'showFPS', 'bool'));
		addOption(new Option('Memory Counter', 'If unchecked, hides the Memory Counter.', 'showMEM', 'bool'));
		addOption(new Option('Rainbow FPS', '', 'RainbowFps', 'bool'));
		addOption(new Option('More Stats FPS', '', 'FPSStats', 'bool'));
		addOption(new Option('Alternate Discord Large Image', '', 'AltDiscordImg', 'bool'));

		var option:Option = new Option('Fullscreen', '', 'fullscreen', 'bool');
		option.onChange = onChangeFullscreen;
		addOption(option);

		super();
	}

	function onChangeFullscreen() {
		FlxG.fullscreen = ClientPrefs.getPref('fullscreen');
	}
}