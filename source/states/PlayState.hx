package states;

import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.animation.FlxAnimationController;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxSave;
import openfl.events.KeyboardEvent;
#if VIDEOS_ALLOWED import hxcodec.flixel.FlxVideo as VideoHandler; #end
#if !MODS_ALLOWED import openfl.utils.Assets as OpenFlAssets; #end
import backend.Highscore;
import backend.Song;
import backend.Rating;
import states.editors.*;
import substates.GameOverSubstate;
import substates.PauseSubState;
import objects.Note.EventNote;
import objects.*;
import backend.Section;
import utils.*;
import data.*;
import data.StageData.StageFile;
import data.EkData.Keybinds;
import psychlua.*;
import cutscenes.DialogueBoxPsych;
#if (SScript >= "3.0.0") import tea.SScript; #end
#if sys import sys.FileSystem; #end

class PlayState extends MusicBeatState {
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -271.5;

	public static var ratingStuff:Array<Dynamic> = [
		['Skill issue', .2], //From 0% to 19%
		['Ok', .4], //From 20% to 39%
		['Bad', .5], //From 40% to 49%
		['Bruh', .6], //From 50% to 59%
		['Meh', .69], //From 60% to 68%
		['Nice', .7], //69%
		['Good', .8], //From 70% to 79%
		['Great', .9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Amazing!!', 1]
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
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartGroups:Map<String, ModchartGroup> = new Map<String, ModchartGroup>();
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

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel";
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

	public var notes:FlxTypedGroup<Note>;
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
	public var health:Float = 1;
	public var healthMax:Float = 2;
	public var combo:Int = 0;
	public var maxCombo:Int = 0;

	public var healthBar:Bar;
	var songPercent:Float = 0;

	var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
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
	var extraTxt:FlxText;

	var msTimingTween:FlxTween;
	var mstimingTxt:FlxText = new FlxText(0, 0, 0, "0ms");

	var songNameTxt:FlxText;

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

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var storyDifficultyText:String = "";
	#if discord_rpc
	// Discord RPC variables
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

	public var precacheList:Map<String, String> = new Map<String, String>();

	public var songName:String;

	var downScroll:Bool = ClientPrefs.getPref('downScroll');
	var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
	var hideHud:Bool = ClientPrefs.getPref('hideHud');
	var healthBarAlpha:Float = ClientPrefs.getPref('healthBarAlpha');
	var timeType:String = ClientPrefs.getPref('timeBarType'); 

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	override function create() {
		instance = this;

		startCallback = startCountdown;
		endCallback = endSong;

		firstStart = !MusicBeatState.previousStateIs(PlayState);
		FlxG.fixedTimestep = false;
		persistentUpdate = true;
		persistentDraw = true;

		Conductor.usePlayState = true;
		Conductor.songPosition = Math.NEGATIVE_INFINITY;
		if (firstStart) FlxG.sound.destroy(true);
		Paths.clearStoredCache();

		if (FlxG.sound.music != null) FlxG.sound.music.destroy();
		var music:FlxSound = FlxG.sound.music = new FlxSound();
		music.group = FlxG.sound.defaultMusicGroup;
		music.persist = true;
		music.volume = 1;

		GameOverSubstate.resetVariables();
		PauseSubState.songName = null; //Reset to default

		keysArray = Keybinds.fill();
		fillKeysPressed();
		keysPressed = CoolUtil.dynamicArray(false, keysArray[mania].length);
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camGame.bgColor = 0xFF000000;
		camHUD.bgColor = 0x00000000;
		camOther.bgColor = 0x00000000;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		songName = Paths.formatToSongPath(SONG.song);
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		mania = SONG.mania;
		if (mania < Note.minMania || mania > Note.maxMania)
			mania = Note.defaultMania;

		storyDifficultyText = Difficulty.getString();

		#if discord_rpc
		if (isStoryMode) detailsText = 'Story Mode: ${WeekData.getCurrentWeek().weekName}';
		else detailsText = "Freeplay";
		detailsPausedText = 'Paused - $detailsText';
		#end

		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(songName);
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();

		stageUI = "normal";
		defaultCamZoom = stageData.defaultZoom;
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

		if(stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		if(isPixelStage) introSoundsSuffix = '-pixel';

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage) {
			case 'stage': new states.stages.StageWeek1(); //Week 1
			case 'spooky': new states.stages.Spooky(); //Week 2
			case 'philly': new states.stages.Philly(); //Week 3
			case 'limo': new states.stages.Limo(); //Week 4
			case 'mall': new states.stages.Mall(); //Week 5
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
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'scripts/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder)) {
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
			gf.scrollFactor.set(.95, .95);
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
		if(gf != null) camPos.add(gf.getGraphicMidpoint().x + gf.cameraPosition[0], gf.getGraphicMidpoint().y + gf.cameraPosition[1]);
		
		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null) gf.visible = false;
		}
		stagesFunc((stage:BaseStage) -> stage.createPost());

		uiGroup = new FlxSpriteGroup();
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		comboGroup = new FlxSpriteGroup();

		Conductor.songPosition = -5000 / Conductor.songPosition;

		var showTime:Bool = timeType != 'Disabled';
		timeTxt = new FlxText(0, 19, 400, "", 16);
		timeTxt.screenCenter(X);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = updateTime = showTime;
		if(downScroll) timeTxt.y = FlxG.height - 35;

		if(timeType == 'Song Name') timeTxt.text = SONG.song;
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4) - 2;
		timeBarBG.screenCenter(X);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.addPoint.set(-4, -4);
		uiGroup.add(timeBarBG);
		
		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createGradientBar([FlxColor.GRAY], [dad.getColor(), boyfriend.getColor()], 1, 90);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeTxt);
		
		timeBarBG.sprTracker = timeBar;
		uiGroup.insert(uiGroup.members.indexOf(timeBarBG), timeBar);
		add(comboGroup);
		add(strumLineNotes);
		add(grpNoteSplashes);
		add(uiGroup);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = .000001;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

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

		healthBar = new Bar(0, 0, 'healthBar', () -> return health, 0, healthMax);
		healthBar.y = (downScroll ? 50 : FlxG.height * .9);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !hideHud;
		healthBar.alpha = healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !hideHud;
		iconP1.alpha = healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !hideHud;
		iconP2.alpha = healthBarAlpha;
		uiGroup.add(iconP2);
		reloadHealthBarColors();
		if (ClientPrefs.getPref('HealthTypes') == 'Psych') {
			iconP1.iconType = 'psych';
			iconP2.iconType = 'psych';
		}

		scoreTxt = new FlxText(FlxG.width / 2, Math.floor(healthBar.y + 50), 0);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		scoreTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		if (!downScroll) scoreTxt.y = FlxG.height - scoreTxt.height;
		scoreTxt.visible = !hideHud;
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);
		uiGroup.add(scoreTxt);

		judgementCounter = new FlxText(2, 0, 0, "", 16);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		judgementCounter.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		judgementCounter.scrollFactor.set();
		judgementCounter.visible = ClientPrefs.getPref('ShowJudgementCount') && !hideHud;
		judgementCounter.text = 'Max Combos: 0\nEpics: 0\nSicks: 0\nGoods: 0\nBads: 0\nShits: 0\n' + getMissText(!ClientPrefs.getPref('movemissjudge'), '\n');
		uiGroup.add(judgementCounter);
		judgementCounter.screenCenter(Y);

		botplayTxt = new FlxText(400, healthBar.bg.y + (downScroll ? 100 : -100), 0, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		botplayTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		botplayTxt.scrollFactor.set();
		botplayTxt.visible = cpuControlled;
		botplayTxt.screenCenter(X);
		uiGroup.add(botplayTxt);

		songNameTxt = new FlxText(2, 0, 0, '${SONG.song} - ${storyDifficultyText}' + (playbackRate != 1 ? ' (${playbackRate}x)' : ''), 16);
		songNameTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		songNameTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		songNameTxt.scrollFactor.set();
		songNameTxt.y = FlxG.height - songNameTxt.height;
		songNameTxt.visible = !hideHud;
		uiGroup.add(songNameTxt);

		extraTxt = new FlxText(2, songNameTxt.y, 0, SONG.extraText.trim(), 16);
		extraTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		extraTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		extraTxt.scrollFactor.set();
		extraTxt.visible = !hideHud;
		extraTxt.camera = camHUD;
		uiGroup.add(extraTxt);

		if (extraTxt.text != null && extraTxt.text != "")
			songNameTxt.y -= 20;

		strumLineNotes.camera = camHUD;
		grpNoteSplashes.camera = camHUD;
		notes.camera = camHUD;
		uiGroup.camera = camHUD;
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
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/${Paths.CHART_PATH}/$songName/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder)) {
				if(file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
				if(file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
			}

		startCallback();
		RecalculateRating();

		if(ClientPrefs.getPref('hitsoundVolume') > 0) precacheList.set('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}', 'sound');
		for (i in 1...4) precacheList.set('missnote$i', 'sound');

		if (PauseSubState.songName != null)
			precacheList.set(PauseSubState.songName, 'music');
		else if (ClientPrefs.getPref('pauseMusic') != 'None')
			precacheList.set(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic')), 'music');
		precacheList.set('alphabet', 'image');
		resetRPC();
	
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnScripts('onCreatePost');

		super.create();

		#if (target.threaded && sys)
		Main.current.threadPool.run(() -> {
		#end
			cacheCountdown();
			cachePopUpScore();
			GameOverSubstate.cache();
			for (key => type in precacheList) {
				switch(type) {
					case 'image': Paths.image(key);
					case 'sound': Paths.sound(key);
					case 'music': Paths.music(key);
				}
			}
			Paths.clearUnusedCache();
		#if (target.threaded && sys)
		});
		#end

		if(timeToStart > 0)	clearNotesBefore(timeToStart);
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			var ratio:Float = value / songSpeed; //funny word huh
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

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1) {
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.getPref('safeFrames') / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		return playbackRate = value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += newText.height + 2;
		});

		luaDebugGroup.add(newText);
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.setColors(dad.getColor(), boyfriend.getColor());
		timeBar.createGradientBar([FlxColor.GRAY], [dad.getColor(), boyfriend.getColor()], 1, 90);
		timeBar.updateBar();
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
					newGf.scrollFactor.set(0.95, 0.95);
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
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush) {
			for (script in luaArray) {
				if(script.scriptName == luaFile) {
					doPush = false;
					break;
				}
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
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(FileSystem.exists(scriptFile)) doPush = true;
		}
		
		if(doPush) {
			if(SScript.global.exists(scriptFile)) doPush = false;
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
			char.scrollFactor.set(.95, .95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String) {
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		if(!#if sys FileSystem #else OpenFlAssets #end.exists(filepath)) {
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:VideoHandler = new VideoHandler();
		video.play(filepath);
		video.onEndReached.add(() -> {
			video.dispose();
			startAndEnd();
			return;
		}, true);
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	public function startAndEnd() {
		if(endingSong) endSong();
		else startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void {
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.finishThing = () -> {
				psychDialogue = null;
				if(endingSong) endSong();
				else startCountdown();
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
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['${stageUI}UI/countdown/ready-pixel', '${stageUI}UI/countdown/set-pixel', '${stageUI}UI/countdown/date-pixel'];
			case "normal": ["countdown/ready", "countdown/set" , "countdown/go"];
			default: ['${stageUI}UI/countdown/ready', '${stageUI}UI/countdown/set', '${stageUI}UI/countdown/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);
		
		for (count in ['3', '2', '1', 'Go'])
			Paths.sound('countdown/intro$count' + introSoundsSuffix);
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

		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if (ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			updateLuaDefaultPos();
	
			setOnScripts('defaultMania', SONG.mania);

			startedCountdown = true;
			Conductor.songPosition -= Conductor.crochet * 5;
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

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, (tmr:FlxTimer) -> {
				charactersDance();

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/countdown/ready-pixel', '${stageUI}UI/countdown/set-pixel', '${stageUI}UI/countdown/date-pixel'];
					case "normal": ["countdown/ready", "countdown/set", "countdown/go"];
					default: ['${stageUI}UI/countdown/ready', '${stageUI}UI/ountdown/set', '${stageUI}UI/countdown/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var tick:Countdown = THREE;
				switch(swagCounter) {
					case 0:
						FlxG.sound.play(Paths.sound('countdown/intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0]);
						FlxG.sound.play(Paths.sound('countdown/intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1]);
						FlxG.sound.play(Paths.sound('countdown/intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2]);
						FlxG.sound.play(Paths.sound('countdown/introGo' + introSoundsSuffix), 0.6);
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
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.camera = camHUD;
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (isPixelStage) spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = (ClientPrefs.getPref('Antialiasing') && !isPixelStage);
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: (twn:FlxTween) -> {
				remove(spr, true);
				spr.destroy();
			}
		});
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

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false) {
		var ret:Dynamic = callOnScripts('onUpdateScore', [miss]);
		if(ret == FunkinLua.Function_Stop) return;

		judgementCounter.text = 'Max Combos: ${maxCombo}';
		for (rating in ratingsData)
			judgementCounter.text += '\n${flixel.addons.ui.U.FU(rating.name)}s: ${rating.hits}';
		judgementCounter.text += '\n${getMissText(!ClientPrefs.getPref('movemissjudge'), '\n')}';
		judgementCounter.screenCenter(Y);
		if (!ClientPrefs.getPref('ShowNPSCounter')) UpdateScoreText();
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

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void {
		startingSong = false;

		var music:FlxSound = FlxG.sound.music;
		music.loadEmbedded(Paths.inst(SONG.song), false);
		music.onComplete = finishSong.bind();
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

		if(paused) {
			music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = music.length;
		FlxTween.tween(timeBar, {alpha: 1}, .5 * playbackRate, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, .5 * playbackRate, {ease: FlxEase.circOut});

		#if discord_rpc Discord.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter(), true, songLength); #end
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

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		var inst = Paths.inst(songData.song);
		songLength = inst != null ? inst.length : 0;

		vocals = new FlxSound();
		if (SONG.needsVoices) vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		vocals.group = FlxG.sound.defaultMusicGroup;
		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		add(notes = new FlxTypedGroup<Note>());
		var noteData:Array<SwagSection>;
		noteData = songData.notes;

		var file:String = Paths.json('${Paths.CHART_PATH}/$songName/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson('${Paths.CHART_PATH}/$songName/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length) makeEvent(event, i);
		}

		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % Note.ammo[mania]);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > Note.ammo[mania] - 1)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1) {
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						sustainNote.correctionOffset = swagNote.height / 2;

						if(!isPixelStage) {
							if(oldNote.isSustainNote) {
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
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
							if (daNoteData > Note.separator[mania]) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2;
				else if(middleScroll) {
					swagNote.x += 310;
					if(daNoteData > Note.separator[mania])
						swagNote.x += FlxG.width / 2 + 25;
				}

				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);
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

			case 'Play Sound':
				precacheList.set(event.value1, 'sound');
				Paths.sound(event.value1);
		}
		stagesFunc((stage:BaseStage) -> stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue)
			return returnedValue;

		switch(event.event) {
			case 'Kill Henchmen': return 280;
		}
		return 0;
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

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
		var targetAlpha:Float = 1;
		if (player < 1) {
			if (!ClientPrefs.getPref('opponentStrums')) targetAlpha = 0;
			else if (middleScroll) targetAlpha = .35;
		}
		
		for (i in 0...Note.ammo[mania]) {
			var twnDuration:Float = (4 / mania) * playbackRate;
			var twnStart:Float = .5 + ((.8 / mania) * i) * playbackRate;

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = downScroll;

			if (arrowStartTween || ((!isStoryMode || restarted || firstStart || deathCounter > 0) && !skipArrowStartTween) && mania > 1) {
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
			} else babyArrow.alpha = targetAlpha;

			if (player < 1 && middleScroll) {
				babyArrow.x += 310;
				if(i > Note.separator[mania]) //Up and Right
					babyArrow.x += FlxG.width / 2 + 25;
			}

			grp.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
			callOnScripts('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);

			if (ClientPrefs.getPref('showKeybindsOnStart') && player == 1) {
				for (j in 0...keysArray[mania][i].length) {
					var daKeyTxt:FlxText = new FlxText(babyArrow.x, babyArrow.y - 10, 0, backend.InputFormatter.getKeyName(keysArray[mania][i][j]), 32 - mania);
					daKeyTxt.setFormat(Paths.font("vcr.ttf"), 32 - mania, FlxColor.WHITE, CENTER);
					daKeyTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1.25);
					daKeyTxt.alpha = 0;
					var textY:Float = (j == 0 ? babyArrow.y - 32 : ((babyArrow.y - 32) + babyArrow.height) - daKeyTxt.height);
					daKeyTxt.setPosition(babyArrow.x + ((babyArrow.width - daKeyTxt.width) / 2), textY);
					add(daKeyTxt);
					daKeyTxt.camera = camHUD;

					if (mania > 1 && !skipArrowStartTween)
						FlxTween.tween(daKeyTxt, {y: textY + 32, alpha: 1}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
					else {
						daKeyTxt.y += 16;
						daKeyTxt.alpha = 1;
					}
					new FlxTimer().start(Conductor.crochet * .001 * 12, (_) -> {
						FlxTween.tween(daKeyTxt, {y: daKeyTxt.y + 32, alpha: 0}, twnDuration, {ease: FlxEase.circIn, startDelay: twnStart, 
						onComplete: (t) -> remove(daKeyTxt)});
					});
				}
			}
		}
	}

	function updateNote(note:Note) {
		var tMania:Int = mania + 1;
		var noteData:Int = note.noteData;

		note.scale.set(1, 1);
		note.updateHitbox();

		if (isPixelStage) {
			if (note.isSustainNote) note.originalHeight = note.height;
			note.setGraphicSize(Std.int(note.width * daPixelZoom * Note.pixelScales[mania]));
		} else {
			note.setGraphicSize(Std.int(note.width * Note.scales[mania]));
			note.updateHitbox();
		}

		note.updateHitbox();

		var prevNote:Note = note.prevNote;
		if (note.isSustainNote && prevNote != null) {
			note.offsetX += note.width / 2;
			note.animation.play(Note.keysShit.get(mania).get('letters')[noteData] + ' tail');
			note.updateHitbox();
			note.offsetX -= note.width / 2;

			if (note != null && prevNote != null && prevNote.isSustainNote && prevNote.animation != null) {
				prevNote.animation.play(Note.keysShit.get(mania).get('letters')[noteData % tMania] + ' hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				prevNote.scale.y *= songSpeed;

				if(isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / note.height);
				}
				prevNote.updateHitbox();
			}

			if (isPixelStage) {
				prevNote.scale.y *= daPixelZoom * Note.pixelScales[mania]; //Fuck urself
				prevNote.updateHitbox();
			}
		} else if (!note.isSustainNote && noteData > - 1 && noteData < tMania)
			if (note.changeAnim) note.animation.play(Note.keysShit.get(mania).get('letters')[noteData % tMania]);
		
		if (note.changeColSwap) {
			var hsvNumThing = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData % tMania]);
			var colSwap = note.colorSwap;

			var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
			colSwap.hue = arrowHSV[hsvNumThing][0] / 360;
			colSwap.saturation = arrowHSV[hsvNumThing][1] / 100;
			colSwap.brightness = arrowHSV[hsvNumThing][2] / 100;
		}
	}

	public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false) {
		var daOldMania = mania;
		mania = newValue;

		if (!skipStrumFadeOut) {
			for (i in 0...strumLineNotes.members.length) {
				var oldStrum:FlxSprite = strumLineNotes.members[i].clone();
				oldStrum.setPosition(strumLineNotes.members[i].x, strumLineNotes.members[i].y);
				oldStrum.alpha = strumLineNotes.members[i].alpha;
				oldStrum.scrollFactor.set();
				oldStrum.camera = camHUD;
				oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[daOldMania]));
				oldStrum.updateHitbox();
				add(oldStrum);

				FlxTween.tween(oldStrum, {alpha: 0}, .3, {onComplete: (_) -> remove(oldStrum)});
			}
		}

		playerStrums.clear();
		opponentStrums.clear();
		strumLineNotes.clear();
		setOnScripts('defaultMania', mania);

		notes.forEachAlive((note:Note) -> updateNote(note));

		for (noteI in 0...unspawnNotes.length)
			updateNote(unspawnNotes[noteI]);
		callOnScripts('onChangeMania', [mania, daOldMania]);

		generateStaticArrows(0);
		generateStaticArrows(1);
		updateLuaDefaultPos();
	}

	override function openSubState(SubState:FlxSubState) {
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
		stagesFunc((stage:BaseStage) -> stage.closeSubState());
		if (paused) {
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {if (!tmr.finished) tmr.active = true;});
			FlxTween.globalManager.forEach((twn:FlxTween) -> {if (!twn.finished) twn.active = true;});

			paused = false;
			callOnScripts('onResume');

			#if discord_rpc resetRPC(startTimer != null && startTimer.finished); #end
		}

		super.closeSubState();
	}

	override public function onFocus():Void {
		callOnScripts('onFocus');
		#if discord_rpc
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.);
		#end
		super.onFocus();
		callOnScripts('onFocusPost');
	}

	override public function onFocusLost():Void {
		callOnScripts('onFocusLost');
		#if discord_rpc
		if (health > 0 && !paused && !tryPause())
			Discord.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
		#end
		super.onFocusLost();
		callOnScripts('onFocusLostPost');
	}

	override public function onResize(width:Int, height:Int):Void {
		callOnScripts('onResize', [width, height]);
		super.onResize(width, height);
		callOnScripts('onResizePost', [width, height]);
	}

	function resetRPC(?cond:Bool = false) {
		#if desktop
		if (cond) Discord.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
		else Discord.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
		#end
	}

	function resyncVocals(resync:Bool = true):Void {
		if (finishTimer != null || (transitioning && endingSong)) return;
		FlxG.sound.music.pitch = playbackRate;

		if (Conductor.songPosition <= vocals.length) {
			var stream = vocals.vorbis != null;
			vocals.pitch = playbackRate;

			if (!stream || resync) {
				if (stream) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				Conductor.songPosition = (vocals.time = FlxG.sound.music.time) + Conductor.offset;
			} else Conductor.songPosition = lastSongTime + Conductor.offset;
			vocals.play();
		} else Conductor.songPosition = lastSongTime + Conductor.offset;

		var diff = lastSongTime - Conductor.songPosition;
		if (diff < songElapsed && diff >= 0) {
			var v = Conductor.songPosition;
			Conductor.songPosition = lastSongTime;
			lastSongTime = v;
		} else lastSongTime = Conductor.songPosition;
		FlxG.sound.music.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var lastSongTime:Float = 0;
	var songElapsed:Float = 0;
	var syncDebounce:Float = 0;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.playing) {
			var time = FlxG.sound.music.time;
			songElapsed = time - lastSongTime;
			lastSongTime = time;
		}

		callOnScripts('onUpdate', [elapsed]);
		
		if (startedCountdown && !paused) {
			var delta = elapsed * 1000 * playbackRate;
			if (!startingSong && FlxG.sound.music.playing && songElapsed > 0)
				Conductor.songPosition = lastSongTime;
			else Conductor.songPosition += delta;

			if (!startingSong && (syncDebounce += elapsed) > 1) {
				syncDebounce = 0;
				var resync = vocals.loaded && Math.abs(vocals.time - FlxG.sound.music.time) > (vocals.vorbis == null ? 6 : 12);
				if (Math.abs(lastSongTime - Conductor.songPosition) > 16 || resync)
					resyncVocals(resync);
			}
		}

		if(ClientPrefs.getPref('camMovement') && !isPixelStage)
			if(camlock) camFollow.setPosition(camlockpoint.x, camlockpoint.y);
		
		FlxG.camera.followLerp = 0;
		if(!inCutscene && !paused)
			FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * cameraSpeed * playbackRate / (FlxG.updateFramerate / 60), 0, 1);

		checkEventNote();

		if (generatedMusic && !endingSong && !isCameraOnForcedPos && ClientPrefs.getPref('UpdateCamSection'))
			moveCameraSection();
		super.update(elapsed);

		scoreTxt.x = Math.floor((FlxG.width - scoreTxt.width) / 2);
		if (ClientPrefs.getPref('ShowNPSCounter')) {
			for(i in 0...notesHitArray.length) {
				var cock:Date = notesHitArray[i];
				if (cock != null && cock.getTime() + (1000 / playbackRate) < Date.now().getTime())
					notesHitArray.remove(cock);
			}
			nps = Math.floor(notesHitArray.length);
			if (nps > maxNPS) maxNPS = nps;
			UpdateScoreText();
		}

		updateMusicBeat();
		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE) tryPause();

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene)
			openChartEditor();

		switch(ClientPrefs.getPref('IconBounceType')) {
			case "Vanilla":
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, .85)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, .85)));
			case "Kade": // Stolen from Vanilla Engine
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, .5)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, .5)));
			case "Psych":
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP1.scale.set(mult, mult);
				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP2.scale.set(mult, mult);
			case "Dave":
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, .88)), Std.int(FlxMath.lerp(150, iconP1.height, .88)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, .88)), Std.int(FlxMath.lerp(150, iconP2.height, .88)));
		}
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		final iconOffset:Int = 26;
		if (healthBar.bounds.max != null)
			if (health > healthBar.bounds.max) health = healthBar.bounds.max;
		else if (health > healthMax) health = healthMax;
		if (practiceMode && health < 0) health = 0;

		if (iconP1.moves) iconP1.x = (iconP1.iconType == 'psych' ? healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset : healthBar.barCenter - iconOffset);
		if (iconP2.moves) iconP2.x = (iconP2.iconType == 'psych' ? healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2 : healthBar.barCenter - (iconP2.width - iconOffset));

		if (healthBar.percent < 20) {
			iconP1.setState(1);
			iconP2.setState(2);
		} else if (healthBar.percent > 80) {
			iconP1.setState(2);
			iconP2.setState(1);
		} else {
			iconP1.setState(0);
			iconP2.setState(0);
		}

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene)
			openCharacterEditor();

		if (startingSong) {
			if (startedCountdown && Conductor.songPosition >= 0) startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		} else if (!paused && updateTime) {
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
			songPercent = curTime / songLength;
			var songCalc:Float = songLength - curTime;

			switch (timeType) {
				case 'Time Elapsed' | 'Time Position' | 'Name Elapsed' | 'Name Time Position':
					songCalc = curTime;
			}

			var secondsTotal:Int = Math.floor(Math.max(0, (songCalc / playbackRate) / 1000));
			var formattedsec:String = CoolUtil.formatTime(secondsTotal);
			var timePos:String = '$formattedsec / ' + CoolUtil.formatTime(Math.floor((songLength / playbackRate) / 1000));
			if (timeType != 'Song Name')
				switch (timeType) {
					case 'Time Left' | 'Time Elapsed': timeTxt.text = formattedsec;
					case 'Time Position': timeTxt.text = timePos;
					case 'Name Left' | 'Name Elapsed': timeTxt.text = '${SONG.song} ($formattedsec)';
					case 'Name Time Position': timeTxt.text = '${SONG.song} ($timePos)';
					case 'Name Percent': timeTxt.text = '${SONG.song} (${timeBar.percent}%)';
				}
		}

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultCamZoom, FlxMath.bound(elapsed * 3.125 * camZoomingDecay * playbackRate, 0, 1));
			camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, FlxMath.bound(elapsed * 3.125 * camZoomingDecay * playbackRate, 0, 1));
		}

		#if debug
		FlxG.watch.addQuick("sectionShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		#end

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.getPref('noReset') && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
			health = 0;
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

				if (!boyfriend.stunned && boyfriend.animation.curAnim != null && (cpuControlled || !keysPressed.contains(true) || endingSong)) {
					var canDance = boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss');
					if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * boyfriend.singDuration && canDance)
						boyfriend.dance();
				}
				
				if(notes.length > 0) {
					if(startedCountdown) renderNotes();
					else {
						notes.forEachAlive((daNote:Note) -> {
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
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

			// Kill extremely late notes and cause misses
			if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
				if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
					noteMiss(daNote);
				if (!daNote.mustPress && daNote.ignoreNote && !endingSong)
					opponentnoteMiss(daNote);
			
				daNote.active = false;
				daNote.visible = false;
			
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		});
	}

	function tryPause():Bool {
		if (startedCountdown && canPause) {
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
				return true;
			}
		}
		return false;
	}

	function openPauseMenu() {
		for (i in 0...keysPressed.length)
			if (keysPressed[i]) inputRelease(i);

		FlxG.camera.followLerp = 0;
		FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {
			if (!tmr.finished) tmr.active = false;
		});
		FlxTween.globalManager.forEach((twn:FlxTween) -> {
			if (!twn.finished) twn.active = false;
		});
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

		#if discord_rpc
		Discord.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
		#end
	}

	function openChartEditor() {
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		chartingMode = true;

		#if discord_rpc
		Discord.changePresence("Chart Editor", null, null, true);
		Discord.resetClientID();
		#end
		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor() {
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		#if desktop Discord.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead) {
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollow.x, camFollow.y));

				#if discord_rpc
				Discord.changePresence('Game Over - $detailsText', '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
				#end
				return isDead = true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) return;

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				var value = switch(value1.toLowerCase().trim()) {
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
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

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

					if(duration > 0 && intensity != 0)
						targetsArray[i].shake(intensity, duration * playbackRate);
				}

			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = (value2 == "true");

				newMania = Std.parseInt(value1);
				if(Math.isNaN(newMania) && newMania < Note.minMania && newMania > Note.maxMania)
					newMania = 0;
				changeMania(newMania, skipTween);

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
							if(!boyfriendMap.exists(value2))
								addCharacterToList(value2, charType);

							var lastVisible:Bool = boyfriend.visible;
							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = lastVisible;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2))
								addCharacterToList(value2, charType);

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
								if(!gfMap.exists(value2))
									addCharacterToList(value2, charType);

								var lastVisible:Bool = gf.visible;
								gf.visible = false;
								gf = gfMap.get(value2);
								gf.visible = lastVisible;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Extra Text Change':
				if (extraTxt.text != null)
					if (songNameTxt.y != songNameTxt.y - 20)
						songNameTxt.y -= 20;

				extraTxt.text = value1;
				if(extraTxt.text == null || extraTxt.text == "")
					songNameTxt.y = FlxG.height - songNameTxt.height;
				else songNameTxt.y = (FlxG.height - songNameTxt.height) - 20;

			case 'Change Scroll Speed':
				if (songSpeedType != "constant") {
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0) songSpeed = newValue;
					else songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear,
						onComplete: (twn:FlxTween) -> songSpeedTween = null
					});
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
					if (killMe.length > 1)
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe, true, true), killMe[killMe.length - 1], trueVal != null ? trueVal : value2);
					else LuaUtils.setVarInArray(this, value1, trueVal != null ? trueVal : value2);	
				} catch(e:Dynamic) addTextToDebug('ERROR ("Set Property" Event) - $e', FlxColor.RED);
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		}
		stagesFunc((stage:BaseStage) -> stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	function moveCameraSection():Void {
		var section = SONG.notes[curSection];
		if (section == null) return;

		if (gf != null && section.gfSection) {
			moveCamera('gf');
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var camCharacter:String = (!section.mustHitSection ? 'dad' : 'boyfriend');
		moveCamera(camCharacter);
		if(ClientPrefs.getPref('camMovement') && !isPixelStage) {
			campoint.set(camFollow.x, camFollow.y);
			bfturn = (camCharacter == 'boyfriend');
			camlock = false;
		}
		callOnScripts('onMoveCamera', [camCharacter]);
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
		if (cameraTwn == null && camGame.zoom != zoom) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: zoom}, (Conductor.stepCrochet * 4 / 1000) * playbackRate, {ease: FlxEase.elasticInOut, 
				onComplete: (_) -> cameraTwn = null
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void {
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.getPref('noteOffset') <= 0 || ignoreNoteOffset)
			endCallback();
		else finishTimer = new FlxTimer().start(ClientPrefs.getPref('noteOffset') / 1000, (tmr:FlxTimer) -> {endCallback();});
	}

	public var transitioning = false;
	public function endSong() {
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach((daNote:Note) -> {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			}

			if(doDeathCheck()) return false;
		}

		timeBarBG.visible = timeBar.visible = timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;
		restarted = false;

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			if(!practiceMode && !cpuControlled) {
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				Highscore.saveCombo(SONG.song, '$ratingFC, $ratingName', storyDifficulty);
			}
			playbackRate = 1;
			vocals.volume = 0;
			vocals.stop();

			if (chartingMode) {
				openChartEditor();
				return false;
			}

			if (isStoryMode) {
				campaignScore += songScore;
				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if desktop Discord.resetClientID(); #end

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn)
						CustomFadeTransition.nextCamera = null;
					MusicBeatState.switchState(new StoryMenuState());

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

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			} else {
				Mods.loadTopMod();
				#if desktop Discord.resetClientID(); #end

				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn)
					CustomFadeTransition.nextCamera = null;
				MusicBeatState.switchState(new FreeplayState());
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
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
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
		var uiSuffix:String = '';
		if (stageUI != "normal") {
			uiPrefix = '${stageUI}UI/';
			if (isPixelStage) uiSuffix = '-pixel';
		}

		for (rating in ratingsData) Paths.image(uiPrefix + 'ratings/${rating.image}' + uiSuffix);
		for (i in 0...10) Paths.image(uiPrefix + 'number/num$i' + uiSuffix);
		for (miscRatings in ['combo', 'early', 'late']) Paths.image(uiPrefix + 'ratings/$miscRatings' + uiSuffix);
	}

	var scoreSeparator:String = "|";
	function getMissText(hidden:Bool = false, sepa:String = ' '):String {
		if (cpuControlled || hidden) return '';
		var breakText = (ClientPrefs.getPref('ScoreType') == 'Kade' ? 'Combo Breaks' : 'Breaks');
		return '${sepa != '\n' ? '$scoreSeparator $breakText:' : '$breakText: '}$songMisses' + sepa;
	}

	var updateScoreText:Bool = true;
	function UpdateScoreText() {
		var tempText:String = (!ClientPrefs.getPref('ShowNPSCounter') ? '' : 'NPS:$nps (Max:$maxNPS) $scoreSeparator ');
		var tempMiss:String = getMissText(ClientPrefs.getPref('movemissjudge'));
		
		tempText += 'Score:$songScore';
		tempText += tempMiss;
		switch(ClientPrefs.getPref('ScoreType')) {
			case 'Alter': tempText += '$scoreSeparator Acc:$accuracy%' + (ratingName != '?' ? ' | [$ratingName, $ratingFC] • $ranks' : ' | [?, ?] • F');
			case 'Kade': tempText += '$scoreSeparator Accuracy:$accuracy%' + (ratingName != '?' ? ' $scoreSeparator ($ratingFC) $ratingName' : ' $scoreSeparator N/A');
		}
		if (updateScoreText) scoreTxt.text = tempText;
	}

	function popUpScore(note:Note):Void {
		if (note == null) return;

		var noteDiff = getNoteDiff(note);
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);
		var score:Int = 500;

		var daTiming:String = "";
		var msTiming:Float = 0;

		note.ratingMod = daRating.ratingMod;
		note.rating = daRating.name;
		score = daRating.score;

		if(!note.ratingDisabled) daRating.hits++;
		totalNotesHit += (ClientPrefs.getPref('complexAccuracy') ? backend.EtternaFunctions.wife3(-noteDiff) : daRating.ratingMod);

		if(daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note);

		if (noteDiff > Conductor.safeZoneOffset * .1)
			daTiming = "early";
		else if (noteDiff < Conductor.safeZoneOffset * -.1)
			daTiming = "late";

		songScore += score;
		if(!note.ratingDisabled) {
			songHits++;
			totalPlayed++;
			RecalculateRating();
		}
		if (ClientPrefs.getPref('ShowCombo')) {
			var placement:Float = FlxG.width * 0.35;
			
			if (!ClientPrefs.getPref('comboStacking') && comboGroup.members.length > 0) {
				for (spr in comboGroup) {
					if(spr != mstimingTxt) spr.destroy();
					comboGroup.remove(spr);
				}
			}

			var uiPrefix:String = '';
			var uiSuffix:String = '';
			var antialias:Bool = ClientPrefs.getPref('Antialiasing');
			
			if (isPixelStage) {
				uiPrefix = 'pixelUI/';
				if (isPixelStage) uiSuffix = '-pixel';
				antialias = !isPixelStage;
			}
		
			var comboOffset:Array<Array<Int>> = ClientPrefs.getPref('comboOffset');

			var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'ratings/' + daRating.image + uiSuffix));
			rating.screenCenter();
			rating.x = placement - 40 + comboOffset[0][0];
			rating.y -= 60 - comboOffset[0][1];
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.subtract(FlxG.random.int(0, 10) * playbackRate, FlxG.random.int(140, 175) * playbackRate);
			rating.visible = !hideHud && showRating;
			rating.antialiasing = antialias;
		
			var timing:FlxSprite = new FlxSprite();
			if (daTiming != "") timing.loadGraphic(Paths.image(uiPrefix + 'ratings/$daTiming' + uiSuffix));
			timing.screenCenter();
			timing.x = placement - 130 + comboOffset[3][0];
			timing.y -= comboOffset[3][1];
			timing.acceleration.y = 550 * playbackRate * playbackRate;
			timing.velocity.subtract(FlxG.random.int(0, 10) * playbackRate, FlxG.random.int(140, 175) * playbackRate);
			timing.visible = !hideHud && ClientPrefs.getPref('ShowLateEarly');
			timing.antialiasing = antialias;
		
			if (ClientPrefs.getPref('ShowMsTiming') && mstimingTxt != null) {
				msTiming = MathUtil.truncateFloat(noteDiff / getActualPlaybackRate());
				mstimingTxt.setFormat(flixel.system.FlxAssets.FONT_DEFAULT, 20, FlxColor.WHITE, CENTER);
				mstimingTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
				mstimingTxt.visible = !hideHud;
				mstimingTxt.text = '${msTiming}ms';
				mstimingTxt.color = SpriteUtil.dominantColor(rating);
				comboGroup.add(mstimingTxt);
			}
		
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'ratings/combo' + uiSuffix));
			comboSpr.screenCenter();
			comboSpr.x = placement + comboOffset[2][0];
			comboSpr.y -= comboOffset[2][1];
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboSpr.visible = showCombo && !hideHud;
			comboSpr.antialiasing = antialias;
		
			if (ClientPrefs.getPref('ShowMsTiming')) {
				mstimingTxt.screenCenter();
				var comboShowSpr:FlxSprite = (combo >= 10 ? comboSpr : rating);
				mstimingTxt.setPosition(comboShowSpr.x + 100, comboShowSpr.y + (combo >= 10 ? 80 : 100));
				mstimingTxt.updateHitbox();
			}
		
			if (daTiming != "" && ClientPrefs.getPref('ShowLateEarly'))
				comboGroup.add(timing);
		
			for (daRatings in [rating, comboSpr, timing]) {
				if (!isPixelStage)
					daRatings.setGraphicSize(Std.int(daRatings.width * .7));
				else daRatings.setGraphicSize(Std.int(daRatings.width * daPixelZoom * .85));
			}
		
			comboSpr.updateHitbox();
			rating.updateHitbox();
			timing.updateHitbox();
		
			var seperatedScore:Array<Int> = [];
			var comboSplit:Array<String> = Std.string(Math.abs(combo)).split('');
		
			for (i in 0...comboSplit.length)
				seperatedScore.push(Std.parseInt(comboSplit[i]));
		
			var daLoop:Int = 0;
			for (i in seperatedScore) {
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'number/num$i' + uiSuffix));
				numScore.screenCenter();
				numScore.x = placement + (43 * daLoop) - 90 + comboOffset[1][0];
				numScore.y += 80 - comboOffset[1][1];
			
				if (!isPixelStage)
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				numScore.updateHitbox();
			
				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				numScore.visible = !hideHud;
				numScore.antialiasing = antialias;
			
				if(combo >= 10) comboGroup.add(comboSpr);
				comboGroup.add(rating);
				if(showComboNum) comboGroup.add(numScore);
			
				FlxTween.tween(numScore, {alpha: 0}, .2 / playbackRate, {
					onComplete: (tween:FlxTween) -> {
						remove(numScore, true); numScore.destroy();
					}, startDelay: Conductor.crochet * .002 / playbackRate
				});
			
				daLoop++;
			}
		
			FlxTween.tween(rating, {alpha: 0}, .2 / playbackRate, {
				onComplete: (tween:FlxTween) -> {
					remove(rating, true); rating.destroy();
				}, startDelay: Conductor.crochet * .001 / playbackRate
			});
		
			if (ClientPrefs.getPref('ShowLateEarly')) {
				FlxTween.tween(timing, {alpha: 0}, .2 / playbackRate, {
					onComplete: (tween:FlxTween) -> {
						remove(timing, true); timing.destroy();
					}, startDelay: Conductor.crochet * .001 / playbackRate
				});
			}
		
			if (ClientPrefs.getPref('ShowMsTiming')) {
				if (msTimingTween != null) {
					mstimingTxt.alpha = 1;
					msTimingTween.cancel();
				}
				msTimingTween = FlxTween.tween(mstimingTxt, {alpha: 0}, .2 / playbackRate, {
					startDelay: Conductor.crochet * .001 / playbackRate
				});
			}
		
			FlxTween.tween(comboSpr, {alpha: 0}, .2 / playbackRate, {
				onComplete: (tween:FlxTween) -> {
					remove(comboSpr, true); comboSpr.destroy();
				}, startDelay: Conductor.crochet * .002 / playbackRate
			});
		}
	}

	static function getNoteDiff(note:Note = null):Float {
		var noteDiffTime:Float = note.strumTime - Conductor.songPosition;
		return switch(ClientPrefs.getPref('NoteDiffTypes')) {
			case 'Psych': Math.abs(noteDiffTime + ClientPrefs.getPref('ratingOffset')) / instance.getActualPlaybackRate();
			case 'Simple': noteDiffTime;
			default: 0;
		}
	}

	function inputPress(key:Int) {
		fillKeysPressed();
		keysPressed[key] = true;

		//more accurate hit time for the ratings?
		if(notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong) {
			var lastTime:Float = Conductor.songPosition;
			if (FlxG.sound.music != null && FlxG.sound.music.playing && !startingSong)
				if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

			var sortedNotesList:Array<Note> = [];				
			var canMiss:Bool = !ClientPrefs.getPref('ghostTapping');

			for (daNote in notes) {
				if (!strumsBlocked[daNote.noteData] && daNote.mustPress && daNote.exists && !daNote.blockHit && !daNote.tooLate) {
					if (!daNote.isSustainNote && !daNote.wasGoodHit) {
						if (!daNote.canBeHit && daNote.checkDiff(Conductor.songPosition)) daNote.update(0);
						if (daNote.canBeHit) {
							if (daNote.noteData == key) sortedNotesList.push(daNote);
							canMiss = !ClientPrefs.getPref('AntiMash');
						} else if (daNote.isSustainNote && daNote.noteData == key && ((daNote.wasGoodHit || daNote.prevNote.wasGoodHit) && (daNote.parent != null && !daNote.parent.hasMissed && daNote.parent.wasGoodHit)))
							sortedNotesList.push(daNote);
					}
				}
			}
			sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			if (sortedNotesList.length > 0) {
				var epicNote:Note = sortedNotesList[0];
				if (sortedNotesList.length > 1) {
					for (bad in 1...sortedNotesList.length) {
						var doubleNote:Note = sortedNotesList[bad];
						if (doubleNote.noteData != epicNote.noteData) break;

						if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
							notes.remove(doubleNote, true);
							doubleNote.destroy();
							break;
						} else if (doubleNote.strumTime < epicNote.strumTime) {
							epicNote = doubleNote; 
							break;
						}
					}
				}

				// eee jack detection before was not super good
				if (epicNote.isSustainNote)
					strumPlayAnim(false, key);
				goodNoteHit(epicNote);
			} else {
				callOnScripts('onGhostTap', [key]);
				if (canMiss && !boyfriend.stunned) noteMissPress(key);
			}
			Conductor.songPosition = lastTime;
		}

		if (!strumsBlocked[key]) {
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm') {
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		callOnScripts('onKeyPress', [key]);
	}

	function inputRelease(key:Int) {
		if (!keysPressed[key]) return;
		fillKeysPressed();
		keysPressed[key] = false;

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

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(key > -1) inputRelease(key);
	}

	function fillKeysPressed() {
		var keybinds:Int = keysArray[mania].length;
		if (strumsBlocked != null) while (strumsBlocked.length < keybinds) strumsBlocked.push(false);
		if (keysPressed != null) while (keysPressed.length < keybinds) keysPressed.push(false);
	}

	function getKeyFromEvent(arr:Array<Dynamic>, key:FlxKey):Int {
		if (key != NONE) {
			for (i in 0...arr[mania].length)
				for (j in 0...arr[mania][i].length)
					if(key == arr[mania][i][j]) return i;
		}
		return -1;
	}

	function processInputs():Void {
		if (!startedCountdown) return;

		if(notes.length > 0) {
			notes.forEachAlive((daNote:Note) -> {
				if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.checkHit(Conductor.songPosition))
					opponentNoteHit(daNote);

				if (cpuControlled && !daNote.blockHit && daNote.mustPress && daNote.canBeHit && (daNote.isSustainNote ? (daNote.parent == null || daNote.parent.wasGoodHit) : daNote.checkHit(Conductor.songPosition)))
					goodNoteHit(daNote);
				if (cpuControlled || boyfriend.stunned) return;
				if (daNote.isSustainNote && strumsBlocked[daNote.noteData] != true && keysPressed[daNote.noteData % Note.ammo[mania]] && (daNote.parent == null || daNote.parent.wasGoodHit) && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
					goodNoteHit(daNote);
			});
		}
	}

	function opponentnoteMiss(daNote:Note):Void {
		notes.forEachAlive((note:Note) -> {
			if (daNote != note && !daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		var result:Dynamic = callOnLuas('opponentnoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('opponentnoteMiss', [daNote]);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote.hasMissed) return;
		daNote.hasMissed = true;
		daNote.active = false;

		notes.forEachAlive((note:Note) -> {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		var leData:Int = Std.int(Math.abs(daNote.noteData));
		noteMissCommon(leData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissCommon(direction:Int, note:Note = null) {
		var subtract:Float = .05;
		if(note != null) subtract = note.missHealth;
		health -= subtract * healthLoss;

		if(instakillOnMiss) doDeathCheck(true);
		if (combo > maxCombo) maxCombo = combo;

		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if(char != null && char.hasMissAnimations) {
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;
			char.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss' + suffix, true);
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
		if (SONG.needsVoices) vocals.volume = 1;

		var isSus:Bool = note.isSustainNote;
		var leData:Int = Math.floor(Math.abs(note.noteData));
		var leType:String = note.noteType;

		note.hitByOpponent = true;

		if(leType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = .6;
		} else if (!note.noAnimation) {
			var altAnim:String = note.animSuffix;
			if (SONG.notes[curSection] != null && SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
				altAnim = '-alt';

			var char:Character = note.gfNote ? gf : dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[leData] + altAnim;
			if(char != null) {
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices) vocals.volume = 1;

		strumPlayAnim(true, leData % Note.ammo[mania], Conductor.stepCrochet * 1.25 / 1000);

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[leData];
		if (ClientPrefs.getPref('camMovement'))
			if(!bfturn) moveCamOnNote(animToPlay);

		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!isSus) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function moveCamOnNote(singArrows:String) {
		switch (singArrows) {
			case "singLEFT": camlockpoint.set(campoint.x - camMovement, campoint.y);
			case "singDOWN": camlockpoint.set(campoint.x, campoint.y + camMovement);
			case "singUP": camlockpoint.set(campoint.x, campoint.y - camMovement);
			case "singRIGHT": camlockpoint.set(campoint.x + camMovement, campoint.y);
		}

		var camTimer:FlxTimer = new FlxTimer().start(1);
		camlock = true;
		if(camTimer.finished) {
			camlock = false;
			camFollow.setPosition(campoint.x, campoint.y);
			camTimer = null;
		} 
	}

	function goodNoteHit(note:Note):Void {
		if (note.wasGoodHit || (cpuControlled && (note.ignoreNote || note.hitCausesMiss))) return;

		note.wasGoodHit = true;
		if (ClientPrefs.getPref('hitsoundVolume') > 0 && !note.hitsoundDisabled) 
			FlxG.sound.play(Paths.sound('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}'), ClientPrefs.getPref('hitsoundVolume'));

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.floor(Math.abs(note.noteData));
		var leType:String = note.noteType;

		if (!isSus) notesHitArray.push(Date.now());

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[leData];
		if (ClientPrefs.getPref('camMovement'))
			if(bfturn) moveCamOnNote(animToPlay);

		if(note.hitCausesMiss) {
			noteMiss(note);
			if(!note.noteSplashDisabled && !isSus)
				spawnNoteSplashOnNote(note);

			if(!note.noMissAnimation) {
				switch(leType) {
					case 'Hurt Note' | 'Kill Note': // Hurt note, Kill Note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			if (!isSus) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			return;
		}

		if (!dontZoomCam) camZooming = true;
		if (SONG.needsVoices) vocals.volume = 1;
		health += note.hitHealth * healthGain;
		if (!isSus) {
			combo++;
			popUpScore(note);
		}

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
				if(leType == 'Hey!') {
					if(char.animOffsets.exists(animCheck)) {
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
				}
			}
		}

		var time:Float = 0;
		if(cpuControlled)
			time = Conductor.stepCrochet * 1.25 / 1000;
		strumPlayAnim(false, leData % Note.ammo[mania], time);

		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('goodNoteHit', [note]);

		if (!isSus) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.getPref('splashOpacity') > 0 && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if((SONG.splashSkin != null || SONG.splashSkin != '') && SONG.splashSkin.length > 0) skin = SONG.splashSkin;
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		var arrowIndex:Int = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania]);

		var hsb:Array<Float> = [0, 0, 0];
		if (data > -1 && data < arrowHSV.length) {
			hsb = [arrowHSV[arrowIndex][0] / 360, arrowHSV[arrowIndex][1] / 100, arrowHSV[arrowIndex][2] / 100];
			if(note != null) {
				skin = note.noteSplashTexture;
				hsb = note.noteSplashHSB;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, hsb);
		grpNoteSplashes.add(splash);
	}

	public function charactersDance():Void {
		for (char in [gf, boyfriend, dad]) {
			if (char == null) continue;
			var speed = (gf != null && char == gf) ? gfSpeed : 1;
			var curAnim = char.animation.curAnim;
			if ((curAnim == null || !curAnim.name.startsWith('sing')) && !char.stunned && curBeat % Math.round(speed * char.danceEveryNumBeats) == 0)
				char.dance();
		}
	}

	override function destroy() {
		for (i in 0...luaArray.length) {
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy');
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		for (script in hscriptArray)
			if(script != null) {
				script.call('onDestroy');
				script.destroy();
			}
		while (hscriptArray.length > 0)
			hscriptArray.pop();

		for (name => save in modchartSaves) save.close();

		@:privateAccess
		if (Std.isOfType(FlxG.game._requestedState, PlayState))
			if (FlxG.sound.music != null) FlxG.sound.music.destroy();
		else {
			Paths.clearStoredCache();
			if (FlxG.sound.music != null) {
				FlxG.sound.music.onComplete = null;
				FlxG.sound.music.pitch = 1;
			}
		}

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxAnimationController.globalSpeed = 1;
		instance = null;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null)
			FlxG.sound.music.fadeTween.cancel();
		FlxG.sound.music.fadeTween = null;
	}

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

		charactersDance();
		
		switch (ClientPrefs.getPref('IconBounceType')) {
			case 'Vanilla' | 'Kade':
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
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getPreloadPath(luaFile);
		
		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String) {
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(scriptFile);
		
		if(FileSystem.exists(scriptToLoad)) {
			if (SScript.global.exists(scriptToLoad)) return false;
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String) {
		function doerror(m:String) {
			addTextToDebug(m, FlxColor.RED);
			Logs.trace(m);
		}
		try {
			var newScript:HScript = new HScript(null, file);
			if(newScript.parsingException != null) {
				doerror('ERROR ON LOADING - ${newScript.parsingException}');
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate')) {
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded) {
					for (e in callValue.exceptions)
						if (e != null) doerror('ERROR (onCreate) - $e');

					newScript.destroy();
					hscriptArray.remove(newScript);
					Logs.trace('failed to initialize sscript interp!!! ($file)');
				} else Logs.trace('initialized sscript interp successfully: $file');
			}
		} catch(e) {
			doerror('ERROR - $e');
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null) {
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(event:String, ?args:Array<Any> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while(i < len) {
			var script:FunkinLua = luaArray[i];
			if(exclusions.contains(script.scriptName)) {
				i++;
				continue;
			}

			var ret:Dynamic = script.call(event, args);
			if((ret == FunkinLua.Function_StopLua || ret == FunkinLua.Function_StopAll) && !excludeValues.contains(ret) && !ignoreStops) {
				returnVal = ret;
				break;
			}
			
			if(ret != null && !excludeValues.contains(ret)) returnVal = ret;
			if(!script.closed) i++;
			else len--;
		}
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1) return returnVal;
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var ret:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded) {
					var e = callValue.exceptions[0];
					if(e != null) FunkinLua.luaTrace('ERROR (${callValue.calledFunction}) - $e', true, false, FlxColor.RED);
				} else {
					ret = callValue.returnValue;
					if((ret == FunkinLua.Function_StopHScript || ret == FunkinLua.Function_StopAll) && !excludeValues.contains(ret) && !ignoreStops) {
						returnVal = ret;
						break;
					}
					
					if(ret != null && !excludeValues.contains(ret))
						returnVal = ret;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName)) continue;
			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin)) continue;
			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float = 0) {
		var grp = isDad ? opponentStrums : playerStrums;
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
		if(ret != FunkinLua.Function_Stop) {
			ratingName = '?';
			if(totalPlayed != 0) { // Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				accuracy = MathUtil.floorDecimal(ratingPercent * 100, 2);
				ranks = CoolUtil.GenerateLetterRank(accuracy);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
				if (ratingPercent < 1)
					for (i in 0...ratingStuff.length - 1)
						if(ratingPercent < ratingStuff[i][1]) {
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboUpdate();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', accuracy);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingRank', ranks);
		setOnScripts('ratingFC', ratingFC);
	}

	public function getActualPlaybackRate():Float {
		return FlxG.sound.music != null ? FlxG.sound.music.getActualPitch() : playbackRate;
	}

	function fullComboUpdate() {
		var fullhits = [for(i in 0...ratingsData.length) ratingsData[i].hits];
		ratingFC = 'Clear';
		if(songMisses < 1) {
			if (fullhits[3] > 0 || fullhits[4] > 0) ratingFC = 'FC';
			else if (fullhits[2] > 0) ratingFC = 'GFC';
			else if (fullhits[1] > 0) ratingFC = 'SFC';
			else if (fullhits[0] > 0) ratingFC = "PFC";
		} else if (songMisses < 10) ratingFC = 'SDCB';
	}
}