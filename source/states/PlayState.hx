package states;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
#if VIDEOS_ALLOWED import backend.VideoManager; #end
#if !MODS_ALLOWED import openfl.utils.Assets; #end
#if !flash import flixel.addons.display.FlxRuntimeShader; #end
import backend.Highscore;
import backend.Song;
import backend.Rating;
import states.editors.*;
import substates.GameOverSubstate;
import substates.PauseSubState;
import objects.Note.EventNote;
import objects.*;
import utils.*;
import data.*;
import psychlua.*;
import cutscenes.DialogueBoxPsych;

class PlayState extends MusicBeatState {
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -271.5;

	public static var ratingStuff:Array<Array<haxe.extern.EitherType<String, Float>>> = [
		['Skill issue', .2], //From 0% to 19%
		['Ok', .4], //From 20% to 39%
		['Bad', .5], //From 40% to 49%
		['Bruh', .6], //From 50% to 59%
		['Meh', .69], //From 60% to 68%
		['Nice', .7], //69%
		['Good', .8], //From 70% to 79%
		['Great', .9], //From 80% to 89%
		['Sick!', 1.], //From 90% to 99%
		['Superb!!', 1.]
	];
	//event variables
	var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, flixel.util.FlxSave> = new Map<String, flixel.util.FlxSave>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	public var spawnTime:Float = 2000;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;
	@:noCompletion static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	public var gameOverChar:Character = null;

	public var notes:NoteGroup;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var canTweenCamZoom:Bool = false;
	public var canTweenCamZoomBoyfriend:Float = 1;
	public var canTweenCamZoomDad:Float = 1;
	public var canTweenCamZoomGf:Float = 1.3;

	public var dontZoomCam:Bool = false;
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	public var firstStart:Bool = false;

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	var displayedHealth(default, null):Float = 1;

	public dynamic function updateIconsPosition() {
		final iconOffset:Int = 26;
		iconP1.x = (iconP1.iconType == 'psych' ? healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset : healthBar.barCenter - iconOffset);
		iconP2.x = (iconP2.iconType == 'psych' ? healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2 : healthBar.barCenter - (iconP2.width - iconOffset));
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float {
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
			return health = value;

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(healthBar.bounded, healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		if (healthBar.percent < 20) {iconP1.setState(1); iconP2.setState(2);}
		else if (healthBar.percent > 80) {iconP1.setState(2); iconP2.setState(1);}
		else {iconP1.setState(0); iconP2.setState(0);}

		return health;
	}
	public var combo:Int = 0;
	public var maxCombo:Int = 0;

	public var healthBar:Bar;
	var songPercent:Float = 0;

	public var timeBar:Bar;
	public static var timeToStart:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	public static var mania:Int = 0;

	var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	var updateTime:Bool = true;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;

	public var accuracy:Float = 0;
	public var ranks:String = "";

	var notesHitArray:Array<Date> = [];
	public var nps:Int = 0;
	public var maxNPS:Int = 0;

	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	
	var timeTxt:FlxText;
	var judgementCounter:FlxText;

	var msTimingTween:FlxTween;
	var mstimingTxt:FlxText = new FlxText(0, 0, 0, "0ms");

	public static var campaignScore:Int = 0;
	public static var deathCounter:Int = 0;

	public static var chartingMode:Bool = false;

	public static var seenCutscene:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var restarted:Bool = false;

	public var defaultCamZoom:Float = 1.05;
	public var defaultHudCamZoom:Float = 1.;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singUP'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var storyDifficultyText:String = "";
	#if DISCORD_ALLOWED // Discord RPC variables
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var keysPressed:Array<Bool> = [];

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	public var hscriptArray:Array<HScript> = [];
	var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	var keysArray:Array<Dynamic>;

	public var comboGroup:FlxSpriteGroup;
	public var uiGroup:FlxSpriteGroup;
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	public var songName:String;

	var downScroll:Bool = ClientPrefs.getPref('downScroll');
	var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
	var hideHud:Bool = ClientPrefs.getPref('hideHud');
	var healthBarAlpha:Float = ClientPrefs.getPref('healthBarAlpha');
	var timeType:String = ClientPrefs.getPref('timeBarType'); 

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	#if VIDEOS_ALLOWED public var videoSprites:Array<backend.VideoSpriteManager> = []; #end
	override function create() {
		instance = this;

		startCallback = startCountdown;
		endCallback = endSong;

		firstStart = !MusicBeatState.previousStateIs(PlayState);
		persistentUpdate = true;
		persistentDraw = true;

		Conductor.usePlayState = true;
		Conductor.songPosition = Math.NEGATIVE_INFINITY;
		if (firstStart) FlxG.sound.destroy(true);
		Paths.clearStoredCache();

		if (FlxG.sound.music != null) FlxG.sound.music.destroy();
		var music:FlxSound = FlxG.sound.music = new FlxSound();
		music.persist = true;
		music.volume = 1;
		FlxG.sound.defaultMusicGroup.add(music);

		GameOverSubstate.resetVariables();
		PauseSubState.songName = null; //Reset to default

		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		camOther.bgColor = 0x00000000;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		songName = Paths.formatToSongPath(SONG.song);
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		if (mania < EK.minMania || mania > EK.maxMania) mania = EK.defaultMania;
		mania = SONG.mania != null ? SONG.mania : 3;

		keysArray = EK.fillKeys()[mania];
		fillKeysPressed();
		keysPressed = ArrayUtil.dynamicArray(false, keysArray.length);

		storyDifficultyText = Difficulty.getString();
		#if DISCORD_ALLOWED
		if (isStoryMode) detailsText = 'Story Mode: ${WeekData.getCurrentWeek().weekName}';
		else detailsText = "Freeplay";
		detailsPausedText = 'Paused - $detailsText';
		#end

		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(songName);
		curStage = SONG.stage;

		var stageData:data.StageData.StageFile = StageData.getStageFile(curStage);

		defaultCamZoom = stageData.defaultZoom;
		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage) stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.ID = 0;

		if(stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		if(isPixelStage) introSoundsSuffix = '-pixel';

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null) opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null) girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage) {
			case 'stage': new states.stages.StageWeek1(); //Week 1
			case 'spooky': new states.stages.Spooky(); //Week 2
			case 'philly': new states.stages.Philly(); //Week 3
			case 'limo': new states.stages.Limo(); //Week 4
			case 'mall': new states.stages.Mall(); //Week 5
			case 'school': new states.stages.School(); //Week 6 (placeholder)
			case 'davehouse': new states.stages.DaveHouse(); //Week Dave
		}

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.camera = camOther;
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/')) for (file in FileSystem.readDirectory(folder)) {
			if(file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
			if(file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
		}
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('stages/$curStage.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('stages/$curStage.hx'); #end

		if (!stageData.hide_girlfriend) {
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);
	
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null) {
			final mid:FlxPoint = gf.getGraphicMidpoint();
			camPos.add(mid.x + gf.cameraPosition[0], mid.y + gf.cameraPosition[1]);
			mid.put();
		}
		
		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null) gf.visible = false;
		}
		stagesFunc((stage:BaseStage) -> stage.createPost());

		uiGroup = new FlxSpriteGroup();
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		comboGroup = new FlxSpriteGroup();
		comboGroup.ID = 0;
		noteGroup = new FlxTypedGroup<FlxBasic>();

		var showTime:Bool = timeType != 'Disabled';
		timeTxt = new FlxText(0, 19, 400, "", 16);
		timeTxt.screenCenter(X);
		timeTxt.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = updateTime = showTime;
		if(downScroll) timeTxt.y = FlxG.height - 35;
		if(timeType == 'Song Name') timeTxt.text = SONG.song + ' - ${storyDifficultyText}' + (playbackRate != 1 ? ' (${playbackRate}x)' : '');

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', () -> return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		add(comboGroup);
		add(noteGroup);
		noteGroup.add(strumLineNotes);
		add(uiGroup);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = .000001;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);
		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 1);
		camGame.zoom = defaultCamZoom;
		camGame.snapToTarget();
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		moveCameraSection();

		healthBar = new Bar(0, downScroll ? 50 : FlxG.height * .9, 'healthBar', () -> return (ClientPrefs.getPref('SmoothHealth') ? displayedHealth : health), 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !hideHud;
		healthBar.alpha = healthBarAlpha;
		reloadHealthBarColors();
		if (!instakillOnMiss) uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP2 = new HealthIcon(dad.healthIcon, false);
		for(icon in [iconP1, iconP2]) {
			icon.y = healthBar.y - (icon.height / 2);
			icon.visible = !hideHud;
			icon.alpha = healthBarAlpha;
			if (ClientPrefs.getPref('HealthTypes') == 'Psych') icon.iconType = 'psych';
			if (!instakillOnMiss) uiGroup.add(icon);
		}

		scoreTxt = new FlxText(FlxG.width / 2, Math.floor(healthBar.y + 50), FlxG.width);
		scoreTxt.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, CENTER);
		scoreTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
		if (!downScroll) scoreTxt.y = FlxG.height - scoreTxt.height;
		scoreTxt.visible = !hideHud;
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);
		uiGroup.add(scoreTxt);

		judgementCounter = new FlxText(2, 0, 0, "Max Combo: 0\nEpic: 0\nSick: 0\nGood: 0\nOk: 0\nBad: 0", 16);
		judgementCounter.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, LEFT);
		judgementCounter.setBorderStyle(OUTLINE, FlxColor.BLACK);
		judgementCounter.scrollFactor.set();
		judgementCounter.visible = ClientPrefs.getPref('ShowJudgement') && !hideHud;
		uiGroup.add(judgementCounter);
		judgementCounter.screenCenter(Y);
		updateScore(false);

		botplayTxt = new FlxText(FlxG.width / 2, healthBar.bg.y + (downScroll ? 100 : -100), FlxG.width - 800, "[BOTPLAY]", 32);
		botplayTxt.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER);
		botplayTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
		botplayTxt.screenCenter(X);
		botplayTxt.scrollFactor.set();
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);

		uiGroup.camera = camHUD; noteGroup.camera = camHUD;
		comboGroup.camera = (ClientPrefs.getPref('RatingDisplay') == "Hud" ? camHUD : camGame);
		startingSong = true;

		for (notetype in noteTypes) {
			#if LUA_ALLOWED startLuasNamed('custom_notetypes/$notetype.lua'); #end
			#if HSCRIPT_ALLOWED startHScriptsNamed('custom_notetypes/$notetype.hx'); #end
		}
		for (event in eventsPushed) {
			#if LUA_ALLOWED startLuasNamed('custom_events/$event.lua'); #end
			#if HSCRIPT_ALLOWED startHScriptsNamed('custom_events/$event.hx'); #end
		}
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1) {
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		if (songName == 'tutorial') {
			canTweenCamZoom = true;
			dontZoomCam = true;
	
			canTweenCamZoomBoyfriend = 1;
			canTweenCamZoomDad = 1.3;
			canTweenCamZoomGf = 1.3;
	
			moveCameraSection();
		}
		// SONG SPECIFIC SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/${Paths.CHART_PATH}/$songName/')) for (file in FileSystem.readDirectory(folder)) {
			if(file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
			if(file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
		}

		startCallback();
		RecalculateRating();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		if(ClientPrefs.getPref('hitsoundVolume') > 0) Paths.sound('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}');
		for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic')) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic')));
		resetRPC();
	
		callOnScripts('onCreatePost');

		super.create();

		#if (target.threaded && sys)
		Main.current.threadPool.run(() -> {
		#end
			cacheCountdown();
			cachePopUpScore();
			GameOverSubstate.cache();
			Paths.clearUnusedCache();
		#if (target.threaded && sys)
		});
		#end

		if(timeToStart > 0)	clearNotesBefore(timeToStart);
		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			final ratio:Float = value / songSpeed; //funny word huh
			if (ratio != 1) {
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return songSpeed = value;
	}

	function set_playbackRate(value:Float):Float {
		if(generatedMusic) {
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;

			final ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1) {
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.getPref('safeFrames') / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		return playbackRate = value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> spr.y += newText.height + 2);
		luaDebugGroup.add(newText);
		trace(text);
	}

	public function reloadHealthBarColors() {
		healthBar.setColors(CoolUtil.getColor(dad.healthColorArray), CoolUtil.getColor(boyfriend.healthColorArray));
		timeBar.setColors(CoolUtil.getColor(dad.healthColorArray), FlxColor.GRAY);
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.visible = false;
					startCharacterScripts(newBoyfriend.curCharacter);
					HealthIcon.returnGraphic(newBoyfriend.healthIcon);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.visible = false;
					startCharacterScripts(newDad.curCharacter);
					HealthIcon.returnGraphic(newDad.healthIcon);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.visible = false;
					startCharacterScripts(newGf.curCharacter);
					HealthIcon.returnGraphic(newGf.healthIcon);
				}
		}
	}

	function startCharacterScripts(name:String) {
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath)) {
			luaFile = replacePath;
			doPush = true;
		} else {
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile)) doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(lime.utils.Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush) {
			for (script in luaArray) if(script.scriptName == luaFile) {
				doPush = false;
				break;
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/$name.hx';
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath)) {
			scriptFile = replacePath;
			doPush = true;
		} else {
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile)) doPush = true;
		}
		
		if(doPush) {
			for (hx in hscriptArray) if (hx.origin == scriptFile) {
				doPush = false;
				break;
			}
			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):VideoManager {
		#if VIDEOS_ALLOWED
		var filepath:String = Paths.video(name);
		var video:VideoManager = new VideoManager();
		inCutscene = true;

		if(!#if sys FileSystem #else Assets #end.exists(filepath)) {
			FlxG.log.warn('Couldnt find video file: $name');
			startAndEnd();
			return null;
		}

		video.startVideo(filepath);
		video.onVideoEnd.add(() -> {startAndEnd(); return;});
		return video;
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return null;
		#end
	}

	public function startAndEnd() {
		if(endingSong) endSong();
		else startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String):Void {
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.finishThing = () -> {
				psychDialogue = null;
				startAndEnd();
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.camera = camHUD;
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public var camMovement:Float = 40;
	public var campoint:FlxPoint = FlxPoint.get();
	public var camlockpoint:FlxPoint = FlxPoint.get();
	public var camlock:Bool = false;
	public var bfturn:Bool = false;

	function cacheCountdown() {
		for (asset in switch(stageUI) {
			case "pixel": ['${stageUI}UI/countdown/ready-pixel', '${stageUI}UI/countdown/set-pixel', '${stageUI}UI/countdown/date-pixel'];
			case "normal": ["countdown/ready", "countdown/set", "countdown/go"];
			default: ['${stageUI}UI/countdown/ready', '${stageUI}UI/countdown/set', '${stageUI}UI/countdown/go'];
		}) Paths.image(asset);
		for (count in ['3', '2', '1', 'Go']) Paths.sound('countdown/intro$count' + introSoundsSuffix);
	}

	public function updateLuaDefaultPos() {
		for (i in 0...playerStrums.length) {
			setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...opponentStrums.length) {
			setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
			setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
		}
	}

	public function startCountdown() {
		if (startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if (ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			updateLuaDefaultPos();

			setOnScripts('defaultMania', SONG.mania);

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			} else if (skipCountdown) {
				setSongTime(0);
				return true;
			}

			final introAlts:Array<String> = switch(stageUI) {
				case "pixel": ['${stageUI}UI/countdown/ready-pixel', '${stageUI}UI/countdown/set-pixel', '${stageUI}UI/countdown/date-pixel'];
				case "normal": ["countdown/ready", "countdown/set", "countdown/go"];
				default: ['${stageUI}UI/countdown/ready', '${stageUI}UI/countdown/set', '${stageUI}UI/countdown/go'];
			};
			var tick:Countdown = THREE;
			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, (tmr:FlxTimer) -> {
				charactersDance(tmr.loopsLeft);
				switch(swagCounter) {
					case 0:
						FlxG.sound.play(Paths.sound('countdown/intro3' + introSoundsSuffix), .6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0]);
						FlxG.sound.play(Paths.sound('countdown/intro2' + introSoundsSuffix), .6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1]);
						FlxG.sound.play(Paths.sound('countdown/intro1' + introSoundsSuffix), .6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2]);
						FlxG.sound.play(Paths.sound('countdown/introGo' + introSoundsSuffix), .6);
						tick = GO;
					case 4: tick = START;
				}

				notes.forEachAlive((note:Note) -> {
					if(ClientPrefs.getPref('opponentStrums') || note.mustPress) {
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(middleScroll && !note.mustPress) note.alpha *= .35;
					}
				});

				stagesFunc((stage:BaseStage) -> stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);
				swagCounter++;
			}, 5);
		}
		return true;
	}

	inline function createCountdownSprite(image:String):FlxSprite {
		final spr:FlxSprite = new FlxSprite(Paths.image(image));
		spr.camera = camHUD;
		spr.scrollFactor.set();

		if (isPixelStage) {
			spr.setGraphicSize(spr.width * daPixelZoom);
			spr.updateHitbox();
		}

		spr.screenCenter();
		spr.antialiasing = (ClientPrefs.getPref('Antialiasing') && !isPixelStage);
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, Conductor.crochet / 1000, {ease: FlxEase.cubeInOut, onComplete: (twn:FlxTween) -> {remove(spr, true); spr.destroy();}});
		return spr;
	}

	public function clearNotesBefore(time:Float) {
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time) {
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	var updateScoreText:Bool = true;
	public dynamic function updateScore(miss:Bool = false) {
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if(ret == LuaUtils.Function_Stop) return;

		judgementCounter.text = 'Max Combo: ${maxCombo}';
		for (rating in ratingsData) judgementCounter.text += '\n${CoolUtil.capitalize(rating.name)}: ${rating.hits}';
		judgementCounter.screenCenter(Y);
		if (updateScoreText) scoreTxt.text = getScoreText();

		callOnScripts('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float) {
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length) {
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() callOnScripts('onNextDialogue', [dialogueCount++]);
	public function skipDialogue() callOnScripts('onSkipDialogue', [dialogueCount]);

	function startSong():Void {
		startingSong = false;

		var music:FlxSound = FlxG.sound.music;
		music.loadEmbedded(Paths.inst(SONG.song));
		music.onComplete = () -> finishSong();
		music.pitch = playbackRate;
		music.volume = 1;
		vocals.time = music.time = 0;
		music.play(); vocals.play();

		if(timeToStart > 0) {
			setSongTime(timeToStart);
			timeToStart = 0;
		}

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {music.pause(); vocals.pause();}

		// Song duration in a float, useful for the time left feature
		songLength = music.length;
		FlxTween.tween(timeBar, {alpha: 1}, .5 * playbackRate, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, .5 * playbackRate, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', true, songLength / playbackRate); #end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var noteTypes:Array<String> = [];
	var eventsPushed:Array<String> = [];
	function generateSong(dataPath:String):Void {
		songSpeed = SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');

		switch(songSpeedType) {
			case "multiplicative": songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant": songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData:SwagSong = SONG;
		Conductor.bpm = songData.bpm;

		var inst = Paths.inst(songData.song);
		songLength = inst != null ? inst.length : 0;

		vocals = new FlxSound();
		if (SONG.needsVoices) vocals.loadEmbedded(Paths.voices(SONG.song));
		vocals.pitch = playbackRate;
		FlxG.sound.defaultMusicGroup.add(vocals);
		FlxG.sound.list.add(vocals);

		notes = new NoteGroup();
		noteGroup.add(notes);
		var noteData:Array<backend.Section.SwagSection> = songData.notes;

		var file:String = Paths.json('${Paths.CHART_PATH}/$songName/events');
		if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson('${Paths.CHART_PATH}/$songName/events')) || FileSystem.exists(file) #else Assets.exists(file) #end)
			for (event in Song.loadFromJson('events', songName).events) for (i in 0...event[1].length) makeEvent(event, i); //Event Notes

		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % EK.keys(mania));
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > mania) gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < EK.keys(mania)));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				if (instakillOnMiss && swagNote.isHideableNote) continue;
				unspawnNotes.push(swagNote);

				final floorSus:Int = Math.floor(swagNote.sustainLength / Conductor.stepCrochet);
				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1) {
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < EK.keys(mania)));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);
						sustainNote.correctionOffset = swagNote.height / 2;

						if(!isPixelStage) {
							if(oldNote.isSustainNote) {
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}
							if(downScroll) sustainNote.correctionOffset = 0;
						} else if(oldNote.isSustainNote) {
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}
	
						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if (middleScroll) {
							sustainNote.x += 310;
							if (daNoteData > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2;
				else if(middleScroll) {
					swagNote.x += 310;
					if(daNoteData > 1) swagNote.x += FlxG.width / 2 + 25;
				}

				if(!noteTypes.contains(swagNote.noteType)) noteTypes.push(swagNote.noteType);
			}
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length) makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) return;

		stagesFunc((stage:BaseStage) -> stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1': charType = 2;
					case 'dad' | 'opponent' | '0': charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}
				addCharacterToList(event.value2, charType);

			case 'Play Sound': Paths.sound(event.value1);
		}
		stagesFunc((stage:BaseStage) -> stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue) return returnedValue;

		return switch(event.event) {
			case 'Kill Henchmen': 280;
			default: 0;
		}
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int return flixel.util.FlxSort.byValues(-1, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int) {
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.getPref('noteOffset'),
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	public function generateStaticArrows(player:Int, arrowStartTween:Bool = false):Void {
		var strumLineX:Float = middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = downScroll ? (FlxG.height - 150) : 50;
		var grp = player == 1 ? playerStrums : opponentStrums;
		for (i in 0...EK.keys(mania)) {
			var tempMania:Int = mania;
			if (tempMania == 0) tempMania = 1;
			var twnDuration:Float = (4 / tempMania) * playbackRate;
			var twnDelay:Float = .5 + ((.8 / tempMania) * i) * playbackRate;
			var targetAlpha:Float = 1;

			if (player < 1) {
				if (!ClientPrefs.getPref('opponentStrums')) targetAlpha = 0;
				else if (middleScroll) targetAlpha = .35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = downScroll;

			if (arrowStartTween || ((!isStoryMode || restarted || firstStart || deathCounter > 0) && !skipArrowStartTween) && mania > 1) {
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, twnDuration, {ease: FlxEase.circOut, startDelay: twnDelay});
			} else babyArrow.alpha = targetAlpha;

			if (player < 1 && middleScroll) {
				babyArrow.x += 310;
				if(i > 1) babyArrow.x += FlxG.width / 2 + 25; //Up and Right
			}

			grp.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
			callOnLuas('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);
			callOnHScript('onSpawnStrum', [babyArrow]);

			if (ClientPrefs.getPref('showKeybindsOnStart') && player == 1) {
				for (j in 0...keysArray[i].length) {
					var daKeyTxt:FlxText = new FlxText(babyArrow.x, babyArrow.y - 10, 0, backend.InputFormatter.getKeyName(keysArray[i][j]), 32 - mania);
					daKeyTxt.setFormat(Paths.font("babyshark.ttf"), 32 - mania, FlxColor.WHITE, CENTER);
					daKeyTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
					daKeyTxt.alpha = 0;
					var textY:Float = (j == 0 ? babyArrow.y - 32 : ((babyArrow.y - 32) + babyArrow.height) - daKeyTxt.height);
					daKeyTxt.setPosition(babyArrow.x + ((babyArrow.width - daKeyTxt.width) / 2), textY);
					add(daKeyTxt);
					daKeyTxt.camera = camHUD;

					if (mania > 1 && !skipArrowStartTween) FlxTween.tween(daKeyTxt, {y: textY + 32, alpha: 1}, twnDuration, {ease: FlxEase.circOut, startDelay: twnDelay});
					else {daKeyTxt.y += 16; daKeyTxt.alpha = 1;}
					FlxTimer.wait(Conductor.crochet * .001 * 12, () -> FlxTween.tween(daKeyTxt, {y: daKeyTxt.y + 32, alpha: 0}, twnDuration, {ease: FlxEase.circIn, startDelay: twnDelay, onComplete: (t) -> remove(daKeyTxt)}));
				}
			}
		}
	}

	override function openSubState(SubState:flixel.FlxSubState) {
		stagesFunc((stage:BaseStage) -> stage.openSubState(SubState));
		if (paused) {
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
		}
		super.openSubState(SubState);
	}

	override function closeSubState() {
		super.closeSubState();
		stagesFunc((stage:BaseStage) -> stage.closeSubState());
		if (paused) {
			if (FlxG.sound.music != null && !startingSong) resyncVocals();

			FlxTimer.globalManager.forEach((tmr:FlxTimer) -> if (!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach((twn:FlxTween) -> if (!twn.finished) twn.active = true);

			#if VIDEOS_ALLOWED if(videoSprites.length > 0) for(video in videoSprites) if(video.exists) video.paused = false; #end

			paused = false;
			callOnScripts('onResume');

			#if DISCORD_ALLOWED resetRPC(startTimer != null && startTimer.finished); #end
		}
	}

	override public function onFocus():Void {
		callOnScripts('onFocus');
		#if DISCORD_ALLOWED if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.); #end
		super.onFocus();
		callOnScripts('onFocusPost');
	}

	override public function onFocusLost():Void {
		callOnScripts('onFocusLost');
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && ClientPrefs.getPref('autoPausePlayState') && !tryPause())
			DiscordClient.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)');
		#end
		super.onFocusLost();
		callOnScripts('onFocusLostPost');
	}

	override public function onResize(width:Int, height:Int):Void {
		callOnScripts('onResize', [width, height]);
		super.onResize(width, height);
		callOnScripts('onResizePost', [width, height]);
	}

	function resetRPC(?showTime:Bool = false) {
		#if desktop
		if (showTime) DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', true, (songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset')) / playbackRate);
		else DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)');
		#end
	}

	function resyncVocals(resync:Bool = true):Void {
		if (finishTimer != null || (transitioning && endingSong)) return;
		FlxG.sound.music.pitch = playbackRate;

		if (Conductor.songPosition <= vocals.length) {
			var stream:Bool = vocals.vorbis != null;
			vocals.pitch = playbackRate;

			if (!stream || resync) {
				if (stream) {FlxG.sound.music.pause(); vocals.pause();}
				Conductor.songPosition = (vocals.time = FlxG.sound.music.time) + Conductor.offset;
			} else Conductor.songPosition = lastSongTime + Conductor.offset;
			vocals.play();
		} else Conductor.songPosition = lastSongTime + Conductor.offset;

		var diff:Float = lastSongTime - Conductor.songPosition;
		if (diff < songElapsed && diff >= 0) {
			var v:Float = Conductor.songPosition;
			Conductor.songPosition = lastSongTime;
			lastSongTime = v;
		} else lastSongTime = Conductor.songPosition;
		FlxG.sound.music.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	var lastSongTime:Float = 0;
	var songElapsed:Float = 0;
	var syncDebounce:Float = 0;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.playing) {
			var time:Float = FlxG.sound.music.time;
			songElapsed = time - lastSongTime;
			lastSongTime = time;
		}
		
		if (startedCountdown && !paused) {
			var delta:Float = elapsed * 1000 * playbackRate;
			if (!startingSong && FlxG.sound.music.playing && songElapsed > 0)
				Conductor.songPosition = lastSongTime;
			else Conductor.songPosition += delta;

			if (!startingSong && (syncDebounce += elapsed) > 1) {
				syncDebounce = 0;
				var resync:Bool = vocals.loaded && Math.abs(vocals.time - FlxG.sound.music.time) > (vocals.vorbis == null ? 6 : 12);
				if (Math.abs(lastSongTime - Conductor.songPosition) > 16 || resync) resyncVocals(resync);
			}
		}

		if(ClientPrefs.getPref('camMovement') && !isPixelStage && camlock)
			camFollow.setPosition(camlockpoint.x, camlockpoint.y);
		
		if(!inCutscene && !paused && !freezeCamera)
			FlxG.camera.followLerp = 2.4 * cameraSpeed * playbackRate;
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		checkEventNote();

		if (generatedMusic && !endingSong && !isCameraOnForcedPos && ClientPrefs.getPref('UpdateCamSection')) moveCameraSection();
		super.update(elapsed);

		if (ClientPrefs.getPref('ShowNPS')) {
			for(i in 0...notesHitArray.length) {
				var curNPS:Date = notesHitArray[i];
				if (curNPS != null && curNPS.getTime() + (1000 / playbackRate) < Date.now().getTime())
					notesHitArray.remove(curNPS);
			}
			nps = Math.floor(notesHitArray.length);
			if (nps > maxNPS) maxNPS = nps;
			if (updateScoreText) scoreTxt.text = getScoreText();
		}

		if (ClientPrefs.getPref('SmoothHealth')) displayedHealth = FlxMath.lerp(displayedHealth, health, .1 / (ClientPrefs.getPref('framerate') / 60));

		updateMusicBeat();
		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE) tryPause();

		for (icon in [iconP1, iconP2]) {
			switch(ClientPrefs.getPref('IconBounceType')) {
				case "Old": icon.setGraphicSize(Std.int(FlxMath.lerp(150, icon.width, .5)));
				case "Psych":
					var mult:Float = FlxMath.lerp(1, icon.scale.x, Math.exp(-elapsed * 9 * playbackRate));
					icon.scale.set(mult, mult);
				case "Dave": icon.setGraphicSize(Std.int(FlxMath.lerp(150, icon.width, .88)), Std.int(FlxMath.lerp(150, icon.height, .88)));
			}
			icon.updateHitbox();
		}
		updateIconsPosition();

		if (!endingSong && !inCutscene && allowDebugKeys) {
			if (controls.justPressed('debug_1')) openChartEditor();
			if (controls.justPressed('debug_2')) openCharacterEditor();
		}

		if (healthBar.bounds != null && health > healthBar.bounds.max) health = healthBar.bounds.max;

		if (startingSong) {
			if (startedCountdown && Conductor.songPosition >= 0) startSong();
			else if(!startedCountdown) Conductor.songPosition = -Conductor.crochet * 5;
		} else if (!paused && updateTime) {
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
			songPercent = curTime / songLength;
			var songCalc:Float = songLength - curTime;

			if (timeType == 'Time Elapsed' || timeType == 'Time Position' || timeType == 'Name Elapsed' || timeType == 'Name Time Position') songCalc = curTime;

			var secondsTotal:Int = Math.floor(Math.max(0, (songCalc / playbackRate) / 1000));
			var formattedsec:String = CoolUtil.formatTime(secondsTotal);
			var timePos:String = '$formattedsec / ${CoolUtil.formatTime(Math.floor((songLength / playbackRate) / 1000))}';
			if (timeType != 'Song Name') timeTxt.text = switch(timeType) {
				case 'Time Left' | 'Time Elapsed': formattedsec;
				case 'Time Position': timePos;
				case 'Name Left' | 'Name Elapsed': '${SONG.song} • ${storyDifficultyText} ${(playbackRate != 1 ? '(${playbackRate}x) ' : '')}($formattedsec)';
				case 'Name Percent': '${SONG.song} • ${storyDifficultyText} ${(playbackRate != 1 ? '(${playbackRate}x) ' : '')}(${timeBar.percent}%)';
				case 'Name Time Position' | _: '${SONG.song} • ${storyDifficultyText} ${(playbackRate != 1 ? '(${playbackRate}x) ' : '')}($timePos)';
			}
		}

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(defaultHudCamZoom, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		#if debug
		FlxG.watch.addQuick("sectionShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		#end

		if (!ClientPrefs.getPref('noReset') && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong && !practiceMode) health = 0;
		doDeathCheck();

		if (unspawnNotes[0] != null) {
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time) {
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		if (generatedMusic) {
			if(!inCutscene) {
				processInputs();

				var anim:String = boyfriend.getAnimationName();
				if (!boyfriend.stunned && !boyfriend.isAnimationNull() && (cpuControlled || !keysPressed.contains(true) || endingSong)) {
					var canDance:Bool = anim.startsWith('sing') && !anim.endsWith('miss');
					if(!boyfriend.isAnimationNull() && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * boyfriend.singDuration && canDance)
						boyfriend.dance();
				}
				
				if(notes.length > 0) {
					if(startedCountdown) renderNotes();
					else notes.forEachAlive((daNote:Note) -> {daNote.canBeHit = false; daNote.wasGoodHit = false;});
				}
			}
			checkEventNote();
		}

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function renderNotes():Void {
		notes.forEachAlive((daNote:Note) -> {
			var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
			if(!daNote.mustPress) strumGroup = opponentStrums;
			var strum:StrumNote = strumGroup.members[daNote.noteData];
			daNote.followStrumNote(strum, songSpeed / playbackRate);
			if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

			if (Conductor.songPosition - daNote.strumTime > noteKillOffset) { // Kill extremely late notes and cause misses
				if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);
				if (!daNote.mustPress && daNote.ignoreNote && !endingSong) opponentnoteMiss(daNote);
			
				daNote.active = daNote.visible = false;
				invalidateNote(daNote);
			}
		});
	}

	function tryPause():Bool {
		if (startedCountdown && canPause) {
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
				return true;
			}
		}
		return false;
	}

	function openPauseMenu() {
		for (i in 0...keysPressed.length) if (keysPressed[i]) inputRelease(i);

		FlxG.camera.followLerp = 0;
		FlxTimer.globalManager.forEach((tmr:FlxTimer) -> if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach((twn:FlxTween) -> if (!twn.finished) twn.active = false);
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		#if VIDEOS_ALLOWED if(videoSprites.length > 0) for(video in videoSprites) if(video.exists) video.paused = true; #end

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED DiscordClient.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)'); #end
	}

	function openChartEditor() {
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, true);
		DiscordClient.resetClientID();
		#end
		FlxG.switchState(() -> new ChartingState());
	}

	function openCharacterEditor() {
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		FlxG.switchState(() -> new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		final hpBound:Float = (healthBar.bounds != null ? healthBar.bounds.min : 0);
		if (((skipHealthCheck && instakillOnMiss) || health <= hpBound) && !practiceMode && !isDead) {
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				#if LUA_ALLOWED modchartTimers.clear(); modchartTweens.clear(); #end
				#if VIDEOS_ALLOWED if(videoSprites.length > 0) for(video in videoSprites) removeVideoSprite(video); #end

				openSubState(new GameOverSubstate());

				#if DISCORD_ALLOWED DiscordClient.changePresence('Game Over - $detailsText', '${SONG.song} ($storyDifficultyText)'); #end
				return isDead = true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) return;

			var value1:String = eventNotes[0].value1 != null ? eventNotes[0].value1 : '';
			var value2:String = eventNotes[0].value2 != null ? eventNotes[0].value2 : '';
			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		if(strumTime == null) strumTime = Conductor.songPosition;

		switch(eventName) {
			case 'Hey!':
				var value:Int = switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0': 0;
					case 'gf' | 'girlfriend' | '1': 1;
					default: 2;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = .6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) {
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.getPref('camZooms') && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = .015;
					if(flValue2 == null) flValue2 = .03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Set Camera Zoom':
				if(flValue1 == null) flValue1 = defaultCamZoom;
				if(flValue2 == null) flValue2 = 1;
				defaultCamZoom = flValue1;
				defaultHudCamZoom = flValue2;

			case 'Play Animation':
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend': char = boyfriend;
					case 'gf' | 'girlfriend': char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null) {
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null) {
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null) {
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.setPosition(flValue1, flValue2);
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend': char = gf;
					case 'boyfriend' | 'bf': char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;
						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null) {
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) targetsArray[i].shake(intensity, duration * playbackRate);
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend': charType = 2;
					case 'dad' | 'opponent': charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) addCharacterToList(value2, charType);

							var lastVisible:Bool = boyfriend.visible;
							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = lastVisible;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) addCharacterToList(value2, charType);

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastVisible:Bool = dad.visible;
							dad.visible = false;
							dad = dadMap.get(value2);
							if(gf != null) gf.visible = !wasGf;
							dad.visible = lastVisible;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null) {
							if(gf.curCharacter != value2) {
								if(!gfMap.exists(value2)) addCharacterToList(value2, charType);

								var lastVisible:Bool = gf.visible;
								gf.visible = false;
								gf = gfMap.get(value2);
								gf.visible = lastVisible;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant") {
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					final newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0) songSpeed = newValue;
					else songSpeedTween = FlxTween.num(songSpeed, newValue, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete: (_) -> songSpeedTween = null}, set_songSpeed);
				}

			case 'Set Property':
				try {
					var trueVal:Dynamic = null;
					var killMe:Array<String> = value1.split(',');
					if (killMe.length > 1 && killMe[1].toLowerCase().replace(" ", "") == "bool") {
						if (value2 == "true") trueVal = true;
						else if (value2 == "false") trueVal = false;
					}
	
					killMe = killMe[0].split('.');
					if (killMe.length > 1) LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe, true, true), killMe[killMe.length - 1], trueVal != null ? trueVal : value2);
					else LuaUtils.setVarInArray(this, value1, trueVal != null ? trueVal : value2);	
				} catch(e:Dynamic) {
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
				}
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		}
		stagesFunc((stage:BaseStage) -> stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	var lastCharFocus:String;
	public function moveCameraSection():Void {
		var section = SONG.notes[curSection];
		if (section == null) return;

		if (gf != null && section.gfSection) {
			moveCamera('gf');
			if (lastCharFocus != 'gf') {
				callOnScripts('onMoveCamera', ['gf']);
				lastCharFocus = 'gf';
			}
			return;
		}

		var camCharacter:String = (!section.mustHitSection ? 'dad' : 'boyfriend');
		moveCamera(camCharacter);
		if(ClientPrefs.getPref('camMovement') && !isPixelStage) {
			campoint.set(camFollow.x, camFollow.y);
			bfturn = (camCharacter == 'boyfriend');
			camlock = false;
		}
		if (bfturn && lastCharFocus != 'boyfriend') callOnScripts('onMoveCamera', ['boyfriend']);
		else if (lastCharFocus != 'dad') callOnScripts('onMoveCamera', ['dad']);
		lastCharFocus = bfturn ? 'boyfriend' : 'dad';
	}

	var cameraTwn:FlxTween;
	public function moveCamera(moveCameraTo:Dynamic) {
		if(moveCameraTo == 'dad' || moveCameraTo) {
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			if(canTweenCamZoom) tweenCamZoom(canTweenCamZoomDad);
		} else if((moveCameraTo == 'boyfriend' || moveCameraTo == 'bf') || !moveCameraTo) {
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			if(canTweenCamZoom) tweenCamZoom(canTweenCamZoomBoyfriend);
		} else {
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			if(canTweenCamZoom) tweenCamZoom(canTweenCamZoomGf);
		}
	}

	public function tweenCamZoom(zoom:Float = 1) {
		if (cameraTwn == null && camGame.zoom != zoom)
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: zoom}, (Conductor.stepCrochet * 4 / 1000) * playbackRate, {ease: FlxEase.elasticInOut, onComplete: (_) -> cameraTwn = null});
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void {
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.getPref('noteOffset') <= 0 || ignoreNoteOffset) endCallback();
		else finishTimer = FlxTimer.wait(ClientPrefs.getPref('noteOffset') / 1000, () -> endCallback());
	}

	public var transitioning = false;
	public function endSong() {
		if(!startingSong) { //Should kill you if you tried to cheat
			notes.forEach((daNote:Note) -> if(daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= .05 * healthLoss);
			for (daNote in unspawnNotes) if(daNote.strumTime < songLength - Conductor.safeZoneOffset) health -= .05 * healthLoss;
			if(doDeathCheck()) return false;
		}

		timeBar.visible = timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;
		restarted = false;

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning) {
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			if(!practiceMode && !cpuControlled) {
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				Highscore.saveCombo(SONG.song, '$ratingFC, $ratingName', storyDifficulty);
			}
			playbackRate = 1;
			vocals.volume = 0;
			vocals.stop();

			if (chartingMode) {openChartEditor(); return false;}

			if (isStoryMode) {
				campaignScore += songScore;
				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					FlxG.switchState(() -> new StoryMenuState());

					if(!practiceMode && !cpuControlled) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				} else {
					var difficulty:String = Difficulty.getFilePath();
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					SONG = Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
					FlxG.sound.music.stop();

					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(() -> new PlayState());
				}
			} else {
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				FlxG.switchState(() -> new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0;

	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	function cachePopUpScore() {
		var uiPrefix:String = '';
		var uiPostfix:String = '';
		if (stageUI != "normal") {
			uiPrefix = '${stageUI}UI/';
			if (isPixelStage) uiPostfix = '-pixel';
		}

		for (rating in ratingsData) Paths.image(uiPrefix + 'ratings/${rating.image}' + uiPostfix);
		for (i in 0...10) Paths.image(uiPrefix + 'number/num$i' + uiPostfix);
		for (miscRatings in ['combo', 'early', 'late']) Paths.image(uiPrefix + 'ratings/$miscRatings' + uiPostfix);
	}

	var scoreSeparator:String = "|";
	function getScoreText() {
		var tempText:String = '${!ClientPrefs.getPref('ShowNPS') ? '' : 'NPS:$nps/$maxNPS $scoreSeparator '}Score:$songScore ';
		if (!(cpuControlled || instakillOnMiss)) tempText += '$scoreSeparator Breaks:$songMisses ';
		tempText += '$scoreSeparator Acc:$accuracy% •' + (ratingName != '?' ? ' ($ratingFC, $ranks) $ratingName' : ' N/A');
		return tempText;
	}

	public var ratingAcc:FlxPoint = FlxPoint.get();
	public var ratingVel:FlxPoint = FlxPoint.get();
	function popUpScore(?note:Note):Void {
		if (note == null) return;

		final noteDiff:Float = getNoteDiff(note) / getActualPlaybackRate();
		final daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff);
		var score:Int = 500;

		var msTiming:Float = 0;

		note.ratingMod = daRating.ratingMod;
		note.rating = daRating.name;
		score = daRating.score;

		if(!note.ratingDisabled) daRating.hits++;
		totalNotesHit += (ClientPrefs.getPref('complexAccuracy') ? backend.Wife3.getAcc(-noteDiff) : daRating.ratingMod);

		if(daRating.noteSplash && !note.noteSplashDisabled) spawnNoteSplashOnNote(note);

		songScore += score;
		if(!note.ratingDisabled) {
			songHits++;
			totalPlayed++;
			RecalculateRating();
		}

		if (!ClientPrefs.getPref('ShowComboCounter') || (!showRating && !showCombo && !showComboNum)) return;
		if (!ClientPrefs.getPref('comboStacking')) comboGroup.forEachAlive((spr:FlxSprite) -> FlxTween.globalManager.completeTweensOf(spr));

		final placement:Float = FlxG.width * .35;

		var uiPrefix:String = '';
		var uiPostfix:String = '';
		var antialias:Bool = ClientPrefs.getPref('Antialiasing');
		final mult:Float = (isPixelStage ? daPixelZoom * .85 : .7);

		if (stageUI != "normal") {
			uiPrefix = 'pixelUI/';
			if (isPixelStage) uiPostfix = '-pixel';
			antialias = !isPixelStage;
		}
	
		var comboOffset:Array<Array<Int>> = ClientPrefs.getPref('comboOffset');

		var rating:FlxSprite = null;
		if (showRating) {
			rating = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image(uiPrefix + 'ratings/${daRating.image}' + uiPostfix));
			rating.screenCenter(Y).y -= 60 + comboOffset[0][1];
			rating.x = placement - 40 + comboOffset[0][0];
	
			rating.velocity.set(-FlxG.random.int(0, 10) * playbackRate + ratingVel.x, -FlxG.random.int(140, 175) * playbackRate + ratingVel.y);
			rating.acceleration.set(ratingAcc.x * playbackRate * playbackRate, 550 * playbackRate * playbackRate + ratingAcc.y);
			rating.antialiasing = antialias;
			rating.setGraphicSize(rating.width * mult);
			rating.updateHitbox();
			rating.ID = comboGroup.ID++;
	
			comboGroup.add(rating);
			FlxTween.tween(rating, {alpha: 0}, .2 / playbackRate, {onComplete: (_) -> {rating.kill(); rating.alpha = 1;}, startDelay: Conductor.crochet * .001 / playbackRate});
		}
	
		var comboSpr:FlxSprite = null;
		if (showCombo && combo >= 10) {
			comboSpr = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image(uiPrefix + 'ratings/combo' + uiPostfix));
			comboSpr.screenCenter(Y).y -= comboOffset[2][1];
			comboSpr.x = placement + comboOffset[2][0];
	
			comboSpr.velocity.set(FlxG.random.int(1, 10) * playbackRate + ratingVel.x, -FlxG.random.int(140, 160) * playbackRate + ratingVel.y);
			comboSpr.acceleration.set(ratingAcc.x * playbackRate * playbackRate, FlxG.random.int(200, 300) * playbackRate * playbackRate + ratingAcc.y);
			comboSpr.antialiasing = antialias;
			comboSpr.setGraphicSize(comboSpr.width * mult);
			comboSpr.updateHitbox();
			comboSpr.ID = comboGroup.ID++;

			comboGroup.add(comboSpr);
			FlxTween.tween(comboSpr, {alpha: 0}, .2 / playbackRate, {onComplete: (_) -> {comboSpr.kill(); comboSpr.alpha = 1;}, startDelay: Conductor.crochet * .002 / playbackRate});
		}

		if (ClientPrefs.getPref('ShowMsTiming') && mstimingTxt != null) {
			msTiming = MathUtil.truncateFloat(noteDiff / getActualPlaybackRate());
			mstimingTxt.setFormat(null, 20, FlxColor.WHITE, CENTER);
			mstimingTxt.setBorderStyle(OUTLINE, FlxColor.BLACK);
			mstimingTxt.text = '${msTiming}ms';
			mstimingTxt.color = SpriteUtil.dominantColor(rating);

			var comboShowSpr:FlxSprite = (showCombo && combo >= 10 ? comboSpr : rating);
			mstimingTxt.setPosition(comboShowSpr.x + 100, comboShowSpr.y + (showCombo && combo >= 10 ? 80 : 100));
			mstimingTxt.updateHitbox();
			mstimingTxt.ID = comboGroup.ID++;
			comboGroup.add(mstimingTxt);
		}
	
		if (showComboNum) {
			var comboSplit:Array<String> = Std.string(Math.abs(combo)).split('');
			var daLoop:Int = 0;
			for (i in [for (i in 0...comboSplit.length) Std.parseInt(comboSplit[i])]) {
				var numScore:FlxSprite = comboGroup.recycle(FlxSprite).loadGraphic(Paths.image(uiPrefix + 'number/num$i' + uiPostfix));
				numScore.screenCenter(Y).y += 80 - comboOffset[1][1];
				numScore.x = placement + (43 * daLoop++) - 90 + comboOffset[1][0];
			
				numScore.velocity.set(FlxG.random.float(-5, 5) * playbackRate + ratingVel.x, -FlxG.random.int(140, 160) * playbackRate + ratingVel.y);
				numScore.acceleration.set(ratingAcc.x * playbackRate * playbackRate, FlxG.random.int(200, 300) * playbackRate * playbackRate + ratingAcc.y);
				numScore.antialiasing = antialias;
				numScore.setGraphicSize(numScore.width * (isPixelStage ? daPixelZoom : .5));
				numScore.updateHitbox();
				numScore.ID = comboGroup.ID++;

				comboGroup.add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, .2 / playbackRate, {onComplete: (_) -> {numScore.kill(); numScore.alpha = 1;}, startDelay: Conductor.crochet * .002 / playbackRate});
			}
		}

		if (ClientPrefs.getPref('ShowMsTiming')) {
			if (msTimingTween != null) {mstimingTxt.alpha = 1; msTimingTween.cancel();}
			msTimingTween = FlxTween.tween(mstimingTxt, {alpha: 0}, .2 / playbackRate, {startDelay: Conductor.crochet * .001 / playbackRate});
		}
		comboGroup.sort(CoolUtil.sortByID);
	}

	static function getNoteDiff(note:Note = null):Float {
		var noteDiffTime:Float = note.strumTime - Conductor.songPosition;
		return switch(ClientPrefs.getPref('NoteDiffTypes')) {
			case 'Psych': Math.abs(noteDiffTime + ClientPrefs.getPref('ratingOffset'));
			case 'Simple' | _: noteDiffTime;
		}
	}

	function inputPress(key:Int) {
		fillKeysPressed();
		keysPressed[key] = true;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key], true);
		if(ret == LuaUtils.Function_Stop) return;

		//more accurate hit time for the ratings?
		if(notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong) {
			var lastTime:Float = Conductor.songPosition;
			if (FlxG.sound.music != null && FlxG.sound.music.playing && !startingSong && Conductor.songPosition >= 0)
				Conductor.songPosition = FlxG.sound.music.time;

			var sortedNotesList:Array<Note> = [];				
			var canMiss:Bool = !ClientPrefs.getPref('ghostTapping');

			for (daNote in notes) {
				if (!strumsBlocked[daNote.noteData] && daNote.mustPress && daNote.exists && !daNote.blockHit && !daNote.tooLate) {
					if (!daNote.isSustainNote && !daNote.wasGoodHit) {
						if (!daNote.canBeHit && daNote.checkDiff(Conductor.songPosition)) daNote.update(0);
						if (daNote.canBeHit) {
							if (daNote.noteData == key) sortedNotesList.push(daNote);
							canMiss = canMiss ? true : ClientPrefs.getPref('AntiMash');
						} else if (daNote.isSustainNote && daNote.noteData == key && ((daNote.wasGoodHit || daNote.prevNote.wasGoodHit) && (daNote.parent != null && !daNote.parent.hasMissed && daNote.parent.wasGoodHit)))
							sortedNotesList.push(daNote);
					}
				}
			}
			sortedNotesList.sort((a:Note, b:Note) -> Std.int(a.strumTime - b.strumTime));

			if (sortedNotesList.length > 0) {
				var epicNote:Note = sortedNotesList[0];
				if (sortedNotesList.length > 1) {
					for (bad in 1...sortedNotesList.length) {
						var doubleNote:Note = sortedNotesList[bad];
						if (doubleNote.noteData != epicNote.noteData) break;

						if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
							invalidateNote(doubleNote);
							break;
						} else if (doubleNote.strumTime < epicNote.strumTime) {
							epicNote = doubleNote; 
							break;
						}
					}
				}

				// eee jack detection before was not super good
				if (epicNote.isSustainNote) strumPlayAnim(false, key);
				goodNoteHit(epicNote);
			} else {
				callOnScripts('onGhostTap', [key]);
				if (canMiss && !boyfriend.stunned) noteMissPress(key);
			}
			Conductor.songPosition = lastTime;
		}

		var spr:StrumNote = playerStrums.members[key];
		if(!strumsBlocked[key] && spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	function inputRelease(key:Int) {
		if (!keysPressed[key]) return;
		fillKeysPressed();
		keysPressed[key] = false;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	var strumsBlocked:Array<Bool> = [];
	function onKeyPress(event:KeyboardEvent):Void {
		if (cpuControlled || !startedCountdown || paused) return;

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (key >= 0 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) inputPress(key);
	}

	function onKeyRelease(event:KeyboardEvent):Void {
		if (cpuControlled || !startedCountdown || paused) return;

		var key:Int = getKeyFromEvent(keysArray, event.keyCode);
		if(key > -1) inputRelease(key);
	}

	function fillKeysPressed() {
		var keybinds:Int = keysArray.length;
		if (strumsBlocked != null) while (strumsBlocked.length < keybinds) strumsBlocked.push(false);
		if (keysPressed != null) while (keysPressed.length < keybinds) keysPressed.push(false);
	}

	function getKeyFromEvent(arr:Array<Dynamic>, key:FlxKey):Int {
		if (key != NONE) for (i in 0...arr.length) for (j in 0...arr[i].length) if(key == arr[i][j]) return i;
		return -1;
	}

	function processInputs():Void {
		if (!startedCountdown) return;

		if(notes.length > 0) {
			notes.forEachAlive((daNote:Note) -> {
				if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.checkHit(Conductor.songPosition))
					opponentNoteHit(daNote);

				if (cpuControlled && !daNote.blockHit && daNote.mustPress && daNote.canBeHit && (daNote.isSustainNote && daNote.prevNote.wasGoodHit ? (daNote.parent == null || daNote.parent.wasGoodHit) : daNote.checkHit(Conductor.songPosition)))
					goodNoteHit(daNote);
				if (cpuControlled || boyfriend.stunned) return;
				if (daNote.isSustainNote && strumsBlocked[daNote.noteData] != true && keysPressed[daNote.noteData % EK.keys(mania)] && (daNote.parent == null || daNote.parent.wasGoodHit) && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
					goodNoteHit(daNote);
			});
		}
	}

	function opponentnoteMiss(daNote:Note):Void {
		notes.forEachAlive((note:Note) -> if (daNote != note && !daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) invalidateNote(note));

		var result:Dynamic = callOnLuas('opponentnoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentnoteMiss', [daNote]);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote.hasMissed) return;
		daNote.hasMissed = true;
		daNote.active = false;

		notes.forEachAlive((note:Note) -> if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) invalidateNote(note));

		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissCommon(direction:Int, ?note:Note) {
		var subtract:Float = .05;
		if(note != null) subtract = note.missHealth;
		health -= subtract * healthLoss;

		if(instakillOnMiss) doDeathCheck(true);
		if(combo > maxCombo) maxCombo = combo;

		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations) {
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;
			char.playAnim('sing' + singAnimations[EK.gfxHud[mania][Std.int(Math.abs(direction))]] + 'miss$suffix', true);
			if(char != gf && combo > 5 && gf != null && gf.animOffsets.exists('sad')) {
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		combo = 0;
		vocals.volume = 0;
	}

	function noteMissPress(direction:Int = 1):Void { //You pressed a key when there was no notes to press for this key
		if(ClientPrefs.getPref('ghostTapping')) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, .2));
		callOnScripts('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void {
		if (!dontZoomCam) camZooming = true;
		vocals.volume = 1;

		var isSus:Bool = note.isSustainNote;
		var leData:Int = Math.floor(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHitPre', [note]);

		note.hitByOpponent = true;

		var animToPlay:String = 'sing' + singAnimations[EK.gfxHud[mania][Std.int(Math.abs(leData))]];
		if(leType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = .6;
		} else if (!note.noAnimation) {
			var altAnim:String = note.animSuffix;
			if (SONG.notes[curSection] != null && SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
				altAnim = '-alt';

			var char:Character = note.gfNote ? gf : dad;
			if(char != null) {
				char.playAnim(animToPlay + altAnim, true);
				char.holdTimer = 0;
			}
		}

		strumPlayAnim(true, leData % EK.keys(mania), Conductor.stepCrochet * 1.25 / 1000);
		if (ClientPrefs.getPref('camMovement') && !bfturn) moveCamOnNote(animToPlay);

		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);
		if (!isSus) invalidateNote(note);
	}

	function moveCamOnNote(singArrows:String) {
		switch (singArrows) {
			case "singLEFT": camlockpoint.set(campoint.x - camMovement, campoint.y);
			case "singDOWN": camlockpoint.set(campoint.x, campoint.y + camMovement);
			case "singUP": camlockpoint.set(campoint.x, campoint.y - camMovement);
			case "singRIGHT": camlockpoint.set(campoint.x + camMovement, campoint.y);
		}

		var camTimer:FlxTimer = new FlxTimer().start();
		camlock = true;
		if(camTimer.finished) {
			camlock = false;
			camFollow.setPosition(campoint.x, campoint.y);
			camTimer = null;
		} 
	}

	function goodNoteHit(note:Note):Void {
		if (note.wasGoodHit || (cpuControlled && note.ignoreNote)) return;
		
		note.wasGoodHit = true;
		if (ClientPrefs.getPref('hitsoundVolume') > 0 && !note.hitsoundDisabled) 
			FlxG.sound.play(Paths.sound('${note.hitsound}'), ClientPrefs.getPref('hitsoundVolume'));

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.floor(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHitPre', [note]);
		
		var animToPlay:String = 'sing' + singAnimations[EK.gfxHud[mania][Std.int(Math.abs(leData))]];
		if (ClientPrefs.getPref('camMovement') && bfturn) moveCamOnNote(animToPlay);

		if(note.hitCausesMiss) {
			if(!note.noMissAnimation && (leType == 'Hurt Note' || leType == 'Kill Note') && boyfriend.animOffsets.exists('hurt')) {
				boyfriend.playAnim('hurt', true);
				boyfriend.specialAnim = true;
			}

			noteMiss(note);
			if(!note.noteSplashDisabled && !isSus) spawnNoteSplashOnNote(note);
			if(!isSus) invalidateNote(note);
			return;
		}

		if (!dontZoomCam) camZooming = true;
		vocals.volume = 1;
		health += note.hitHealth * healthGain;

		if(!note.noAnimation) {
			var char:Character = boyfriend;
			var animCheck:String = 'hey';

			if(note.gfNote) {
				char = gf;
				animCheck = 'cheer';
			}

			if(char != null) {
				char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;
				if(leType == 'Hey!' && char.animOffsets.exists(animCheck)) {
					char.playAnim(animCheck, true);
					char.specialAnim = true;
					char.heyTimer = .6;
				}
			}
		}

		strumPlayAnim(false, leData % EK.keys(mania), cpuControlled ? Conductor.stepCrochet * 1.25 / 1000 : 0);

		if(!isSus) {
			notesHitArray.push(Date.now());
			combo++;
			popUpScore(note);
		}

		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if(!isSus) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.getPref('splashOpacity') > 0 && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				var x:Float = strum.x + EK.swidths[mania] / 2 - Note.swagWidth / 2;
				var y:Float = strum.y + EK.swidths[mania] / 2 - Note.swagWidth / 2;
				spawnNoteSplash(x, y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		splash.ID = grpNoteSplashes.ID++;
		grpNoteSplashes.add(splash);
		grpNoteSplashes.sort(CoolUtil.sortByID);
	}

	public function charactersDance(beat:Int, force:Bool = false):Void {
		for (char in [gf, boyfriend, dad]) {
			if (char == null) continue;
			var speed:Int = (gf != null && char == gf) ? gfSpeed : 1;
			
			if ((char.isAnimationNull() || !char.getAnimationName().startsWith('sing')) && !char.stunned && beat % Math.round(speed * char.danceEveryNumBeats) == 0)
				char.dance(force);
		}
	}

	override function destroy() {
		var luaScript:FunkinLua = null;
		while (luaArray.length > 0) {
			luaScript = luaArray.pop();
			if (luaScript == null) continue;

			luaScript.call('onDestroy', []);
			luaScript.stop();
		}
		FunkinLua.customFunctions.clear();
		var hscript:HScript = null;
		while (hscriptArray.length > 0) {
			hscript = hscriptArray.pop();
			if (hscript == null) continue;

			hscript.executeFunction('onDestroy');
			hscript.destroy();
		}
		for (_ => save in modchartSaves) save.close();

		for (point in [campoint, camlockpoint, ratingAcc, ratingVel]) point = flixel.util.FlxDestroyUtil.put(point);

		@:privateAccess
		if (Std.isOfType(FlxG.game._nextState, PlayState))
			if (FlxG.sound.music != null) FlxG.sound.music.destroy();
		else {
			Paths.clearStoredCache();
			if (FlxG.sound.music != null) FlxG.sound.music.onComplete = null;
		}

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.animationTimeScale = 1;
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		instance = null;
		super.destroy();
	}

	#if VIDEOS_ALLOWED
	function removeVideoSprite(video:backend.VideoSpriteManager) {
		if(members.contains(video)) remove(video, true);
		else forEachOfType(FlxSpriteGroup, (group:FlxSpriteGroup) -> if(group.members.contains(video)) group.remove(video, true));
		video.destroy();
	}
	#end

	var lastStepHit:Int = -1;
	override function stepHit() {
		super.stepHit();

		if(curStep == lastStepHit) return;

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;
	override function beatHit() {
		super.beatHit();

		if(lastBeatHit >= curBeat) return;

		charactersDance(curBeat);
		
		switch (ClientPrefs.getPref('IconBounceType')) {
			case "Old":
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
			case "Psych":
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
			case "Dave":
				var funny:Float = Math.max(Math.min(healthBar.bounded, 1.9), .1);
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + .1))), Std.int(iconP1.height - (25 * funny)));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + .1))), Std.int(iconP2.height - (25 * ((2 - funny) + .1))));
			case "GoldenApple":
				var iconAngle:Float = (curBeat % 2 == 0 ? -15 : 15);
				iconP1.scale.set(1.1, (curBeat % 2 == 0 ? .8 : 1.3));
				iconP2.scale.set(1.1, (curBeat % 2 == 0 ? 1.3 : .8));
	
				FlxTween.angle(iconP1, iconAngle, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, -iconAngle, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
	
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		}
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	override function sectionHit() {
		super.sectionHit();

		if (SONG.notes[curSection] != null) {
			if (generatedMusic && !endingSong && !isCameraOnForcedPos && !ClientPrefs.getPref('UpdateCamSection'))
				moveCameraSection();

			if (ClientPrefs.getPref('camZooms') && camZooming && FlxG.camera.zoom < 1.35) {
				FlxG.camera.zoom += .015 * camZoomingMult;
				camHUD.zoom += .03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM) {
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String) {
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad)) luaToLoad = Paths.getSharedPath(luaFile);
		
		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaToLoad))
		#end
		{
			for (script in luaArray) if(script.scriptName == luaToLoad) return false;
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String) {
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFile);
		
		if(FileSystem.exists(scriptToLoad)) {
			for (hx in hscriptArray) if (hx.origin == scriptToLoad) return false;
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String) {
		function makeError(newScript:HScript) {
			newScript.destroy();
			newScript = null;
			hscriptArray.remove(newScript);
			Logs.trace('failed to initialize hscript interp!!! ($file)', ERROR);
		}
		try {
			var times:Float = Date.now().getTime();
			var newScript:HScript = new HScript(null, file);
			hscriptArray.push(newScript);

			if (newScript.exception != null) {
				var len:Int = newScript.exception.message.indexOf('\n') + 1;
				if(len <= 0) len = newScript.exception.message.length;
				Logs.trace(newScript.exception.toString(), ERROR);
				addTextToDebug('ERROR ON LOADING - ${newScript.exception.message.substr(0, len)}', FlxColor.RED);
				makeError(newScript);
				return;
			}

			if (newScript.variables.exists('onCreate')) {
				newScript.executeFunction('onCreate');
				if (newScript.exception != null) {
					var len:Int = newScript.exception.message.indexOf('\n') + 1;
					if(len <= 0) len = newScript.exception.message.length;
					addTextToDebug('ERROR (onCreate) - ${newScript.exception.message.substr(0, len)}}', FlxColor.RED);
					makeError(newScript);
					return;
				}
			}
			trace('initialized hscript interp successfully: $file (${Std.int(Date.now().getTime() - times)}ms)');
		} catch(e) {
			var len:Int = e.message.indexOf('\n') + 1;
			if(len <= 0) len = e.message.length;
			addTextToDebug('ERROR - ${e.message.substr(0, len)}', FlxColor.RED);
			if (hscriptArray.length > 0) makeError(hscriptArray[hscriptArray.length - 1]);
		}
	}
	#end

	public function callOnScripts(funcToCall:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(event:String, ?args:Array<Any>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray) {
			if(script.closed) {
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName)) continue;

			var ret:Dynamic = script.call(event, args);
			if((ret == LuaUtils.Function_StopLua || ret == LuaUtils.Function_StopAll) && !excludeValues.contains(ret) && !ignoreStops) {
				returnVal = ret;
				break;
			}
			
			if(ret != null && !excludeValues.contains(ret)) returnVal = ret;
			if(script.closed) arr.push(script);
		}

		if(arr.length > 0) for (script in arr) luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1) return returnVal;
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || !script.active || !script.variables.exists(funcToCall) || exclusions.contains(script.origin)) continue;

			try {
				returnVal = script.executeFunction(funcToCall, args);
				if (script.exception != null) {
					script.active = false;
					FunkinLua.luaTrace('ERROR ($funcToCall) - ${script.exception}', true, false, FlxColor.RED);
				} else if((returnVal == LuaUtils.Function_StopHScript || returnVal == LuaUtils.Function_StopAll) && !excludeValues.contains(returnVal) && !ignoreStops) break;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, ?exclusions:Array<String>) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, ?exclusions:Array<String>) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName)) continue;
			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, ?exclusions:Array<String>) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin)) continue;
			script.setVar(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float = 0) {
		final grp = isDad ? opponentStrums : playerStrums;
		var spr:StrumNote = grp.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time / playbackRate;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop) {
			ratingName = '?';
			if(totalPlayed != 0) { // Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				accuracy = MathUtil.floorDecimal(ratingPercent * 100, 2);
				ranks = Rating.GenerateLetterRank(accuracy);

				// Rating Name
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length - 1) {
						final daRating = ratingStuff[i];
						if(ratingPercent < cast daRating[1]) {
							ratingName = daRating[0];
							break;
						}
					}
				else ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
		setOnScripts('rating', ratingPercent);
		setOnScripts('accuracy', accuracy);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingRank', ranks);
		setOnScripts('ratingFC', ratingFC);
	}

	public function getActualPlaybackRate():Float return FlxG.sound.music != null ? FlxG.sound.music.getActualPitch() : playbackRate;

	public dynamic function fullComboFunction() {
		var fullhits = [for(i in 0...ratingsData.length) ratingsData[i].hits];
		ratingFC = 'Clear';
		if(songMisses < 1) {
			if (fullhits[3] > 0 || fullhits[4] > 0) ratingFC = 'FC';
			else if (fullhits[2] > 0) ratingFC = 'GFC';
			else if (fullhits[1] > 0) ratingFC = 'SFC';
			else if (fullhits[0] > 0) ratingFC = "PFC";
		} else if (songMisses < 10) ratingFC = 'SDCB';
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader {
		if(!ClientPrefs.getPref('shaders')) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name)) {
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String) {
		if(!ClientPrefs.getPref('shaders')) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name)) {
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/')) {
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag)) {
				frag = File.getContent(frag);
				found = true;
			} else frag = null;

			if(FileSystem.exists(vert)) {
				vert = File.getContent(vert);
				found = true;
			} else vert = null;

			if(found) {
				runtimeShaders.set(name, [frag, vert]);
				return true;
			}
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
		#else
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end
}