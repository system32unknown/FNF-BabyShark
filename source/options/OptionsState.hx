package options;

class OptionsState extends MusicBeatState {
	var options:Array<Array<Dynamic>> = [
		['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals', 'Gameplay'],
		['Saves', 'Miscellaneous', #if TRANSLATIONS_ALLOWED 'Language', #end]
	];
	var grpOptions:FlxTypedGroup<Alphabet>;
	static var curSelected:Int = 0;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors': openSubState(new NotesSubState());
			case 'Controls': openSubState(new ControlsSubState());
			case 'Graphics': openSubState(new GraphicsSettingsSubState());
			case 'Visuals': openSubState(new VisualsSettingsSubState());
			case 'Gameplay': openSubState(new GameplaySettingsSubState());
			case 'Miscellaneous': openSubState(new MiscellaneousSubState());
			case 'Saves': openSubState(new SaveSubState());
			case 'Adjust Delay and Combo': FlxG.switchState(() -> new NoteOffsetState());
			case 'Language': openSubState(new LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var curPage:Int = 0;

	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("Options Menu", null); #end

		PlayState.mania = 8;

		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		add(grpOptions = new FlxTypedGroup<Alphabet>());

		reload();

		add(selectorLeft = new Alphabet(0, 0, '>'));
		add(selectorRight = new Alphabet(0, 0, '<'));

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	function reload(re:Bool = false) {
		if (re) grpOptions.clear();
		for (num => option in options[curPage]) {
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option));
			optionText.screenCenter().y += (92 * (num - (options[curPage].length / 2))) + 45;
			grpOptions.add(optionText);
		}
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if(controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);
		if(controls.UI_LEFT_P || controls.UI_RIGHT_P) changePage(controls.UI_LEFT_P ? -1 : 1);

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState) {
				data.StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(() -> new PlayState());
				FlxG.sound.music.volume = 0;
			} else FlxG.switchState(() -> new states.MainMenuState());
		}

		if (controls.ACCEPT) openSelectedSubstate(options[curPage][curSelected]);
	}
	
	function changeSelection(change:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, options[curPage].length - 1);

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;
			item.alpha = .6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.setPosition(item.x - 63, item.y);
				selectorRight.setPosition(item.x + item.width + 15, item.y);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changePage(change:Int = 0) {
		curPage = FlxMath.wrap(curPage + change, 0, Lambda.count(options) - 1);
		curSelected = 0;
		reload(true);

		for (num => item in grpOptions.members) {
			item.targetY = num - curSelected;

			item.alpha = .6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.setPosition(item.x - 63, item.y);
				selectorRight.setPosition(item.x + item.width + 15, item.y);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy() {
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}