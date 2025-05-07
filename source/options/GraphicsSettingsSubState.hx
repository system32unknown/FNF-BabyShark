package options;

import objects.Character;

class GraphicsSettingsSubState extends BaseOptionsMenu {
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	var fpsOption:Option;
	public function new() {
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * .75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.onFinish.add((name:String) -> boyfriend.dance());
		boyfriend.visible = false;

		addOption(new Option('Low Quality', 'If checked, disables some background details,\ndecreases loading times and improves performance.', 'lowQuality'));

		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.', 'antialiasing');
		option.onChange = () -> {
			for (sprite in members) {
				var sprite:FlxSprite = cast sprite;
				if (sprite != null && (sprite is FlxSprite))
					sprite.antialiasing = Settings.data.antialiasing;
			}
		}; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length - 1;

		addOption(new Option('Shaders', 'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.', 'shaders'));
		addOption(new Option('Note Shaders', "If unchecked, disables note shaders.\nPlease use the noteSkin older than psych v0.6.x!", 'noteShaders'));
		#if desktop addOption(new Option('GPU Caching', 'If checked, allows the GPU to be used for caching textures,\ndecreasing RAM usage. Don\'t turn this on if you have a shitty Graphics Card.', 'cacheOnGPU')); #end

		#if sys
		var option:Option = new Option('VSync', 'If checked, it enables VSync, fixing any screen tearing\nat the cost of capping the FPS to screen refresh rate.\n(Restart required)', 'vsync');
		option.onChange = onChangeVSync;
		addOption(option);
		#end

		var option:Option = new Option('Framerate', "Pretty self explanatory, isn't it?", 'framerate', INT);
		addOption(option);
		option.minValue = 10;
		option.maxValue = 1000;
		option.defaultValue = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		fpsOption = option;

		super();
		insert(1, boyfriend);
	}

	function onChangeFramerate() {
		fpsOption.scrollSpeed = utils.MathUtil.interpolate(30, 1000, (holdTime - .5) / 5, 3);
		if (Settings.data.framerate > FlxG.drawFramerate)
			FlxG.updateFramerate = FlxG.drawFramerate = Settings.data.framerate;
		else FlxG.drawFramerate = FlxG.updateFramerate = Settings.data.framerate;
	}

	#if sys
	function onChangeVSync() {
		var file:String = lime.system.System.applicationStorageDirectory + "vsync.txt";
		if (FileSystem.exists(file)) FileSystem.deleteFile(file);
		File.saveContent(file, Std.string(Settings.data.vsync));
	}
	#end

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change); 
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}