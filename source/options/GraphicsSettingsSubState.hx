package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu {
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new() {
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * .75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = (name:String) -> boyfriend.dance();
		boyfriend.visible = false;

		addOption(new Option('Low Quality', 'If checked, disables some background details,\ndecreases loading times and improves performance.', 'lowQuality', BOOL));

		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.', 'antialiasing', BOOL);
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length - 1;

		addOption(new Option('Shaders', 'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.', 'shaders', BOOL));
		
		#if desktop addOption(new Option('GPU Caching', 'If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon\'t turn this on if you have a shitty Graphics Card.', 'cacheOnGPU', BOOL)); #end

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		var option:Option = new Option('Framerate', "Pretty self explanatory, isn't it?\n(The Default Value is 60 FPS)", 'framerate', INT);
		addOption(option);
		option.minValue = 60;
		option.maxValue = 240;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing() {
		for (sprite in members) {
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
				sprite.antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	function onChangeFramerate() {
		if (ClientPrefs.data.framerate > FlxG.drawFramerate)
			FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;
		else FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;
	}

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change); 
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}