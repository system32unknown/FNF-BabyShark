package states;

import flixel.util.FlxDestroyUtil;

import data.WeekData;
import utils.FlxInterpolateColor;
import backend.Highscore;
import backend.Song;
import objects.HealthIcon;
import objects.MusicPlayer;
import substates.FreeplaySectionSubstate;

class FreeplayState extends MusicBeatState {
	var songs:Array<SongMetadata> = [];

	static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedcombo:String = '';

	var grpSongs:FlxTypedGroup<Alphabet>;
	var iconArray:Array<HealthIcon> = [];
	var interpColor:FlxInterpolateColor;

	var bg:FlxSprite;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	public static var section:String = '';

	override function create() {		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Freeplay Menu", 'Section: $section'); #end

		section = FreeplaySectionSubstate.daSection;
		if (section == null || section == '') section = 'Vanilla';

		var foundSection = false;
		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (leWeek.section != null) {
				if (leWeek.section != section) foundSection = true;
				else foundSection = false;
			} else foundSection = true;

			if (foundSection) {
				foundSection = false;
				continue;
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs) {
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3) colors = [146, 113, 253];
				addSong(song[0], i, song[1], CoolUtil.getColor(colors));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		add(grpSongs = new FlxTypedGroup<Alphabet>());
		for (i in 0...songs.length) {
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.iconType = 'psych';
			icon.sprTracker = songText;

			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * .7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 90, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, 0, 0, "", 24);
		diffText.y = scoreBG.height - diffText.height + 10;
		diffText.font = scoreText.font;

		comboText = new FlxText(scoreText.x, 0, 0, "", 24);
		comboText.y = scoreBG.height / 2 - 6;
		comboText.font = diffText.font;

		add(diffText);
		add(scoreText);
		add(comboText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = .6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		var leText:String = Language.getPhrase("freeplay_tip", '[SPACE] Listen to the Song • [CTRL] Gameplay Changers Menu • [HOLD TAB] Character Selection\n[COMMA] Change Sections • [RESET] Reset Score and Accuracy');
		bottomString = leText;
		bottomText = new FlxText(0, 0, FlxG.width, leText, 18);
		bottomText.setFormat(Paths.font("babyshark.ttf"), 18, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		bottomText.y = FlxG.height - bottomText.height;
		add(bottomText);

		bottomBG = new FlxSprite().makeGraphic(FlxG.width, Std.int(bottomText.height), 0x7F000000);
		bottomBG.scrollFactor.set();
		bottomBG.y = FlxG.height - bottomBG.height;
		insert(members.indexOf(bottomText), bottomBG);

		add(player = new MusicPlayer(this));

		changeSelection();
		updateTexts();
		interpColor = new FlxInterpolateColor(bg.color);
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int) {
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float) {
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.sound.music.volume < .7) FlxG.sound.music.volume += .5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));
		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= .01) lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(utils.MathUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) ratingSplit.push(''); //No decimals, add an empty space
		while (ratingSplit[1].length < 2) ratingSplit[1] += '0'; //Less than 2 decimals in it, add decimals then
		
		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!player.playingMusic) {
			comboText.text = 'Rating: $intendedcombo';
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			positionHighscore();

			if(songs.length > 1) {
				if(FlxG.keys.justPressed.HOME) {
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				} else if(FlxG.keys.justPressed.END) {
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
	
				if (controls.UI_UP_P || controls.UI_DOWN_P) {
					changeSelection(controls.UI_UP_P ? -shiftMult : shiftMult);
					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP) {
					var checkLastHold:Int = Math.floor((holdTime - .5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - .5) * 10);
					
					if(holdTime > .5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
	
				if (FlxG.mouse.wheel != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
					changeDiff();
				}
			}

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
				changeDiff(controls.UI_LEFT_P ? -1 : 1);
				_updateSongLastDifficulty();
			}
		}

		interpColor.fpsLerpTo(songs[curSelected].color, .0625);
		bg.color = interpColor.color;

		if (controls.BACK) {
			if (player.playingMusic) {
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;
	
				player.playingMusic = false;
				player.switchPlayMusic();
	
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			} else {
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new MainMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic) {
			persistentUpdate = false;
			openSubState(new options.GameplayChangersSubstate());
		} else if(FlxG.keys.justPressed.SPACE) {
			if(instPlaying != curSelected && !player.playingMusic) {
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var songLowercase:String = songs[curSelected].songName.toLowerCase();
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

				if (songLowercase == "enter terminal") return;

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				if (PlayState.SONG.needsVoices) {
					Conductor.usePlayState = true;
					Conductor.mapBPMChanges(PlayState.SONG, true);
					Conductor.bpm = PlayState.SONG.bpm;

					vocals = new FlxSound();
					try {
						var loadedVocals = Paths.voices(PlayState.SONG.song, true);
						if(loadedVocals != null && loadedVocals.length > 0) {
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = .8;
							vocals.play();
							vocals.pause();
						} else vocals = FlxDestroyUtil.destroy(vocals);
					} catch(e:Dynamic) vocals = FlxDestroyUtil.destroy(vocals);
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, true), .8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			} else if (instPlaying == curSelected && player.playingMusic) player.pauseOrResume(!player.playing);
		} else if (controls.ACCEPT && !player.playingMusic) {
			persistentUpdate = false;
			var songFolder:String = Paths.formatToSongPath(songs[curSelected].songName);
			var songLowercase:String = Highscore.formatSong(songFolder, curDifficulty);
			
			if (songLowercase == "" || songLowercase.length < 1) return;

			if (songLowercase == "enter-terminal-hard") {
				FlxG.switchState(() -> new TerminalState());
				return;
			}

			try {
				PlayState.SONG = Song.loadFromJson(songLowercase, songFolder);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
			} catch(e:Dynamic) {
				Logs.trace('ERROR! $e', ERROR);
				var errorStr:String = e.toString();
				if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1); //Missing chart

				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			if (FlxG.keys.pressed.TAB) FlxG.switchState(() -> new CharacterSelectionState());
			else {
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(() -> new PlayState());
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
			}
			stopMusicPlay = true;

			destroyFreeplayVocals();
			#if MODS_ALLOWED DiscordClient.loadModRPC(); #end
		} else if (FlxG.keys.justPressed.COMMA && !player.playingMusic) {
			persistentUpdate = false;
			openSubState(new FreeplaySectionSubstate());
			FlxG.sound.play(Paths.sound('scrollMenu'), .7);
		} else if(controls.RESET && !player.playingMusic) {
			persistentUpdate = false;
			openSubState(new substates.ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'), .7);
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);
	}

	function changeDiff(change:Int = 0) {
		if (player.playingMusic) return;
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedcombo = Highscore.getCombo(songs[curSelected].songName, curDifficulty);

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
		else diffText.text = displayDiff.toUpperCase();

		missingText.visible = missingTextBG.visible = false;
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		if (player.playingMusic) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (num => item in grpSongs.members) {
			var icon:HealthIcon = iconArray[num];
			item.alpha = .6;
			icon.alpha = .6;
			if (item.targetY == curSelected) {
				item.alpha = 1;
				icon.alpha = 1;
			}
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1) curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;

		changeDiff();

		_updateSongLastDifficulty();

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedcombo = Highscore.getCombo(songs[curSelected].songName, curDifficulty);
	}

	inline function _updateSongLastDifficulty() {
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
	}

	function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
		comboText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		comboText.x -= comboText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0) {
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles) {
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(FlxMath.bound(lerpSelected - _drawDistance, 0, songs.length));
		var max:Int = Math.round(FlxMath.bound(lerpSelected + _drawDistance, 0, songs.length));
		for (i in min...max) {
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function destroy():Void {
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata {
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int) {
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}