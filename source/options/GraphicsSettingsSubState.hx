package options;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'Antialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Shaders',
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.',
			'shaders', 'bool', true);
		addOption(option);
		
		#if desktop
		var option:Option = new Option('Hardware Caching',
			'If checked, the game will use GPU to store images for to maintain MEM usage. ' +
			'Restart the game for to apply changes.' +
			'\n[UNCHECK THIS IF IMAGES ARE NOT SHOWING]',
			'hardwareCache',
			'bool', false);
		addOption(option);
		
		var option:Option = new Option('Streaming Music',
			'If checked, the game will simultaneously load music data while its playing, this also make looped musics seamlessly loop. ' +
			'Restart the game for to apply changes.' +
			'\n[UNCHECK THIS IF GAME IS CRASHING]',
			'streamMusic',
			'bool', false);
		addOption(option);
		#end

		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);
		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		super();
	}

	function onChangeAntiAliasing() {
		for (sprite in members) {
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
				sprite.antialiasing = ClientPrefs.getPref('Antialiasing');
		}
	}

	function onChangeFramerate() {
		if (ClientPrefs.getPref('framerate') > FlxG.drawFramerate)
			FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.getPref('framerate');
		else FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.getPref('framerate');
	}
}