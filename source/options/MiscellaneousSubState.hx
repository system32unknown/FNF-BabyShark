package options;

class MiscellaneousSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Miscellaneous';
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		addOption(new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', 'bool'));
		addOption(new Option('Memory Counter', 'If unchecked, hides Memory Counter.', 'showMEM', 'bool'));
		addOption(new Option('Rainbow FPS', '', 'RainbowFps', 'bool'));
		addOption(new Option('More Stats FPS', '', 'FPSStats', 'bool'));
		addOption(new Option('Alternate Discord Large Image', '', 'AltDiscordImg', 'bool'));
		var option:Option = new Option('Alt. Discord Large Images', '', 'AltDiscordImgCount', 'int');
		option.scrollSpeed = 15;
		option.minValue = 0;
		option.maxValue = 5;
		addOption(option);

		var option:Option = new Option('Fullscreen', '', 'fullscreen', 'bool');
		option.onChange = onChangeFullscreen;
		addOption(option);

		super();
	}

	function onChangeFullscreen() FlxG.fullscreen = ClientPrefs.getPref('fullscreen');
}