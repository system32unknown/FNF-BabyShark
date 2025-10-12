package substates;

import options.OptionsState;
import utils.StringUtil;
import backend.Song;

class PauseSubState extends MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Change Character', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var songName:String = null;
	var pSte:PlayState;

	override function create() {
		pSte = PlayState.instance;
		if (Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!

		if (PlayState.chartingMode) {
			menuItemsOG.insert(2, 'Leave Charting Mode');

			var num:Int = 0;
			if (!pSte.startingSong) {
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		} else if (pSte.practiceMode && !pSte.startingSong)
			menuItemsOG.insert(3, 'Skip Time');
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length)
			difficultyChoices.push(Difficulty.getString(i));
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		try {
			var pauseSong:String = getPauseSong();
			if (pauseSong != null) pauseMusic.load(Paths.music(pauseSong), true, true);
		} catch (e:Dynamic) Logs.error('ERROR PAUSE MUSIC ON LOAD: $e');
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		var levelDifficulty:FlxText = new FlxText(20, 15, 0, Difficulty.getString().toUpperCase(), 32);
		var failTxt:FlxText = new FlxText(20, 15, 0, Language.getPhrase("fails", "Fails: {1}", [PlayState.deathCounter]), 32);
		var chartingText:FlxText = new FlxText(20, 15, 0, Language.getPhrase("Charting Mode").toUpperCase(), 32);
		practiceText = new FlxText(20, 15, 0, Language.getPhrase("Practice Mode").toUpperCase(), 32);

		for (k => label in [levelInfo, levelDifficulty, failTxt, chartingText, practiceText]) {
			label.setFormat(Paths.font('babyshark.ttf'), 32);
			label.updateHitbox();
			label.scrollFactor.set();
			label.alpha = 0;
			label.setPosition(FlxG.width - (label.width + 20), 15 + (32 * k));
			FlxTween.tween(label, {alpha: 1, y: label.y + 5}, .4, {ease: FlxEase.quartInOut, startDelay: .3 * (k + 1)});
			add(label);
		}
		chartingText.visible = PlayState.chartingMode;
		practiceText.visible = pSte.practiceMode;
		FlxTween.tween(bg, {alpha: .2}, .4, {ease: FlxEase.quartInOut});

		add(grpMenuShit = new FlxTypedGroup<Alphabet>());

		missingTextBG = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = .6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	function getPauseSong():String {
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(Settings.data.pauseMusic);
		if (formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = .1;

	override function update(elapsed:Float) {
		cantUnpause -= elapsed;
		if (pauseMusic.volume < .5) pauseMusic.volume += .01 * elapsed;

		super.update(elapsed);

		if (Controls.justPressed('back')) {
			close();
			return;
		}

		if (FlxG.keys.justPressed.F5) {
			MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			FlxG.resetState();
		}

		updateSkipTextStuff();
		final upJustPressed:Bool = Controls.justPressed('ui_up');
		if (upJustPressed || Controls.justPressed('ui_down')) changeSelection(upJustPressed ? -1 : 1);

		var daSelected:String = menuItems[curSelected];
		switch (daSelected) {
			case 'Skip Time':
				if (Controls.justPressed('ui_left')) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				} else if (Controls.justPressed('ui_right')) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				final leftPressed:Bool = Controls.pressed('ui_left');
				if (leftPressed || Controls.pressed('ui_right')) {
					holdTime += elapsed;
					if (holdTime > 0.5)
						curTime += 45000 * elapsed * (leftPressed ? -1 : 1);

					if (curTime >= FlxG.sound.music.length)
						curTime -= FlxG.sound.music.length;
					else if (curTime < 0)
						curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (Controls.justPressed('accept') && cantUnpause <= 0) {
			if (menuItems == difficultyChoices) {
				var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
				var poop:String = Song.format(songLowercase, curSelected);
				try {
					if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
						Song.loadFromJson(poop, songLowercase);
						PlayState.storyDifficulty = curSelected;
						FlxG.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}
				} catch (e:haxe.Exception) {
					var errorStr:String = e.message;
					if (errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1); // Missing chart
					else errorStr += '\n\n' + e.stack;
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.gameCenter(Y);
					missingText.visible = missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					super.update(elapsed);
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected) {
				case "Resume": close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				case 'Change Character': FlxG.switchState(() -> new states.CharacterSelectionState());
				case 'Toggle Practice Mode':
					pSte.practiceMode = !pSte.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = pSte.practiceMode;
				case "Restart Song": restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if (curTime < Conductor.songPosition) {
						PlayState.startOnTime = curTime;
						restartSong(true);
					} else {
						if (curTime != Conductor.songPosition) {
							pSte.clearNotesBefore(curTime);
							pSte.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					pSte.notes.clear();
					pSte.unspawnNotes = [];
					pSte.finishSong(true);
				case 'Toggle Botplay':
					pSte.cpuControlled = !pSte.cpuControlled;
					PlayState.changedDifficulty = true;
					pSte.botplayTxt.visible = pSte.cpuControlled;
					if (pSte.botplayFade) {
						pSte.botplayTxt.alpha = 1;
						pSte.botplaySine = 0;
					}
				case 'Options':
					pSte.paused = true; // For Hscript
					pSte.vocals.volume = 0;
					pSte.canResync = false;
					FlxG.switchState(() -> new OptionsState());
					if (Settings.data.pauseMusic != 'None') {
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(Settings.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, .8);
						FlxG.sound.music.time = pauseMusic.time;

						Conductor.bpm = switch (Settings.data.pauseMusic) {
							case 'Tea Time': 105.0;
							case 'Breakfast': 160.0;
							case 'Breakfast (Pico)': 88.0;
							case 'Breakfast (Dave)': 80.0;
							default: Conductor.bpm;
						}
					} else {
						FlxG.sound.music.resume();
						FlxTween.tween(FlxG.sound.music, {volume: 1}, .8);
						FlxG.sound.music.looped = true;
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					pSte.canResync = false;

					Mods.loadTopMod();
					FlxG.switchState(() -> PlayState.isStoryMode ? new states.StoryMenuState() : new states.FreeplayState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	function deleteSkipTimeText() {
		if (skipTimeText != null) {
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false) {
		var pSte:PlayState = PlayState.instance;
		pSte.paused = true; // For Hscript
		FlxG.sound.music.volume = 0;
		pSte.vocals.volume = 0;

		if (noTrans) MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
		FlxG.resetState();
	}

	override function destroy() {
		pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void {
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		for (num => item in grpMenuShit.members) {
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				if (item == skipTimeTracker) {
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
		missingText.visible = missingTextBG.visible = false;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function regenMenu():Void {
		for (_ in 0...grpMenuShit.members.length) {
			var obj:Alphabet = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (num => str in menuItems) {
			var item:Alphabet = new Alphabet(90, 320, Language.getPhrase('pause_$str', str));
			item.isMenuItem = true;
			item.targetY = num;
			grpMenuShit.add(item);

			if (str == 'Skip Time') {
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("babyshark.ttf"), 64, FlxColor.WHITE, CENTER);
				skipTimeText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
				skipTimeText.scrollFactor.set();
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}

	function updateSkipTextStuff() {
		if (skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.setPosition(skipTimeTracker.x + skipTimeTracker.width + 60, skipTimeTracker.y);
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText() {
		skipTimeText.text = '${StringUtil.formatTime(Math.floor(curTime / 1000))} / ${StringUtil.formatTime(Math.floor(FlxG.sound.music.length / 1000))}';
	}
}