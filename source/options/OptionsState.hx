package options;

import utils.system.MemoryUtil;
class OptionsState extends MusicBeatState {
	var options:Array<Array<String>> = [
		['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals', 'Gameplay'],
		['Miscellaneous', #if TRANSLATIONS_ALLOWED 'Language', #end 'Optimizations'],
	];
	var grpOptions:FlxTypedGroup<Alphabet>;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch (label) {
			case 'Note Colors': openSubState(new NotesColorSubState());
			case 'Controls': openSubState(new ControlsSubState());
			case 'Graphics': openSubState(new GraphicsSettingsSubState());
			case 'Visuals': openSubState(new VisualsSettingsSubState());
			case 'Gameplay': openSubState(new GameplaySettingsSubState());
			case 'Miscellaneous': openSubState(new MiscellaneousSubState());
			case 'Adjust Delay and Combo': FlxG.switchState(() -> new NoteOffsetState());
			case 'Language': openSubState(new LanguageSubState());
			case 'Optimizations': openSubState(new OptimizeSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var curSelected:Int = 0;
	var curPage:Int = 0;

	var lastMania:Int = 3;
	override function create() {
		#if DISCORD_ALLOWED DiscordClient.changePresence("Options Menu"); #end

		lastMania = PlayState.mania;
		PlayState.mania = 8;

		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.antialiasing = Settings.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.gameCenter();
		add(bg);

		add(grpOptions = new FlxTypedGroup<Alphabet>());
		reload();

		add(selectorLeft = new Alphabet(0, 0, '>'));
		add(selectorRight = new Alphabet(0, 0, '<'));

		changeSelection();
		changePage();
		Settings.save();

		super.create();
	}

	function reload(re:Bool = false) {
		if (re) grpOptions.clear();
		for (num => option in options[curPage]) {
			var optionText:Alphabet = new Alphabet(200, 0, Language.getPhrase('options_$option', option), BOLD, CENTER);
			optionText.gameCenter();
			optionText.y += (92 * (num - (options[curPage].length / 2))) + 45;
			grpOptions.add(optionText);
		}
	}

	override function closeSubState() {
		super.closeSubState();
		Settings.save();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		final upJustPressed:Bool = Controls.justPressed('ui_up');
		if (upJustPressed || Controls.justPressed('ui_down')) changeSelection(upJustPressed ? -1 : 1);
		final leftJustPressed:Bool = Controls.justPressed('ui_left');
		if (leftJustPressed || Controls.justPressed('ui_right')) changePage(leftJustPressed ? -1 : 1);

		if (Controls.justPressed('back')) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState) {
				data.StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(() -> new PlayState());
				FlxG.sound.music.volume = 0;
			} else FlxG.switchState(() -> new states.MainMenuState());
		} else if (Controls.justPressed('accept')) openSelectedSubstate(options[curPage][curSelected]);
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
		curPage = FlxMath.wrap(curPage + change, 0, options.length - 1);
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
		PlayState.mania = lastMania;
		Controls.save();
		Settings.save();
		if (!Settings.data.disableGC && !MemoryUtil.isGcOn) {
			MemoryUtil.enable();
			MemoryUtil.collect(true);
			MemoryUtil.compact();
		}
		super.destroy();
	}
}