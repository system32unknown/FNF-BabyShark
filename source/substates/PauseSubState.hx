package substates;

import flixel.addons.transition.FlxTransitionableState;
import options.OptionsState;

#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

class PauseSubState extends MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Mod Settings', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	public static var songName:String = '';

	override function create() {
		if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

		if(PlayState.chartingMode) {
			menuItemsOG.insert(2, 'Leave Charting Mode');
			
			var num:Int = 0;
			if(!PlayState.instance.startingSong) {
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			difficultyChoices.push('' + Difficulty.getString(i));
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();

		#if (target.threaded)
		var mutex:Mutex = new Mutex();

		Thread.create(() -> {
			mutex.acquire();
			try {
				if (songName == null || songName.toLowerCase() != 'none') {
					if(songName == null) {
						var path:String = Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'));
						if(path.toLowerCase() != 'none')
							pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))), true, true);
					} else pauseMusic.loadEmbedded(Paths.music(songName), true, true);
				}
			} catch(e:Dynamic) Logs.trace(e, ERROR);
			pauseMusic.volume = 0;
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
			FlxG.sound.list.add(pauseMusic);
			mutex.release();
		});
		#else
		try {
			if (songName == null || songName.toLowerCase() != 'none') {
				if(songName == null) {
					var path:String = Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'));
					if(path.toLowerCase() != 'none')
						pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))), true, true);
				} else pauseMusic.loadEmbedded(Paths.music(songName), true, true);
			}
		} catch(e:Dynamic) Logs.trace(e, ERROR);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);
		#end

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		var levelDifficulty:FlxText = new FlxText(20, 15, 0, Difficulty.getString().toUpperCase(), 32);
		var failTxt:FlxText = new FlxText(20, 15, 0, 'Fails: ${PlayState.deathCounter}', 32);
		var chartingText:FlxText = new FlxText(20, 15, 0, "CHARTING MODE", 32);
		practiceText = new FlxText(20, 15, 0, "PRACTICE MODE", 32);

		for(k => label in [levelInfo, levelDifficulty, failTxt, chartingText, practiceText]) {
			label.scrollFactor.set();
			label.setFormat(Paths.font('babyshark.ttf'), 32);
			label.updateHitbox();
			label.alpha = 0;
			label.setPosition(FlxG.width - (label.width + 20), 15 + (32 * k));
			FlxTween.tween(label, {alpha: 1, y: label.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: .3 * (k + 1)});
			add(label);
		}
		chartingText.visible = PlayState.chartingMode;
		practiceText.visible = PlayState.instance.practiceMode;
		FlxTween.tween(bg, {alpha: .2}, .4, {ease: FlxEase.quartInOut});

		add(grpMenuShit = new FlxTypedGroup<Alphabet>());

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float) {
		cantUnpause -= elapsed;
		if (pauseMusic != null && pauseMusic.volume < .5)
			pauseMusic.volume += .01 * elapsed;

		super.update(elapsed);
		
		if(controls.BACK) {
			close();
			return;
		}
		
		updateSkipTextStuff();
		if (controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);

		var daSelected:String = menuItems[curSelected];
		switch (daSelected) {
			case 'Skip Time':
				if (controls.UI_LEFT_P) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
					if(holdTime > .5) curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					if(holdTime > .5 && FlxG.sound.music.length >= 600000) curTime += 150000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					if(holdTime > .5 && FlxG.sound.music.length >= 3600000) curTime += 450000 * elapsed * (controls.UI_LEFT ? -1 : 1);

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (controls.ACCEPT && cantUnpause <= 0) {
			if (menuItems == difficultyChoices) {
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.song;
					PlayState.SONG = backend.Song.loadFromJson(backend.Highscore.formatSong(name, curSelected), name);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
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
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
				case "Restart Song": restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition) {
						PlayState.startOnTime = curTime;
						restartSong(true);
					} else {
						if (curTime != Conductor.songPosition) {
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Mod Settings': // Custom
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					MusicBeatState.switchState(new states.ModsMenuState());
					if(ClientPrefs.getPref('pauseMusic') != 'None') {
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))), pauseMusic.volume);
						FlxG.sound.music.fadeIn(.8, pauseMusic.volume, 1);
						FlxG.sound.music.time = pauseMusic.time;
					}
					states.ModsMenuState.onPlayState = true;
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					MusicBeatState.switchState(new OptionsState());
					if(ClientPrefs.getPref('pauseMusic') != 'None') {
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic'))), pauseMusic.volume);
						FlxG.sound.music.fadeIn(.8, pauseMusic.volume, 1);
						FlxG.sound.music.time = pauseMusic.time;
						pauseMusic.stop();
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					Mods.loadTopMod();
					MusicBeatState.switchState(PlayState.isStoryMode ? new states.StoryMenuState() : new states.FreeplayState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	function deleteSkipTimeText() {
		if(skipTimeText != null) {
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false) {
		PlayState.restarted = true;
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans) {
			FlxTransitionableState.skipNextTransOut = true;
			FlxTransitionableState.skipNextTransIn = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy() {
		if (pauseMusic != null) pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void {
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var bullShit:Int = 0;
		for (item in grpMenuShit.members) {
			item.targetY = bullShit++ - curSelected;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;

				if(item == skipTimeTracker) {
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
	}

	function regenMenu():Void {
		for (_ in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time') {
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
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.setPosition(skipTimeTracker.x + skipTimeTracker.width + 60, skipTimeTracker.y);
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText() {
		skipTimeText.text = '${CoolUtil.formatTime(Math.floor(curTime / 1000))} / ${CoolUtil.formatTime(Math.floor(FlxG.sound.music.length / 1000))}';
	}
}
