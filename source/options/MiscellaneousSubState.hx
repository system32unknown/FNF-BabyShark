package options;

class MiscellaneousSubState extends BaseOptionsMenu {
	public function new() {
		title = Language.getPhrase('miscs_menu', 'Miscellaneous Settings');
		rpcTitle = 'Miscellaneous Menu'; //for Discord Rich Presence

		var opt:Option = new Option('Memory Counter:', '', 'memCounterType', STRING, ['MEM', 'MEM/PEAK', 'NONE']);
		addOption(opt);
		opt.onChange = () -> if(Main.fpsVar != null) Main.fpsVar.fpsCounter.memCounterType = ClientPrefs.data.memCounterType;
		
		addOption(new Option('Rainbow FPS', '', 'rainbowFps', BOOL));
		addOption(new Option('Alternate Discord Large Image', '', 'altDiscordImg', BOOL));
		var option:Option = new Option('Alt. Discord Large Images:', '', 'altDiscordImgCount', INT);
		option.scrollSpeed = 15;
		option.minValue = 0;
		option.maxValue = 5;
		addOption(option);

		super();
	}
}