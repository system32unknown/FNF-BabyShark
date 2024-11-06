package states;

import flixel.group.FlxGroup;
import data.WeekData;
import data.StageData;
import backend.Highscore;
import backend.Song;
import objects.MenuItem;
import objects.MenuCharacter;

class StoryMenuState extends MusicBeatState {
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var txtTracklist:FlxText;
	var bgSprite:FlxSprite;

	static var curWeek:Int = 0;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];

	override function create() {
		if (PlayState.SONG == null) Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Story Menu"); #end

		if(WeekData.weeksList.length < 1) {
			MusicBeatState.skipNextTransIn = true;
			persistentUpdate = false;
			FlxG.switchState(() -> new ErrorState("NO WEEKS ADDED FOR STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				() -> FlxG.switchState(() -> new states.editors.WeekEditorState()),
				() -> {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					movedBack = true;
					FlxG.switchState(() -> new MainMenuState());
				})
			);
			return;
		}

		if(curWeek >= WeekData.weeksList.length) curWeek = 0;

		scoreText = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 32);
		scoreText.setFormat(Paths.font("babyshark.ttf"), 32);

		txtWeekTitle = new FlxText(FlxG.width * .7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = .7;

		var ui_tex:flixel.graphics.frames.FlxAtlasFrames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);

		add(grpWeekText = new FlxTypedGroup<MenuItem>());
		add(new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK));
		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpLocks = new FlxTypedGroup<FlxSprite>());

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for (i in 0...WeekData.weeksList.length) {
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked) {
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				itemTargetY += Math.max(weekThing.height, 110) + 10;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);

				// Needs an offset thingie
				if (isLocked) {
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		WeekData.setDirectoryFromWeek(loadedWeeks[0]);
		for (char in 0...3) {
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, loadedWeeks[0].weekCharacters[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(difficultySelectors = new FlxGroup());

		leftArrow = new FlxSprite(850, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		Difficulty.resetList();
		if(lastDifficultyName == '') lastDifficultyName = Difficulty.getDefault();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		sprDifficulty = new FlxSprite(0, leftArrow.y);
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * .07 + 100, bgSprite.y + 425, Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
		tracksSprite.x -= tracksSprite.width / 2;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.setFormat(Paths.font("babyshark.ttf"), 32, 0xFFe55777, CENTER);
		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float) {
		if(WeekData.weeksList.length < 1) {
			super.update(elapsed);
			return;
		}

		if(intendedScore != lerpScore) {
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

			scoreText.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
		}

		if (!movedBack && !selectedWeek) {
			var changeDiff:Bool = false;
			final downJustPressed:Bool = Controls.justPressed('ui_down');
			if (downJustPressed || Controls.justPressed('ui_up')) {
				changeWeek(downJustPressed ? 1 : -1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeDiff = true;
			}

			if(FlxG.mouse.wheel != 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'), .7);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			final rightjustPressed:Bool = Controls.justPressed('ui_right');
			final leftjustPressed:Bool = Controls.justPressed('ui_left');
			rightArrow.animation.play(rightjustPressed ? 'press' : 'idle');
			leftArrow.animation.play(leftjustPressed ? 'press' : 'idle');

			if (rightjustPressed || leftjustPressed) changeDifficulty(rightjustPressed ? 1 : -1);
			else if (changeDiff) changeDifficulty();
			if (FlxG.keys.justPressed.CONTROL) {
				persistentUpdate = false;
				openSubState(new options.GameplayChangersSubstate());
			} else if (Controls.justPressed('reset')) {
				persistentUpdate = false;
				openSubState(new substates.ResetScoreSubState('', curDifficulty, '', curWeek));
			} else if (Controls.justPressed('accept')) selectWeek();
		}

		if (Controls.justPressed('back') && !movedBack && !selectedWeek) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(() -> new MainMenuState());
		}

		super.update(elapsed);

		var offY:Float = grpWeekText.members[curWeek].targetY;
		for (_ => item in grpWeekText.members) item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));
		for (_ => lock in grpLocks.members) lock.y = grpWeekText.members[lock.ID].y + grpWeekText.members[lock.ID].height / 2 - lock.height / 2;
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;
	function selectWeek() {
		if (!weekIsLocked(loadedWeeks[curWeek].fileName)) {
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) songArray.push(leWeek[i][0]);

			// Nevermind that's stupid lmao
			try {
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;
	
				var diffic:String = Difficulty.getFilePath(curDifficulty);
				if(diffic == null) diffic = '';
	
				PlayState.storyDifficulty = curDifficulty;
				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = PlayState.campaignMisses = 0;
			} catch(e:Dynamic) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				selectedWeek = false;
				return;
			}

			if (!stopspamming) {
				FlxG.sound.play(Paths.sound('confirmMenu'));
	
				grpWeekText.members[curWeek].isFlashing = true;
				for (char in grpWeekCharacters.members)
					if (char.character != '' && char.hasConfirmAnimation)
						char.animation.play('confirm');
				stopspamming = true;
			}

			var directory:String = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			LoadingState.prepareToSong();
			FlxTimer.wait(1, () -> {
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(() -> new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});

			#if (MODS_ALLOWED && DISCORD_ALLOWED) DiscordClient.loadModRPC(); #end
		} else FlxG.sound.play(Paths.sound('cancelMenu'), .7);
	}

	function changeDifficulty(change:Int = 0):Void {
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty, false);
		var newImage:flixel.graphics.FlxGraphic = Paths.image('menudifficulties/${Paths.formatToSongPath(diff)}');

		if(sprDifficulty.graphic != newImage) {
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
		}
		lastDifficultyName = diff;

		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	}

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;
	function changeWeek(change:Int = 0):Void {
		curWeek = FlxMath.wrap(curWeek + change, 0, loadedWeeks.length - 1);

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		txtWeekTitle.text = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName).toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (num => item in grpWeekText.members) {
			item.alpha = .6;
			if (num - curWeek == 0 && unlocked) item.alpha = 1;
		}

		bgSprite.visible = true;
		var assetName:String = leWeek.weekBackground;
		if(assetName == null || assetName.length < 1) bgSprite.visible = false;
		else bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_$assetName'));
		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;
		
		if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(newPos > -1) curDifficulty = newPos;
		updateText();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText() {
		for (i in 0...grpWeekCharacters.length) grpWeekCharacters.members[i].changeCharacter(loadedWeeks[curWeek].weekCharacters[i]);

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [for (i in 0...leWeek.songs.length) leWeek.songs[i][0]];

		txtTracklist.text = '';
		for (i in 0...stringThing.length) {
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.screenCenter(X).x -= FlxG.width * .35;

		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	}
}
