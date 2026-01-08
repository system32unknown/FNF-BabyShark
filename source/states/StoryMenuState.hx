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

	var bgSprite:FlxSprite;
	var tracksSprite:FlxSprite;
	var tracklist:FlxText;
	var scoreTxt:FlxText;
	var weekTitle:FlxText;

	var difficultySelectors:FlxGroup;
	var diffSprite:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var weekList:Array<WeekData> = [];

	var weekSprGroup:FlxTypedGroup<MenuItem>;
	var characters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;
	static var lastDifficultyName:String = '';
	static var curWeek:Int = 0;
	var curDifficulty:Int = 1;

	override function create() {
		if (PlayState.SONG == null) Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Story Menu"); #end

		if (WeekData.weeksList.length < 1) {
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

		var ui_tex:flixel.graphics.frames.FlxAtlasFrames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		add(weekSprGroup = new FlxTypedGroup<MenuItem>());
		add(new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK));
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		add(bgSprite = new FlxSprite(bgYellow.x, bgYellow.y));

		add(scoreTxt = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 32));
		scoreTxt.font = Paths.font('babyshark.ttf');

		add(weekTitle = new FlxText(0, 10, 750, '', 32));
		weekTitle.font = Paths.font('babyshark.ttf');
		weekTitle.alignment = RIGHT;
		weekTitle.alpha = .7;

		add(characters = new FlxTypedGroup<MenuCharacter>());
		for (i in 1...4) characters.add(new MenuCharacter((FlxG.width - 960) * i - 150, 70));

		add(tracksSprite = new FlxSprite(0, bgSprite.y + 425, Paths.image('Menu_Tracks')));
		tracksSprite.antialiasing = Settings.data.antialiasing;
		tracksSprite.x = 190 - (tracksSprite.width * 0.5);

		add(tracklist = new FlxText(0, tracksSprite.y + 60, 0, '', 32));
		tracklist.alignment = CENTER;
		tracklist.font = Paths.font("babyshark.ttf");
		tracklist.color = 0xFFe55777;

		add(grpLocks = new FlxTypedGroup<FlxSprite>());
		add(difficultySelectors = new FlxGroup());

		leftArrow = new FlxSprite(850, 462);
		leftArrow.antialiasing = Settings.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		Difficulty.resetList();
		if (lastDifficultyName == '') lastDifficultyName = Difficulty.getDefault();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		diffSprite = new FlxSprite(0, leftArrow.y);
		diffSprite.antialiasing = Settings.data.antialiasing;
		difficultySelectors.add(diffSprite);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = Settings.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		reload();
		changeWeek();
		changeDifficulty();

		super.create();
	}

	var allowInput:Bool = true;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	override function update(delta:Float):Void {
		if (WeekData.weeksList.length < 1) {
			super.update(delta);
			return;
		}

		var offsetY:Float = weekSprGroup.members[curWeek].targetY;
		for (item in weekSprGroup.members) item.y = FlxMath.lerp(item.targetY - offsetY + 480, item.y, Math.exp(-delta * 10.2));
		for (lock in grpLocks.members) lock.y = weekSprGroup.members[lock.ID].y + weekSprGroup.members[lock.ID].height / 2 - lock.height / 2;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-delta * 24)));
		if (intendedScore != lerpScore) {
			if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
			scoreTxt.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
		}

		if (!movedBack && !selectedWeek) {
			var changeDiff:Bool = false;
			final downJustPressed:Bool = Controls.justPressed('ui_down');
			if (downJustPressed || Controls.justPressed('ui_up')) {
				changeWeek(downJustPressed ? 1 : -1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeDiff = true;
			}

			if (FlxG.mouse.wheel != 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'), .7);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			final rightjustPressed:Bool = Controls.justPressed('ui_right');
			final leftjustPressed:Bool = Controls.justPressed('ui_left');

			if (rightjustPressed || leftjustPressed) changeDifficulty(rightjustPressed ? 1 : -1);
			else if (changeDiff) changeDifficulty();
			if (FlxG.keys.justPressed.CONTROL) {
				persistentUpdate = false;
				openSubState(new options.GameplayChangersSubstate());
			} else if (Controls.justPressed('reset')) {
				persistentUpdate = false;
				openSubState(new substates.ResetScoreSubState('', curDifficulty, '', curWeek));
			} else if (Controls.justPressed('accept')) selectWeek();

			rightArrow.animation.play(rightjustPressed ? 'press' : 'idle');
			leftArrow.animation.play(leftjustPressed ? 'press' : 'idle');
		}

		if (Controls.justPressed('back') && !movedBack && !selectedWeek) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(() -> new MainMenuState());
		}

		super.update(delta);
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;
	function selectWeek() {
		if (!weekIsLocked(weekList[curWeek].fileName)) {
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = weekList[curWeek].songs;
			for (i in 0...leWeek.length) songArray.push(leWeek[i][0]);

			// Nevermind that's stupid lmao
			try {
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;

				var diffic:String = Difficulty.getFilePath(curDifficulty);
				if (diffic == null) diffic = '';

				PlayState.storyDifficulty = curDifficulty;
				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = PlayState.campaignMisses = 0;
			} catch (e:Dynamic) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				selectedWeek = false;
				return;
			}

			if (!stopspamming) {
				FlxG.sound.play(Paths.sound('confirmMenu'));

				weekSprGroup.members[curWeek].isFlashing = true;
				for (char in characters.members) {
					if (char.character == '' || !char.hasConfirmAnimation) continue;
					char.animation.play('confirm');
				}
				stopspamming = true;
			}

			var directory:String = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			@:privateAccess
			if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory) {
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			FlxTimer.wait(1, () -> {
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(() -> new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});

			#if (MODS_ALLOWED && DISCORD_ALLOWED) DiscordClient.loadModRPC(); #end
		} else FlxG.sound.play(Paths.sound('cancelMenu'), .7);
	}

	function changeDifficulty(?dir:Int = 0):Void {
		curDifficulty = FlxMath.wrap(curDifficulty + dir, 0, Difficulty.list.length - 1);
		WeekData.setDirectoryFromWeek(weekList[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty, false);
		var newImage:flixel.graphics.FlxGraphic = Paths.image('menudifficulties/${Paths.formatToSongPath(diff)}');

		if (diffSprite.graphic != newImage) {
			diffSprite.loadGraphic(newImage);
			diffSprite.x = leftArrow.x + 60;
			diffSprite.x += (308 - diffSprite.width) / 3;
			diffSprite.alpha = 0;
			diffSprite.y = leftArrow.y - diffSprite.height + 50;

			FlxTween.cancelTweensOf(diffSprite);
			FlxTween.tween(diffSprite, {y: diffSprite.y + 30, alpha: 1}, 0.07);
		}
		lastDifficultyName = diff;
		intendedScore = Highscore.getWeekScore(weekList[curWeek].fileName, curDifficulty);
	}

	function changeWeek(?dir:Int = 0):Void {
		curWeek = FlxMath.wrap(curWeek + dir, 0, weekList.length - 1);

		var leWeek:WeekData = weekList[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		weekTitle.text = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName).toUpperCase();
		weekTitle.x = FlxG.width - (weekTitle.width + 10);

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (index => spr in weekSprGroup.members) {
			spr.alpha = (index - curWeek == 0 && unlocked) ? 1 : .5;
		}

		var assetName:String = leWeek.weekBackground;
		if (assetName != null && assetName.length != 0) {
			bgSprite.visible = true;
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_$assetName'));
		} else bgSprite.visible = false;
		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;

		if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if (newPos > -1) curDifficulty = newPos;
		updateText();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText() {
		for (index => item in characters.members) item.changeCharacter(weekList[curWeek].weekCharacters[index]);

		var tracks:String = '';
		var leWeek:WeekData = weekList[curWeek];
		for (i in 0...leWeek.songs.length) {
			var songName:String = leWeek.songs[i][0];
			tracks += songName.toUpperCase();
			if (i != leWeek.songs.length - 1) tracks += '\n';
		}

		tracklist.text = tracks;
		tracklist.x = tracksSprite.getGraphicMidpoint().x - (tracklist.width * .5);

		intendedScore = Highscore.getWeekScore(weekList[curWeek].fileName, curDifficulty);
	}

	function reload():Void {
		WeekData.reloadWeekFiles(true);
		if (curWeek >= WeekData.weeksList.length) curWeek = 0;

		var itemTargetY:Float = 0;
		var index:Int = 0;
		for (week in WeekData.weeksList) {
			var weekFile:WeekData = WeekData.weeksLoaded.get(week);
			var isLocked:Bool = weekIsLocked(week);
			if (!isLocked || !weekFile.hiddenUntilUnlocked) {
				weekList.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);

				var weekSprite:MenuItem = new MenuItem(0, bgSprite.y + 396, week);
				weekSprite.gameCenter(X).y = ((weekSprite.height + 20) * index);
				weekSprite.ID = index;
				weekSprite.targetY = itemTargetY;
				weekSprGroup.add(weekSprite);
				itemTargetY += Math.max(weekSprite.height, 110) + 10;

				// Needs an offset thingie
				if (isLocked) {
					var lock:FlxSprite = new FlxSprite(weekSprite.width + 10 + weekSprite.x);
					lock.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					grpLocks.add(lock);
				}
				index++;
			}
		}
		WeekData.setDirectoryFromWeek(weekList[0]);
	}
}