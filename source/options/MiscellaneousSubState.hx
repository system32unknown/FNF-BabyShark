package options;

class MiscellaneousSubState extends BaseOptionsMenu {
	public function new() {
		title = 'Miscellaneous';
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		var opt:Option = new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', 'bool');
		addOption(opt);
		opt.onChange = onChangeFPSCounter;
		var opt:Option = new Option('Memory Counter:', '', 'memCounterType', 'string', ['MEM', 'MEM/PEAK', 'NONE']);
		addOption(opt);
		opt.onChange = onChangeFPSCounter;
		
		addOption(new Option('Rainbow FPS:', '', 'RainbowFps', 'bool'));
		addOption(new Option('More Stats FPS', '', 'FPSStats', 'bool'));
		addOption(new Option('Alternate Discord Large Image', '', 'AltDiscordImg', 'bool'));
		var option:Option = new Option('Alt. Discord Large Images:', '', 'AltDiscordImgCount', 'int');
		option.scrollSpeed = 15;
		option.minValue = 0;
		option.maxValue = 5;
		addOption(option);

		super();
	}

	function onChangeFPSCounter() {
		if(Main.fpsVar != null) {
			Main.fpsVar.visible = ClientPrefs.getPref('showFPS');
			Main.fpsVar.memCounterType = ClientPrefs.getPref('memCounterType');
		}
	}
}