package states.editors;

import utils.system.MemoryUtil;
class MasterEditorMenu extends MusicBeatState {
	var options:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'Stage Editor',
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Note Splash Editor'
	];
	var grpTexts:FlxTypedGroup<Alphabet>;
	var directories:Array<String> = [null];

	var curSelected = 0;
	var curDirectory = 0;
	var directoryTxt:FlxText;

	override function create() {
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED DiscordClient.changePresence("Editors Main Menu"); #end

		if (!ClientPrefs.data.disableGC && !MemoryUtil.isGcOn) {
			MemoryUtil.enable();
			MemoryUtil.collect(true);
			MemoryUtil.compact();
		}

		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		add(grpTexts = new FlxTypedGroup<Alphabet>());

		for (i in 0...options.length) {
			var leText:Alphabet = new Alphabet(90, 320, options[i]);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}
		
		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, FlxColor.BLACK);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories()) directories.push(folder);
		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if (found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
	}

	override function update(elapsed:Float) {
		final upPressed:Bool = Controls.justPressed('ui_up');
		if (upPressed || Controls.justPressed('ui_down')) changeSelection(upPressed ? -1 : 1);
		#if MODS_ALLOWED
		final leftPressed:Bool = Controls.justPressed('ui_left');
		if (leftPressed || Controls.justPressed('ui_right')) changeDirectory(leftPressed ? -1 : 1);
		#end

		if (Controls.justPressed('back')) FlxG.switchState(() -> new states.MainMenuState());

		if (Controls.justPressed('accept')) {
			switch(options[curSelected]) {
				case 'Chart Editor':
					PlayState.chartingMode = true;
					LoadingState.loadAndSwitchState(() -> new ChartingState());
				case 'Character Editor': LoadingState.loadAndSwitchState(() -> new CharacterEditorState(objects.Character.DEFAULT_CHARACTER, false));
				case 'Stage Editor': LoadingState.loadAndSwitchState(() -> new StageEditorState());
				case 'Week Editor': FlxG.switchState(() -> new WeekEditorState());
				case 'Menu Character Editor': FlxG.switchState(() -> new MenuCharacterEditorState());
				case 'Dialogue Editor': LoadingState.loadAndSwitchState(() -> new DialogueEditorState());
				case 'Dialogue Portrait Editor': LoadingState.loadAndSwitchState(() -> new DialogueCharacterEditorState());
				case 'Note Splash Editor': FlxG.switchState(() -> new NoteSplashEditorState());
			}
			FlxG.sound.music.volume = 0;
			states.FreeplayState.destroyFreeplayVocals();
		}
		
		for (num => item in grpTexts.members) {
			item.targetY = num - curSelected;
			item.alpha = .6;
			if (item.targetY == 0) item.alpha = 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory = FlxMath.wrap(curDirectory + change, 0, directories.length - 1);
	
		data.WeekData.setDirectoryFromWeek();
		if (directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< No Mod Directory Loaded >';
		else {
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}