package states;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import data.WeekData;
import utils.MathUtil;
import game.Difficulty;
import game.Conductor;
import game.Highscore;
import game.HealthIcon;
import game.Song;
import states.editors.ChartingState;
import substates.ResetScoreSubState;
import substates.GameplayChangersSubstate;
import substates.FreeplaySectionSubstate;
import ui.ErrorDisplay;
import ui.Alphabet;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var countText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var grpSongs:FlxTypedGroup<Alphabet>;
	var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	public static var section:String = '';

	override function create()
	{		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if discord_rpc
		DiscordClient.changePresence("Freeplay Menu", null);
		#end

		section = FreeplaySectionSubstate.daSection;
		if (section == null || section == '') section = 'Vanilla';

		var doFunnyContinue = false;
		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (leWeek.sections != null) {
				for (sex in leWeek.sections) {
					if (sex != section)
						doFunnyContinue = true;
					else {
						doFunnyContinue = false;
						break;
					}	
				}
			} else doFunnyContinue = true;

			if (doFunnyContinue) {
				doFunnyContinue = false;
				continue;
			}

			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length) {
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs) {
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3) {
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			Paths.currentModDirectory = songs[i].folder;
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;

		countText = new FlxText(0, 0, 0, "", 20);
		countText.setFormat(Paths.font("vcr.ttf"), countText.size, FlxColor.WHITE, RIGHT);
		countText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
		countText.y = scoreBG.height - countText.y;

		add(countText);
		add(diffText);
		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		changeSelection();

		var textBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = .5;
		textBG.scrollFactor.set();
		add(textBG);

		#if PRELOAD_ALL
		final leTextSplit:Array<String> = [
			"Press SPACE to listen to the Song. / Press CTRL to open the Gameplay Changers Menu.",
			"Press COMMA to change the Section. / Press RESET to Reset your Score and Accuracy."
		];
		var leText:String = '${leTextSplit[0]}\n${leTextSplit[1]}';
		var size:Int = 16;
		#else
		var leText:String = "Press COMMA to change the Section. / Press CTRL to open the Gameplay Changers Menu. / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		text.y = FlxG.height - text.height;
		add(text);
		textBG.height = text.height;
		textBG.y = FlxG.height - textBG.height;

		errorDisplay = new ErrorDisplay();
		errorDisplay.addDisplay(this);

		updateTexts();
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
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, MathUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, MathUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(MathUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while (ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

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
			if (controls.UI_UP_P) {
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P) {
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP) {
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
				
				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}

			if (FlxG.mouse.wheel != 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (controls.UI_LEFT_P) {
			changeDiff(-1);
			_updateSongLastDifficulty();
		} else if (controls.UI_RIGHT_P) {
			changeDiff(1);
			_updateSongLastDifficulty();
		}

		if (controls.BACK) {
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if(FlxG.keys.justPressed.CONTROL) {
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		} else if(FlxG.keys.justPressed.SPACE) {
			if(instPlaying != curSelected) {
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;

				var songFolder:String = songs[curSelected].songName.toLowerCase();
				var songLowercase:String = Highscore.formatSong(songFolder, curDifficulty);
				PlayState.SONG = Song.loadFromJson(songLowercase, songFolder);

				if (PlayState.SONG != null) {
					if (PlayState.SONG.needsVoices)
						vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					else vocals = new FlxSound();

					FlxG.sound.list.add(vocals);
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
					vocals.play();
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0.7;
					instPlaying = curSelected;
				} else {
					errorDisplay.text = getErrorMessage(missChart, 'chart required to play audio, $missFile', songFolder, songLowercase);
					errorDisplay.displayError();
				}
				#end
			}
		} else if (controls.ACCEPT) {
			var songFolder:String = Paths.formatToSongPath(songs[curSelected].songName);
			var songLowercase:String = Highscore.formatSong(songFolder, curDifficulty);
			
			if (songLowercase == "") return;

			PlayState.SONG = Song.loadFromJson(songLowercase, songFolder);

			if (PlayState.SONG != null) {
				persistentUpdate = false;
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				if(colorTween != null) {
					colorTween.cancel();
				}

				if (FlxG.keys.pressed.SHIFT) {
					LoadingState.loadAndSwitchState(new ChartingState());
				} else LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;
				destroyFreeplayVocals();
			} else {
				errorDisplay.text = getErrorMessage(missChart, 'cannot play song, $missFile', songFolder, songLowercase);
				errorDisplay.displayError();
			}
		} else if (FlxG.keys.pressed.P) {
			LoadingState.loadAndSwitchState(new CharacterInSelectState.CharacterSelectState());
		} else if (FlxG.keys.justPressed.COMMA) {
			persistentUpdate = false;
			openSubState(new FreeplaySectionSubstate());
			FlxG.sound.play(Paths.sound('scrollMenu'));
		} else if(controls.RESET) {
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0) {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (i in 0...iconArray.length) {
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members) {
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1) curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;

		changeDiff();

		_updateSongLastDifficulty();

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
	}


	inline function _updateSongLastDifficulty() {
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	function positionHighscore() {
		countText.text = "PAGES (" + ((curSelected + 1) + "/" + songs.length) + ")";
		countText.x = FlxG.width - countText.width;

		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, MathUtil.boundTo(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles) {
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
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
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}