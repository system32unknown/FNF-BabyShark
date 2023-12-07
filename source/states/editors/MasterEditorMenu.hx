package states.editors;

import states.MainMenuState;
import states.FreeplayState;
import data.WeekData;
import objects.Character;

class MasterEditorMenu extends MusicBeatState {
	var options:Array<String> = [
		'Week Editor',
		'Menu Character Editor',
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Character Editor',
		'Chart Editor',
		'Credit Editor'
	];
	var grpTexts:FlxTypedGroup<Alphabet>;
	var directories:Array<String> = [null];

	var curSelected = 0;
	var curDirectory = 0;
	var directoryTxt:FlxText;

	override function create() {
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length) {
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}
		
		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories()) directories.push(folder);
		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);
		#if MODS_ALLOWED if (controls.UI_LEFT_P || controls.UI_RIGHT_P) changeDirectory(controls.UI_LEFT_P ? -1 : 1); #end

		if (controls.BACK) MusicBeatState.switchState(new MainMenuState());

		if (controls.ACCEPT) {
			switch(options[curSelected]) {
				case 'Character Editor': LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false), false);
				case 'Week Editor': MusicBeatState.switchState(new WeekEditorState());
				case 'Menu Character Editor': MusicBeatState.switchState(new MenuCharacterEditorState());
				case 'Dialogue Portrait Editor': LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
				case 'Dialogue Editor' :LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
				case 'Chart Editor':
					PlayState.chartingMode = true;
					LoadingState.loadAndSwitchState(new ChartingState(), false); //felt it would be cool maybe
				case 'Credit Editor': MusicBeatState.switchState(new CreditsEditor());
			}
			FlxG.sound.music.volume = 0;
			#if PRELOAD_ALL
			Conductor.usePlayState = false;
			Conductor.mapBPMChanges(true);
			FreeplayState.destroyFreeplayVocals();
			#end
		}
		
		var bullShit:Int = 0;
		for (item in grpTexts.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory = FlxMath.wrap(curDirectory + change, 0, directories.length - 1);
	
		WeekData.setDirectoryFromWeek();
		if(directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< No Mod Directory Loaded >';
		else {
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}