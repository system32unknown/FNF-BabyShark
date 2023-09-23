package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu {
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new() {
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = (name:String) -> boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'Antialiasing',
			'bool');
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length - 1;

		var option:Option = new Option('Shaders',
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.',
			'shaders', 'bool');
		addOption(option);
		
		#if desktop
		var option:Option = new Option('Hardware Caching',
			'If checked, the game will use GPU to store images for to maintain MEM usage. ' +
			'Restart the game for to apply changes.' +
			'\n[UNCHECK THIS IF IMAGES ARE NOT SHOWING]',
			'hardwareCache', 'bool');
		addOption(option);
		
		var option:Option = new Option('Streaming Music',
			'If checked, the game will simultaneously load music data while its playing, this also make looped musics seamlessly loop. ' +
			'Restart the game for to apply changes.' +
			'\n[UNCHECK THIS IF GAME IS CRASHING]',
			'streamMusic', 'bool');
		addOption(option);
		#end

		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate', 'int');
		addOption(option);
		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		super();
		insert(1, boyfriend);
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

	override function changeSelection(change:Int = 0){
		super.changeSelection(change); 
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}