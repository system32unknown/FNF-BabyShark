package states;

import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.tweens.misc.VarTween;
import flixel.animation.FlxAnimationController;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
#if !MODS_ALLOWED import openfl.utils.Assets as OpenFlAssets; #end
import haxe.Json;
import states.editors.*;
import substates.GameOverSubstate;
import substates.PauseSubState;
import game.Note.EventNote;
import game.Achievements.AchievementObject;
import game.subtitles.SubtitleManager;
import game.Section.SwagSection;
import game.*;
import utils.*;
import ui.*;
import data.*;
import states.stages.BaseStage;
import shaders.PulseEffect;
import data.StageData.StageFile;
import data.EkData.Keybinds;
import scripting.haxe.AlterScript;
import scripting.lua.*;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import handlers.PsychVideo;

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
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
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
	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:Song.SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;
	public var gameOverChar:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var playerLU:FlxTypedGroup<FlxSprite>;
	public var opponentLU:FlxTypedGroup<FlxSprite>;
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
	var healthMax:Float = 2;
	public var combo:Int = 0;
	public var maxCombo:Int = 0;

	var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var fullComboFunction:Void->Void = null;

	public static var mania:Int = 0;

	var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	var updateTime:Bool = true;
	var updateLU:Bool = false;

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

	public var shaderFilters:Array<BitmapFilter> = [];

	public var songScore:Int = 0;
	public var botScore:Int = 0;

	public var accuracy:Float = 0;
	public var ranks:String = "";

	var notesHitArray:Array<Date> = [];
	var nps:Int = 0;
	var maxNPS:Int = 0;

	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var scoreTxtTween:FlxTween;

	var daKeyText:Array<FlxText> = [];
	
	var timeTxt:FlxText;
	var judgementCounter:FlxText;
	var extraTxt:FlxText;

	var mstimingTxt:FlxText = new FlxText(0, 0, 0, "0ms");
	var msTimingTween:VarTween;

	var songNameText:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var deathCounter:Int = 0;

	public static var chartingMode:Bool = false;

	public static var seenCutscene:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var restarted:Bool = false;

	public var defaultCamZoom:Float = 1.05;
	public var defaultHudCamZoom:Float = 1.0;

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

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	var gfChecknull:String = "";

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	public var scriptArray:Array<AlterScript> = [];
	var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	public var achievementsArray:Array<FunkinLua> = [];
	public var achievementWeeks:Array<String> = [];

	// Less laggy controls
	var keysArray:Array<Dynamic>;

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo sprite object
	public static var lastLateEarly:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	public var precacheList:Map<String, String> = new Map<String, String>();

	public var songName:String;

	var antialiasing:Bool = ClientPrefs.getPref('Antialiasing');
	var downScroll:Bool = ClientPrefs.getPref('downScroll');
	var middleScroll:Bool = ClientPrefs.getPref('middleScroll');
	var hideHud:Bool = ClientPrefs.getPref('hideHud');
	var healthBarAlpha:Float = ClientPrefs.getPref('healthBarAlpha');
	var ratingDisplay:String = ClientPrefs.getPref('RatingDisplay');
	var showCombo:Bool = ClientPrefs.getPref('ShowCombo');
	var timeType:String = ClientPrefs.getPref('timeBarType'); 

	var useLuaGameOver:Bool = false;
	public var subtitleManager:SubtitleManager;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	override function create() {
		instance = this;

		startCallback = startCountdown;
		endCallback = endSong;

		firstStart = !MusicBeatState.previousStateIs(PlayState);
		FlxG.fixedTimestep = false;
		persistentUpdate = persistentDraw = true;

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

		fullComboFunction = function() {
			var epics = ratingsData[0].hits;
			var sicks = ratingsData[1].hits;
			var goods = ratingsData[2].hits;
			var bads = ratingsData[3].hits;
			var shits = ratingsData[4].hits;

			ratingFC = 'Clear';
			if(songMisses < 1) {
				if (bads > 0 || shits > 0) ratingFC = 'FC';
				else if (goods > 0) ratingFC = 'GFC';
				else if (sicks > 0) ratingFC = 'SFC';
				else if (epics > 0) ratingFC = "PFC";
			} else if (songMisses < 10)
				ratingFC = 'SDCB';
		};

		keysArray = Keybinds.fill();
		fillKeysPressed();

		// For the "Just the Two of Us" achievement
		keysPressed = CoolUtil.dynamicArray(false, keysArray[mania].length);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

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
		Conductor.changeBPM(SONG.bpm);

		mania = SONG.mania;
		if (mania < Note.minMania || mania > Note.maxMania)
			mania = Note.defaultMania;

		storyDifficultyText = Difficulty.getString();

		#if discord_rpc
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		changeDiscordPresence("Loading", false, true);
		#end

		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(songName);
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
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

		function addAbilityToUnlockAchievements(funkinLua:FunkinLua) {
			if (funkinLua.lua == null) throw "Lua Instance is null.";

			funkinLua.addCallback("giveAchievement", function(_, name:String) {
				if (luaArray.contains(funkinLua))
					throw 'Illegal attempt to unlock ' + name;
				if (Achievements.isAchievementUnlocked(name))
					return "Achievement " + name + " is already unlocked!";
				if (!Achievements.exists(name))
					return "Achievement " + name + " does not exist."; 
				if(instance != null) { 
					Achievements.unlockAchievement(name);
					instance.startAchievement(name);
					ClientPrefs.saveSettings();
					return "Unlocked achievement " + name + "!";
				} else return "Instance is null.";
			});
		}

		//CUSTOM ACHIVEMENTS
		#if (MODS_ALLOWED && LUA_ALLOWED && ACHIEVEMENTS_ALLOWED)
		var luaFiles:Array<String> = Achievements.getModAchievements().copy();
		if(luaFiles.length > 0) {
			for(luaFile in luaFiles) {
				var meta:Achievements.AchievementMeta = try Json.parse(File.getContent(luaFile.substring(0, luaFile.length - 4) + '.json')) catch(e) throw e;
				if (meta != null) {
					if ((meta.global == null || meta.global.length < 1) && meta.song != null && meta.song.length > 0 && SONG.song.toLowerCase().replace(' ', '-') != meta.song.toLowerCase().replace(' ', '-'))
						continue;

					var lua = new FunkinLua(luaFile);
					addAbilityToUnlockAchievements(lua);
					achievementsArray.push(lua);
				}
			}
		}

		var achievementMetas = Achievements.getModAchievementMetas().copy();
		for (i in achievementMetas) { 
			if (i.global == null || i.global.length < 1) {
				if (i.song != null) {
					if (i.song.length > 0 && SONG.song.toLowerCase().replace(' ', '-') != i.song.toLowerCase().replace(' ', '-'))
						continue;
				}
				if (i.lua_code != null) {
					var lua = new FunkinLua(null, i.lua_code);
					addAbilityToUnlockAchievements(lua);
					achievementsArray.push(lua);
				}
				if (i.week_nomiss != null) {
					achievementWeeks.push(i.week_nomiss + '_nomiss');
				}
			}
		}
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED executeScript('scripts', 'lua'); #end
		#if HSCRIPT_ALLOWED executeScript('scripts', 'hx'); #end

		// STAGE SCRIPTS
		#if MODS_ALLOWED
			#if LUA_ALLOWED executeLua('stages/' + curStage + '.lua'); #end
			#if HSCRIPT_ALLOWED executeHx('stages/' + curStage + '.hx'); #end
		#end

		if (!stageData.hide_girlfriend) {
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor

			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(.95, .95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		if (boyfriend != null && !useLuaGameOver) {
			GameOverSubstate.characterName = boyfriend.deathChar;
			GameOverSubstate.deathSoundName = boyfriend.deathSound;
			GameOverSubstate.loopSoundName = boyfriend.deathMusic;
			GameOverSubstate.endSoundName = boyfriend.deathConfirm;
		}
	
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null) {
			camPos.add(gf.getGraphicMidpoint().x + gf.cameraPosition[0], gf.getGraphicMidpoint().y + gf.cameraPosition[1]);
		}
		
		gfChecknull = (gf != null ? gf.curCharacter : "gf");
		if(dad.curCharacter == gfChecknull) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null) gf.visible = false;
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());

		Conductor.songPosition = -5000 / Conductor.songPosition;

		playerLU = new FlxTypedGroup<FlxSprite>();
		playerLU.camera = camHUD;
		opponentLU = new FlxTypedGroup<FlxSprite>();
		opponentLU.camera = camHUD;

		switch(ClientPrefs.getPref('LUType').toLowerCase()) {
			case 'only p1': add(playerLU);
			case 'both': 
				if (!middleScroll) {
					add(playerLU);
					add(opponentLU);
				}
		}

		var showTime:Bool = timeType != 'Disabled';
		timeTxt = new FlxText(0, 19, 400, "", 20);
		timeTxt.screenCenter(X);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = showTime;
		timeTxt.antialiasing = antialiasing;
		if(downScroll) timeTxt.y = FlxG.height - 35;

		if(timeType == 'Song Name') timeTxt.text = SONG.song;
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4) - 2;
		timeBarBG.screenCenter(X);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.setAdd(-4, -4);
		add(timeBarBG);
		
		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createGradientBar([FlxColor.GRAY], [dad.getColor(), boyfriend.getColor()], 1, 90);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeTxt);
		
		timeBarBG.sprTracker = timeBar;
		insert(members.indexOf(timeBarBG), timeBar);

		add(strumLineNotes = new FlxTypedGroup<StrumNote>());

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);
		add(grpNoteSplashes);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.9;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !hideHud;
		healthBarBG.setAdd(-4, -4);
		if(downScroll) healthBarBG.y = 50;
		add(healthBarBG);

		// healthBar
		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, healthMax);
		healthBar.scrollFactor.set();
		healthBar.visible = !hideHud;
		healthBar.alpha = healthBarAlpha;
		insert(members.indexOf(healthBarBG), healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !hideHud;
		iconP1.alpha = healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !hideHud;
		iconP2.alpha = healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(FlxG.width / 2, Math.floor(healthBarBG.y + 40), 0);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		scoreTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		
		if (ClientPrefs.getPref('HealthTypes') == 'Psych') {
			iconP1.isCenter = true;
			iconP2.isCenter = true;
		}
		if (ClientPrefs.getPref('ScoreType') == 'Psych') {
			scoreTxt.y = healthBarBG.y + 36;
			scoreTxt.borderSize = 1.25;
			scoreTxt.size = 20;
		}
		scoreTxt.visible = !hideHud;
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);
		add(scoreTxt);

		judgementCounter = new FlxText(2, 0, 0, "", 16);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		judgementCounter.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		judgementCounter.scrollFactor.set();
		judgementCounter.visible = ClientPrefs.getPref('ShowJudgementCount') && !hideHud;
		judgementCounter.text = 'Max Combos: 0\nEpics: 0\nSicks: 0\nGoods: 0\nBads: 0\nShits: 0\n' + getMissText(!ClientPrefs.getPref('movemissjudge'), '\n');
		add(judgementCounter);
		judgementCounter.screenCenter(Y);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		botplayTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		botplayTxt.scrollFactor.set();
		botplayTxt.visible = cpuControlled;
		botplayTxt.screenCenter(X);
		add(botplayTxt);
		if (downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		songNameText = new FlxText(2, 0, 0, SONG.song + " - " + storyDifficultyText + (playbackRate != 1 ? ' ($playbackRate' + 'x)' : ''), 16);
		songNameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		songNameText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		songNameText.scrollFactor.set();
		songNameText.y = FlxG.height - songNameText.height;
		songNameText.visible = !hideHud;
		add(songNameText);

		extraTxt = new FlxText(2, songNameText.y, 0, SONG.extraText.trim(), 16);
		extraTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		extraTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		extraTxt.scrollFactor.set();
		extraTxt.visible = !hideHud;
		extraTxt.camera = camHUD;
		add(extraTxt);

		if (extraTxt.text != null && extraTxt.text != "")
			songNameText.y -= 20;

		strumLineNotes.camera = camHUD;
		grpNoteSplashes.camera = camHUD;
		notes.camera = camHUD;
		healthBar.camera = camHUD;
		healthBarBG.camera = camHUD;
		iconP1.camera = camHUD;
		iconP2.camera = camHUD;
		scoreTxt.camera = camHUD;
		botplayTxt.camera = camHUD;
		timeBar.camera = camHUD;
		timeBarBG.camera = camHUD;
		timeTxt.camera = camHUD;
		songNameText.camera = camHUD;
		judgementCounter.camera = camHUD;

		startingSong = true;

		for (notetype in noteTypes) {
			#if LUA_ALLOWED executeLua('custom_notetypes/$notetype.lua'); #end
			#if HSCRIPT_ALLOWED executeHx('custom_notetypes/$notetype.hx'); #end
		}
		for (event in eventsPushed) {
			#if LUA_ALLOWED executeLua('custom_events/$event.lua'); #end
			#if HSCRIPT_ALLOWED executeHx('custom_events/$event.hx'); #end
		}
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1) {
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
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
		#if HSCRIPT_ALLOWED executeScript('data/${Paths.CHART_PATH}/$songName', 'lua'); #end
		#if LUA_ALLOWED executeScript('data/${Paths.CHART_PATH}/$songName', 'hx'); #end

		startCallback();
		RecalculateRating();

		if(ClientPrefs.getPref('hitsoundVolume') > 0) precacheList.set('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}', 'sound');
		for (i in 1...4) precacheList.set('missnote$i', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if (ClientPrefs.getPref('pauseMusic') != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic')), 'music');
		}

		precacheList.set('alphabet', 'image');
	
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		changeDiscordPresence("Starting");

		Conductor.safeZoneOffset = (ClientPrefs.getPref('safeFrames') / 60) * 1000;
		callOnLuas('onCreatePost');
		callOnScripts('onCreatePost');
		cleanupLuas();
		super.create();

		subtitleManager = new SubtitleManager();
		subtitleManager.camera = camHUD;
		add(subtitleManager);

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
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		
		noteKillOffset = 350 / songSpeed;
		return songSpeed = value;
	}

	function set_playbackRate(value:Float):Float {
		if(generatedMusic) {
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.getPref('safeFrames') / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return playbackRate = value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah, true);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(dad.getColor(), boyfriend.getColor());
		timeBar.createGradientBar([FlxColor.GRAY], [dad.getColor(), boyfriend.getColor()], 1, 90);

		healthBar.updateBar();
		timeBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.visible = false;
					startCharacterLua(newBoyfriend.curCharacter);
					HealthIcon.returnGraphic(newBoyfriend.healthIcon);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.visible = false;
					startCharacterLua(newDad.curCharacter);
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
					startCharacterLua(newGf.curCharacter);
					HealthIcon.returnGraphic(newGf.healthIcon);
				}
		}
	}

	function startCharacterLua(name:String) {
		var path = 'characters/${name}.lua';
		if (!LuaUtils.isLuaRunning(path)) executeLua(path);
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

	public function loadVideo(name:String) {
		#if VIDEOS_ALLOWED
		var videoHandler:PsychVideo = new PsychVideo();
		videoHandler.loadCutscene(name);
		return;
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	public function startVideo(name:String) {
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var videoHandler:PsychVideo = new PsychVideo(function() {
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		});
		videoHandler.startVideo(name);
		return;
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	/**
		Renders a Video Sprite on Screen
		@param name [the Video Name in the "assets/videos" folder]
		@param x [the Horizontal Position of the Rendered Video]
		@param y [the Vertical Position of the Rendered Video]
		@param op [the Opacity of the Rendered Video]
		@param strCamera [the camera that should be used for rendering the video (e.g: hud)]
		@param loop [if the Video should play from the start once it's done]
		@param pauseMusic [if the Current Song should be paused while playing the video]
	**/
	public function startVideoSprite(name:String, x:Float = 0, y:Float = 0, op:Float = 1, strCamera:String = 'world',
		?loop:Bool = false, ?pauseMusic:Bool = false)
	{
		#if VIDEOS_ALLOWED
		var myCamera:FlxCamera = camGame;
		// stinks but whatever
		switch (strCamera) {
			case 'alt' | 'other' | 'above': myCamera = camOther;
			case 'hud' | 'ui' | 'interface': myCamera = camHUD;
			default: myCamera = camGame;
		}

		var videoHandler:PsychVideo = new PsychVideo(function() {
			startAndEnd();
			return;
		});
		var video:FlxSprite = null;

		video = videoHandler.startVideoSprite(x, y, op, name, myCamera, loop, pauseMusic);
		if (video == null) return;
		add(video);

		return;
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
	public function startDialogue(dialogueFile:DialogueBoxPsych.DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.finishThing = function() {
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
	public var campoint:FlxPoint = new FlxPoint();
	public var camlockpoint:FlxPoint = new FlxPoint();
	public var camlock:Bool = false;
	public var bfturn:Bool = false;

	function cacheCountdown() {
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['countdown/ready', 'countdown/set', 'countdown/go']);
		introAssets.set('pixel', ['pixelUI/countdown/ready-pixel', 'pixelUI/countdown/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		for (count in ['3', '2', '1', 'Go'])
			Paths.sound('countdown/intro$count' + introSoundsSuffix);
	}

	public function updateLuaDefaultPos() {
		for (i in 0...playerStrums.length) {
			setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...opponentStrums.length) {
			setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
			setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
		}
	}

	public function addLUStrums():Void {
		var strums:Array<Array<Dynamic>> = [[playerStrums, playerLU], [opponentStrums, opponentLU]];
		for (istrums in strums) {
			for (i in 0...istrums[0].members.length) {
				var strumLay:FlxSprite = new FlxSprite(istrums[0].members[i].x, 0).makeGraphic(Std.int(istrums[0].members[i].width), FlxG.height);
				strumLay.alpha = ClientPrefs.getPref('LUAlpha');
				strumLay.color = FlxColor.BLACK;
				strumLay.scrollFactor.set();
				strumLay.camera = camHUD;
				strumLay.screenCenter(Y);
				istrums[1].add(strumLay);
			}
		}
	}

	public function startCountdown()
	{
		if (startedCountdown) {
			callOnLuas('onStartCountdown');
			callOnScripts('onStartCountdown');
			return false;
		}

		inCutscene = false;
		callOnScripts('onStartCountdown');
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if (ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);

			addLUStrums();
			updateLuaDefaultPos();
	
			setOnLuas('defaultMania', SONG.mania);

			startedCountdown = true;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted');
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

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer) {
				charactersDance();

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['countdown/ready', 'countdown/set', 'countdown/go']);
				introAssets.set('pixel', ['pixelUI/countdown/ready-pixel', 'pixelUI/countdown/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = antialiasing;
				if (isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}
					
				var tick:states.stages.BaseStage.Countdown = THREE;
				switch(swagCounter) {
					case 0:
						FlxG.sound.play(Paths.sound('countdown/intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('countdown/intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('countdown/intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('countdown/introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4: tick = START;
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.getPref('opponentStrums') || note.mustPress) {
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(middleScroll && !note.mustPress)
							note.alpha *= .35;
					}
				});

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnScripts('onCountdownTick', [swagCounter]);
				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline function createCountdownSprite(image:String, antialias:Bool):FlxSprite {
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.camera = camHUD;
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween) {
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

	var scoreTweenSetting:Array<Dynamic> = [1.075, .2, 'backOut'];
	public function updateScore(miss:Bool = false) {
		judgementCounter.text = 'Max Combos: ${maxCombo}';
		for (rating in ratingsData) {
			judgementCounter.text += '\n${flixel.addons.ui.U.FU(rating.name)}s: ${rating.hits}';
		}
		judgementCounter.text += '\n${getMissText(!ClientPrefs.getPref('movemissjudge'), '\n')}';
		judgementCounter.screenCenter(Y);
		if (!ClientPrefs.getPref('ShowNPSCounter')) {
			UpdateScoreText();
		}
		if(ClientPrefs.getPref('scoreZoom') && !miss) {
			if (scoreTxtTween != null) scoreTxtTween.cancel();

			scoreTxt.scale.set(scoreTweenSetting[0], scoreTweenSetting[0]);
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, scoreTweenSetting[1] * playbackRate, {
				ease: LuaUtils.getTweenEaseByString(scoreTweenSetting[2]),
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
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
		songTime = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void {
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		var music:FlxSound = FlxG.sound.music;
		music.loadEmbedded(Paths.inst(PlayState.SONG.song), false);
		music.onComplete = finishSong.bind();
		music.pitch = playbackRate;
		music.volume = 1;
		vocals.time = music.time = 0;
		music.play(); vocals.play();

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

		#if discord_rpc
		changeDiscordPresence(false, true);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart');
		callOnScripts('onSongStart');
	}

	var noteTypes:Array<String> = [];
	var eventsPushed:Array<String> = [];
	function generateSong(dataPath:String):Void {
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch(songSpeedType) {
			case "multiplicative": songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant": songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		var inst = Paths.inst(PlayState.SONG.song);
		songLength = inst != null ? inst.length : 0;

		if (SONG.needsVoices) vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		else vocals = new FlxSound();

		vocals.group = FlxG.sound.defaultMusicGroup;
		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json('${Paths.CHART_PATH}/$songName/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson('${Paths.CHART_PATH}/$songName/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
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

				var fixedSus:Int = Math.round(songNotes[2] / Conductor.stepCrochet);

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = fixedSus * Conductor.stepCrochet;
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				if(fixedSus > 0) {
					for (susNote in 0...Math.floor(Math.max(fixedSus, 2))) {
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if (middleScroll) {
							sustainNote.x += 310;
							if (daNoteData > Note.separator[mania]) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress) {
					swagNote.x += FlxG.width / 2; // general offset
				} else if(middleScroll) {
					swagNote.x += 310;
					if(daNoteData > Note.separator[mania])
						swagNote.x += FlxG.width / 2 + 25;
				}

				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);
			}
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		if(eventsPushed.contains(event.event))
			return;

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

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Video Sprite':
				loadVideo(Std.string(event.value1));
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int) {
		var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.getPref('noteOffset'),
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
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
			var twnStart:Float = 0.5 + ((0.8 / mania) * i) * playbackRate;

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = downScroll;

			if (!isStoryMode && !skipArrowStartTween && mania > 1) {
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
			} else babyArrow.alpha = targetAlpha;

			if (player < 1 && middleScroll) {
				babyArrow.x += 310;
				if(i > Note.separator[mania]) { //Up and Right
					babyArrow.x += FlxG.width / 2 + 25;
				}
			}

			grp.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
			callOnLuas('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);
			callOnScripts('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);

			if (ClientPrefs.getPref('showKeybindsOnStart') && player == 1) {
				for (j in 0...keysArray[mania][i].length) {
					var daKeyTxt:FlxText = new FlxText(babyArrow.x, babyArrow.y - 10, 0, InputFormatter.getKeyName(keysArray[mania][i][j]), 32 - mania);
					daKeyTxt.setFormat(Paths.font("vcr.ttf"), 32 - mania, FlxColor.WHITE, CENTER);
					daKeyTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1.25);
					daKeyTxt.alpha = 0;
					var textY:Float = (j == 0 ? babyArrow.y - 32 : ((babyArrow.y - 32) + babyArrow.height) - daKeyTxt.height);
					daKeyTxt.setPosition(babyArrow.x + (babyArrow.width / 2) - daKeyTxt.width / 2, textY);
					add(daKeyTxt);
					daKeyTxt.camera = camHUD;
					daKeyText.push(daKeyTxt);

					if (mania > 1 && !skipArrowStartTween)
						FlxTween.tween(daKeyTxt, {y: textY + 32, alpha: 1}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
					else {
						daKeyTxt.y += 16;
						daKeyTxt.alpha = 1;
					}
					new FlxTimer().start(Conductor.crochet * .001 * 12, function(_) {
						FlxTween.tween(daKeyTxt, {y: daKeyTxt.y + 32, alpha: 0}, twnDuration, {ease: FlxEase.circIn, startDelay: twnStart, 
						onComplete: function(t) {
							remove(daKeyTxt);
						}});
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
			if (note.isSustainNote) note.originalHeightForCalcs = note.height;
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

			if (note != null && prevNote != null && prevNote.isSustainNote && prevNote.animation != null) { // haxe flixel
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
		} else if (!note.isSustainNote && noteData > - 1 && noteData < tMania) {
			if (note.changeAnim) note.animation.play(Note.keysShit.get(mania).get('letters')[noteData % tMania]);
		}
		
		if (note.changeColSwap) {
			var hsvNumThing = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData % tMania]);
			var colSwap = note.colorSwap;

			var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
			colSwap.hue = arrowHSV[hsvNumThing][0] / 360;
			colSwap.saturation = arrowHSV[hsvNumThing][1] / 100;
			colSwap.brightness = arrowHSV[hsvNumThing][2] / 100;
		}
	}

	public function addCamFilter(shader:BitmapFilter) {
		if (shaderFilters.length >= 0)
			shaderFilters.insert(shaderFilters.length, shader);
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

				FlxTween.tween(oldStrum, {alpha: 0}, 0.3, {onComplete: function(_) {
					remove(oldStrum);
				}});
			}
		}

		playerStrums.clear();
		playerLU.clear();
		opponentStrums.clear();
		opponentLU.clear();
		strumLineNotes.clear();
		setOnLuas('defaultMania', mania);

		notes.forEachAlive(function(note:Note) {
			updateNote(note);
		});

		for (noteI in 0...unspawnNotes.length) {
			updateNote(unspawnNotes[noteI]);
		}

		callOnLuas('onChangeMania', [mania, daOldMania]);
		callOnScripts('onChangeMania', [mania, daOldMania]);

		generateStaticArrows(0);
		generateStaticArrows(1);
		addLUStrums();
		updateLuaDefaultPos();
	}

	override function openSubState(SubState:FlxSubState) {
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused) {
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
			cleanupLuas();
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused) {
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) {
				if (!tmr.finished) tmr.active = true;
			});
			FlxTween.globalManager.forEach(function(twn:FlxTween) {
				if (!twn.finished) twn.active = true;
			});

			PsychVideo.isActive(true);

			paused = false;
			callOnLuas('onResume');
			callOnScripts('onResume');

			#if discord_rpc
			changeDiscordPresence(false, true);
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void {
		#if discord_rpc
		if (health > 0 && !paused) changeDiscordPresence(false, true);
		#end

		PsychVideo.isActive(true);
		callOnLuas('onFocus');
		callOnScripts('onFocus');
		super.onFocus();
	}

	override public function onFocusLost():Void {
		#if discord_rpc
		if (health > 0 && !paused) {
			cleanupLuas();
			if (!tryPause()) changeDiscordPresence(FlxG.autoPause, true);
		}
		#end

		PsychVideo.isActive(false);
		callOnLuas('onFocusLost');
		callOnScripts('onFocusLost');
		super.onFocusLost();
	}

	override public function onResize(Width:Int, Height:Int):Void {
		callOnLuas('onResize', [Width, Height]);
		callOnScripts('onResize', [Width, Height]);
		super.onResize(Width, Height);
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
			}else Conductor.songPosition = lastSongTime + Conductor.offset;

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
	var moveHealthIcons:Bool = true;
	var lastSongTime:Float = 0;
	var songElapsed:Float = 0;
	var syncDebounce:Float = 0;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.playing) {
			var time = FlxG.sound.music.time;
			songElapsed = time - lastSongTime;
			lastSongTime = time;
		}

		callOnLuas('onUpdate', [elapsed]);
		callOnScripts('onUpdate', [elapsed]);
		
		if (startedCountdown) {
			var delta = elapsed * 1000 * playbackRate;
			if (!startingSong && FlxG.sound.music.playing && songElapsed > 0)
				Conductor.songPosition = lastSongTime;
			else Conductor.songPosition += delta;

			if (!paused && !startingSong && (syncDebounce += elapsed) > 1) {
				syncDebounce = 0;
				var resync = vocals.loaded && Math.abs(vocals.time - FlxG.sound.music.time) > (vocals.vorbis == null ? 6 : 12);
				if (Math.abs(lastSongTime - Conductor.songPosition) > 16 || resync)
					resyncVocals(resync);
			}
		}

		if(ClientPrefs.getPref('camMovement') && !isPixelStage) {
			if(camlock) camFollow.setPosition(camlockpoint.x, camlockpoint.y);
		}

		if (updateLU) {
			switch(ClientPrefs.getPref('LUType').toLowerCase()) {
				case 'only p1':
					for (i in 0...playerLU.members.length) {
						if (playerLU.members[i] != null)
							playerLU.members[i].x = playerStrums.members[i].x;
					}
				case 'both':
					var strums:Array<Array<Dynamic>> = [[playerStrums, playerLU], [opponentStrums, opponentLU]];
					if (!middleScroll) {
						for (strumLU in strums)
							for (i in 0...strumLU[1].members.length)
								if (strumLU[1].members[i] != null)
									strumLU[1].members[i].x = strumLU[0].members[i].x;
					}
			}
		}
		
		FlxG.camera.followLerp = 0;
		if(!inCutscene) {
			FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
			} else boyfriendIdleTime = 0;
		}

		checkEventNote();

		super.update(elapsed);

		scoreTxt.x = Math.floor((FlxG.width - scoreTxt.width) / 2);
		if (ClientPrefs.getPref('ShowNPSCounter')) {
			var balls = notesHitArray.length - 1;
			while (balls >= 0) {
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else balls = 0;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS) maxNPS = nps;
			
			UpdateScoreText();
		}

		updateMusicBeat();
		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);
		setOnLuas('curStep', curStep);
		setOnLuas('curBeat', curBeat);
		setOnLuas('curSection', curSection);

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
		if (health > healthMax) health = healthMax;
		if (moveHealthIcons) iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * .01) - iconOffset);
		if (moveHealthIcons) iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * .01)) - (iconP2.width - iconOffset);

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

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong) {
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		} else {
			if (!paused) {
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition) {
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if(updateTime) {
					var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
					songPercent = curTime / songLength;

					var songCalc:Float = songLength - curTime;
					switch (timeType) {
						case 'Time Elapsed' | 'Time Position' | 'Name Elapsed' | 'Name Time Position':
							songCalc = curTime;
					}

					var secondsTotal:Int = Math.floor(Math.max(0, songCalc / 1000));
					var timePos:String = FlxStringUtil.formatTime(secondsTotal) + " / " + FlxStringUtil.formatTime(Math.floor(songLength / 1000));
					if (timeType != 'Song Name')
						switch (timeType) {
							case 'Time Left' | 'Time Elapsed': timeTxt.text = FlxStringUtil.formatTime(secondsTotal);
							case 'Time Position': timeTxt.text = timePos;
							case 'Name Left' | 'Name Elapsed': timeTxt.text = SONG.song + " (" + FlxStringUtil.formatTime(secondsTotal) + ")";
							case 'Name Time Position': timeTxt.text = SONG.song + " (" + timePos + ")";
							case 'Name Percent': timeTxt.text = '${SONG.song} (${timeBar.percent}%)';
						}
				}
			}
		}

		if (camZooming) {
			camGame.zoom = FlxMath.lerp(camGame.zoom, defaultCamZoom, FlxMath.bound(elapsed * 3.125 * camZoomingDecay * playbackRate, 0, 1));
			camHUD.zoom = FlxMath.lerp(camHUD.zoom, defaultHudCamZoom, FlxMath.bound(elapsed * 3.125 * camZoomingDecay * playbackRate, 0, 1));
		}

		#if debug
		FlxG.watch.addQuick("sectionShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		#end

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.getPref('noReset') && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong) {
			health = 0;
		}
		doDeathCheck();

		if (unspawnNotes[0] != null) {
			final spawnTime:Float = (2000 / songSpeed) / (FlxMath.bound(camHUD.zoom, null, 1));

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < spawnTime) {
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
				callOnScripts('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		if (generatedMusic && !inCutscene) {
			processInputs();
			
			if (!boyfriend.stunned && boyfriend.animation.curAnim != null && (cpuControlled || !keysArePressed() || endingSong)) {
				var canDance = boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss');
				if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / playbackRate) * boyfriend.singDuration && canDance)
					boyfriend.dance();
			}
			
			if(startedCountdown)
				renderNotes();
			else {
				notes.forEachAlive(function(daNote:Note) {
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}

		setOnLuas('cameraX', camFollow.x);
		setOnLuas('cameraY', camFollow.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function renderNotes():Void {
		var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
		notes.forEachAlive(function(daNote:Note) {
			var missed = daNote.tooLate || daNote.hasMissed || (daNote.isSustainNote && (daNote.parent == null || daNote.parent.hasMissed));

			var strumGroup:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : opponentStrums;
			if (strumGroup.members[daNote.noteData] == null) daNote.noteData = mania;
			var myStrum:StrumNote = strumGroup.members[daNote.noteData];
			if (myStrum == null) { // fuck it
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
				return;
			}

			var strumX:Float = myStrum.x + daNote.offsetX;
			var strumY:Float = myStrum.y + daNote.offsetY;
			var strumAngle:Float = myStrum.angle + daNote.offsetAngle;
			var strumAlpha:Float = myStrum.alpha * daNote.multAlpha * (missed ? .5 : 1);
			var strumDirection:Float = myStrum.direction;
			var strumScroll:Bool = myStrum.downScroll;
		
			var angleDir = strumDirection * Math.PI / 180;

			daNote.distance = .45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.localScrollSpeed;
			if (!strumScroll) daNote.distance = -daNote.distance;
		
			if(!daNote.isSustainNote)
				if (daNote.copyAngle) daNote.angle = strumDirection - 90 + strumAngle;
			else daNote.angle = strumDirection - 90 + (daNote.copyAngle ? strumAngle : 0);

			if(daNote.copyAlpha)
				daNote.alpha = strumAlpha;
		
			if(daNote.copyX)
				daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
			if(daNote.copyY) {
				daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
			
				//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
				if(strumScroll && daNote.isSustainNote) {
					if (daNote.animation.curAnim != null && daNote.animation.curAnim.name.endsWith('tail')) {
						daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
						daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
						if(isPixelStage)
							daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * daPixelZoom;
						else daNote.y -= 19;
					}
					daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
					daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1) * Note.scales[mania];
				}
			}
		
			var center:Float = strumY + Note.swagWidth / 2;
			if(myStrum.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
				(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !missed && !daNote.canBeHit))))
			{
				if (strumScroll ? (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center) : (daNote.y + daNote.offset.y * daNote.scale.y <= center)) {
					var swagRect = daNote.clipRect;
					if (swagRect == null) swagRect = FlxRect.get(0, 0, daNote.frameWidth, daNote.frameHeight);
					else swagRect.set(0, 0, daNote.frameWidth, daNote.frameHeight);
					
					if (strumScroll) {
						swagRect.height = (center - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;
					} else {
						swagRect.y = (center - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
					}

					daNote.clipRect = swagRect;
				}
			}
		
			// Kill extremely late notes and cause misses
			if (Conductor.songPosition > noteKillOffset + daNote.strumTime) {
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
			callOnScripts('onPause');
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
				return true;
			}
		}
		return false;
	}

	function openPauseMenu() {
		for (i in 0...keysPressed.length) {
			if (keysPressed[i]) keyReleased(i);
		}

		FlxG.camera.followLerp = 0;
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) {
			if (!tmr.finished) tmr.active = false;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween) {
			if (!twn.finished) twn.active = false;
		});

		PsychVideo.isActive(false);

		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

		#if discord_rpc
		changeDiscordPresence(true, true);
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if discord_rpc
		presenceChangedByLua = true;
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead) {
			callOnScripts('onGameOver');
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = persistentDraw = false;
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollow.x, camFollow.y));

				#if discord_rpc
				changeDiscordPresence("Game Over", false, true);
				#end
				isDead = true;
				return true;
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

			triggerEventNote(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0': value = 0;
					case 'gf' | 'girlfriend' | '1': value = 1;
				}

				if(Math.isNaN(flValue2) || flValue2 <= 0) flValue2 = .6;

				if(value != 0) {
					if(dad.curCharacter == gfChecknull) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
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
				if(Math.isNaN(flValue1) || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.getPref('camZooms') && FlxG.camera.zoom < 1.35) {
					if(Math.isNaN(flValue1)) flValue1 = 0.015;
					if(Math.isNaN(flValue2)) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Set Camera Zoom':
				if(Math.isNaN(flValue1)) flValue1 = defaultCamZoom;
				if(Math.isNaN(flValue2)) flValue2 = 1;
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
					if(!Math.isNaN(flValue1) || !Math.isNaN(flValue2)) {
						if(Math.isNaN(flValue1)) flValue1 = 0;
						if(Math.isNaN(flValue2)) flValue2 = 0;
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

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration * playbackRate);
					}
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
					case 'dad' | 'opponent' | 'cpu': charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastVisible:Bool = boyfriend.visible;
							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = lastVisible;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter == gfChecknull;
							var lastVisible:Bool = dad.visible;
							dad.visible = false;
							dad = dadMap.get(value2);
							if(dad.curCharacter != gfChecknull) {
								if(wasGf && gf != null)
									gf.visible = true;
							} else if(gf != null) gf.visible = false;
							dad.visible = lastVisible;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null) {
							if(gf.curCharacter != value2) {
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastVisible:Bool = gf.visible;
								gf.visible = false;
								gf = gfMap.get(value2);
								gf.visible = lastVisible;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Character Icon':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'dad' | 'opponent': charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0: iconP1.changeIcon("icon-" + value2);
					case 1: iconP2.changeIcon("icon-" + value2);
				}
				reloadHealthBarColors();

			case 'Extra Text Change':
				if (extraTxt.text != null)
					if (songNameText.y != songNameText.y - 20)
						songNameText.y -= 20;

				extraTxt.text = value1;

				if(extraTxt.text == null || extraTxt.text == "")
					songNameText.y = FlxG.height - songNameText.height;
				else songNameText.y = (FlxG.height - songNameText.height) - 20;

			case 'Change Scroll Speed':
				if (songSpeedType != "constant") {
					if(Math.isNaN(flValue1)) flValue1 = 1;
					if(Math.isNaN(flValue2)) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * flValue1;
					if(flValue2 <= 0) songSpeed = newValue;
					else songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween) {
							songSpeedTween = null;
						}
					});
				}

			case 'Play Video Sprite':
				var contents:Array<Dynamic> = [0, 0, 1, 'world'];
				if (Std.string(value2) != null && Std.string(value2).length > 1) {
					contents = Std.string(value2).split(',');
				}

				var x:Float = Std.parseFloat(contents[0]);
				var y:Float = Std.parseFloat(contents[1]);
				var op:Float = Std.parseFloat(contents[2]);
				var cam:String = Std.string(contents[3]);

				startVideoSprite(Std.string(value1), x, y, op, cam);

			case 'Set Property':
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
		}
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnLuas('onEvent', [eventName, value1, value2, strumTime]);
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	function moveCameraSection():Void {
		var section = SONG.notes[curSection];
		if (section == null) return;

		if (gf != null && section.gfSection) {
			moveCamera('gf');
			callOnLuas('onMoveCamera', ['gf']);
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		if (!section.mustHitSection) {
			moveCamera('dad');
			if(ClientPrefs.getPref('camMovement') && !isPixelStage) {
				campoint.set(camFollow.x, camFollow.y);
				bfturn = false;
				camlock = false;
			}
			callOnLuas('onMoveCamera', ['dad']);
			callOnScripts('onMoveCamera', ['dad']);
		} else {
			moveCamera('boyfriend');
			if(ClientPrefs.getPref('camMovement') && !isPixelStage){
				campoint.set(camFollow.x, camFollow.y);
				bfturn = true;
				camlock = false;
			}
			callOnLuas('onMoveCamera', ['boyfriend']);
			callOnScripts('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(moveCameraTo:Dynamic) {
		if(moveCameraTo == 'dad' || moveCameraTo) {
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			if(canTweenCamZoom) tweenCamZoom(canTweenCamZoomDad);
		} else if(moveCameraTo == 'boyfriend' || !moveCameraTo) {
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
				onComplete: function (_) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void {
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.getPref('noteOffset') <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.getPref('noteOffset') / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}

	public var transitioning = false;
	public function endSong() {
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) return false;
		}

		notes.forEachAlive(function(note:Note) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		});

		timeBarBG.visible = timeBar.visible = timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null) return false;
		else {
			var noMissWeek:String = WeekData.getWeekFileName() + '_nomiss';
			var achieve:String = checkForAchievement([noMissWeek, 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
			var customAchieve:String = checkForAchievement(achievementWeeks);

			if (achieve != null || customAchieve != null) {
				startAchievement(customAchieve != null ? customAchieve : achieve);
				return false;
			}
		}
		#end

		callOnScripts('onEndSong');
		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			if(!practiceMode && !cpuControlled)
				Highscore.saveCombo(SONG.song, '$ratingFC, $ratingName', storyDifficulty);

			playbackRate = 1;
			vocals.volume = 0;
			vocals.stop();

			if (chartingMode) {
				openChartEditor();
				return false;
			}

			if (isStoryMode) {
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

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
				WeekData.loadTheFirstEnabledMod();
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

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void {
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

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

	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	function cachePopUpScore() {
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage) {
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		for (cacheRating in ["epic", "sick", "good", "bad", "shit", "combo", "early", "late"]) {
			Paths.image(pixelShitPart1 + 'ratings/' + cacheRating + pixelShitPart2);
		}
		
		for (i in 0...10) {
			Paths.image(pixelShitPart1 + 'number/num$i' + pixelShitPart2);
		}
	}

	// FOR LUA
	public function ChangeAllFonts(font:String) {
		scoreTxt.font = font;
		botplayTxt.font = font;
		judgementCounter.font = font;
		judgementCounter.screenCenter(Y);
		timeTxt.font = font;

		songNameText.font = font;
		songNameText.y = FlxG.height - songNameText.height; //Fixes Height Issues
		extraTxt.y = songNameText.y;
		if (extraTxt.text != null && extraTxt.text != "")
			songNameText.y -= 20;

		for (dakey in daKeyText)
			dakey.font = font;
		extraTxt.font = font;
	}

	var scoreSeparator:String = "|";
	function getMissText(hidden:Bool = false, sepa:String = ' '):String {
		var missText = "";
		var sepaSpace:String = (sepa != '\n' ? scoreSeparator + ' ' : '');
		if (cpuControlled || hidden) return missText;

		switch (ClientPrefs.getPref('ScoreType')) {
			case 'Alter' | 'Kade':
				var breakText = (ClientPrefs.getPref('ScoreType') == 'Kade' ? 'Combo Breaks' : 'Breaks');
				missText = '${sepa != '\n' ? '$scoreSeparator $breakText:' : '$breakText: '}$songMisses';
			case 'Psych':
				missText = sepaSpace + 'Misses: $songMisses';
		} return missText + sepa;
	}
	function getNPSText() {
		if (!ClientPrefs.getPref('ShowNPSCounter')) return '';

		switch (ClientPrefs.getPref('ScoreType')) {
			case 'Alter' | 'Kade':
				return 'NPS:$nps (Max:$maxNPS) $scoreSeparator ';
			default: return 'NPS: $nps $scoreSeparator ';
		}
	}

	function UpdateScoreText() {
		var tempText:String = getNPSText();
		var tempMiss:String = getMissText(ClientPrefs.getPref('movemissjudge'));
		
		switch(ClientPrefs.getPref('ScoreType')) {
			case 'Alter':
				tempText += 'Score:${!cpuControlled ? songScore : botScore} ';
				tempText += tempMiss;
				tempText += '$scoreSeparator Accuracy:$accuracy%' + (ratingName != '?' ? ' | [$ratingName, $ratingFC] • $ranks' : ' | [?, ?] • F');
			case 'Psych':
				tempText += 'Score: ${!cpuControlled ? songScore : botScore} ';
				tempText += tempMiss;
				tempText += '$scoreSeparator Rating: ' + (ratingName != '?' ? '$ratingName [$accuracy% | $ratingFC]' : '? [0% | ?]');
			case 'Kade':
				tempText += 'Score:${!cpuControlled ? songScore : botScore} ';
				tempText += tempMiss;
				tempText += '$scoreSeparator Accuracy:$accuracy%' + (ratingName != '?' ? ' $scoreSeparator ($ratingFC) $ratingName' : ' $scoreSeparator N/A');
		}
		scoreTxt.text = tempText;
	}

	function popUpScore(note:Note):Void {
		if (note == null) return;

		var noteDiff = getNoteDiff(note);
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);
		var placement:String = Std.string(combo);
		var score:Int = 500;

		var daTiming:String = "";
		var msTiming:Float = 0;

		note.ratingMod = daRating.ratingMod;
		note.rating = daRating.name;
		score = daRating.score;

		if(!note.ratingDisabled) daRating.hits++;
		totalNotesHit += daRating.ratingMod;

		if(daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note);

		if (noteDiff > Conductor.safeZoneOffset * 0.1)
			daTiming = "early";
		else if (noteDiff < Conductor.safeZoneOffset * -0.1)
			daTiming = "late";

		if (!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled) {
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}
		} else if (cpuControlled) {
			botScore += score;
			if(!note.ratingDisabled) {
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}
		}
		if (showCombo) {
			var ratingCams = (ratingDisplay == "Hud" ? camHUD : camGame);

			var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
			coolText.screenCenter();
			coolText.x = FlxG.width * .35;
			
			var rating:FlxSprite = new FlxSprite();
			var timing:FlxSprite = new FlxSprite();
			
			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';
			
			if (isPixelStage) {
				pixelShitPart1 = 'pixelUI/';
				pixelShitPart2 = '-pixel';
			}
		
			var comboOffset:Array<Array<Int>> = ClientPrefs.getPref('comboOffset');
		
			rating.loadGraphic(Paths.image(pixelShitPart1 + 'ratings/' + daRating.image + pixelShitPart2));
			rating.camera = ratingCams;
			rating.screenCenter();
			rating.x = coolText.x - 40 + comboOffset[0][0];
			rating.y -= 60 - comboOffset[0][1];
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.subtract(FlxG.random.int(0, 10) * playbackRate, FlxG.random.int(140, 175) * playbackRate);
			rating.visible = !hideHud && showRating;
		
			if (daTiming != "") {
				timing.loadGraphic(Paths.image(pixelShitPart1 + 'ratings/' + daTiming.toLowerCase() + pixelShitPart2));
			}
			timing.camera = ratingCams;
			timing.screenCenter();
			timing.x = coolText.x - 130 + comboOffset[3][0];
			timing.y -= comboOffset[3][1];
			timing.acceleration.y = 550 * playbackRate * playbackRate;
			timing.velocity.subtract(FlxG.random.int(0, 10) * playbackRate, FlxG.random.int(140, 175) * playbackRate);
			timing.visible = !hideHud && ClientPrefs.getPref('ShowLateEarly');
		
			if (ClientPrefs.getPref('ShowMsTiming') && mstimingTxt != null) {
				msTiming = MathUtil.truncateFloat(noteDiff / getActualPlaybackRate());
				
				mstimingTxt.setFormat(flixel.system.FlxAssets.FONT_DEFAULT, 20, FlxColor.WHITE, CENTER);
				mstimingTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
				mstimingTxt.visible = !hideHud;
				mstimingTxt.text = msTiming + "ms";
				mstimingTxt.camera = ratingCams;
			
				switch (daRating.name) {
					case 'shit' | 'bad': mstimingTxt.color = FlxColor.RED;
					case 'good': mstimingTxt.color = FlxColor.GREEN;
					case 'sick': mstimingTxt.color = FlxColor.CYAN;
					case 'epic': mstimingTxt.color = FlxColor.fromString('#784FFF');
				}
				add(mstimingTxt);
			}
		
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'ratings/combo' + pixelShitPart2));
			comboSpr.camera = ratingCams;
			comboSpr.screenCenter();
			comboSpr.x = coolText.x + comboOffset[2][0];
			comboSpr.y -= comboOffset[2][1];
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboSpr.visible = !hideHud;
		
			if (ClientPrefs.getPref('ShowMsTiming')) {
				mstimingTxt.screenCenter();
				var comboShowSpr:FlxSprite = (combo >= 10 ? comboSpr : rating);
				mstimingTxt.setPosition(comboShowSpr.x + 100, comboShowSpr.y + (combo >= 10 ? 80 : 100));
				mstimingTxt.updateHitbox();
			}
		
			if (daTiming != "" && ClientPrefs.getPref('ShowLateEarly'))
				add(timing);
		
			if (!ClientPrefs.getPref('comboStacking')) {
				if (lastRating != null) lastRating.kill();
				lastRating = rating;
			
				if (lastLateEarly != null) lastLateEarly.kill();
				lastLateEarly = timing;
			}
		
			if (!isPixelStage) {
				rating.setGraphicSize(Std.int(rating.width * .7));
				rating.antialiasing = antialiasing;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * .7));
				comboSpr.antialiasing = antialiasing;
				timing.setGraphicSize(Std.int(timing.width * .7));
				timing.antialiasing = antialiasing;
			} else {
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * .85));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * .85));
				timing.setGraphicSize(Std.int(timing.width * daPixelZoom * .85));
			}
		
			comboSpr.updateHitbox();
			rating.updateHitbox();
			timing.updateHitbox();
		
			var seperatedScore:Array<Int> = [];
			var comboSplit:Array<String> = Std.string(combo).split('');
		
			for (i in 0...comboSplit.length)
				seperatedScore.push(Std.parseInt(comboSplit[i]));
		
			if (!ClientPrefs.getPref('comboStacking')) {
				if (lastCombo != null) lastCombo.kill();
				lastCombo = comboSpr;
			}
			if (lastScore != null) {
				while (lastScore.length > 0) {
					lastScore[0].kill();
					lastScore.remove(lastScore[0]);
				}
			}
		
			var daLoop:Int = 0;
			for (i in seperatedScore) {
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'number/num$i' + pixelShitPart2));
				numScore.camera = ratingCams;
				numScore.screenCenter();
				numScore.x = coolText.x + (43 * daLoop) - 90 + comboOffset[1][0];
				numScore.y += 80 - comboOffset[1][1];
			
				if (!ClientPrefs.getPref('comboStacking'))
					lastScore.push(numScore);
			
				if (!isPixelStage) {
					numScore.antialiasing = antialiasing;
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				} else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				numScore.updateHitbox();
			
				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				numScore.visible = !hideHud && showComboNum;
			
				if(combo >= 10) {
					insert(members.indexOf(strumLineNotes), comboSpr);
				}
				insert(members.indexOf(strumLineNotes), rating);
				insert(members.indexOf(strumLineNotes), numScore);
			
				FlxTween.tween(numScore, {alpha: 0}, .2 / playbackRate, {
					onComplete: function(tween:FlxTween) {
						remove(numScore, true);
						numScore.destroy();
					},
					startDelay: Conductor.crochet * .002 / playbackRate
				});
			
				daLoop++;
			}
			coolText.text = Std.string(seperatedScore);
		
			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});
		
			if (ClientPrefs.getPref('ShowLateEarly')) {
				FlxTween.tween(timing, {alpha: 0}, 0.2 / playbackRate, {
					startDelay: Conductor.crochet * 0.001 / playbackRate,
					onComplete: function(tween:FlxTween) {
						remove(timing, true);
						timing.destroy();
					}
				});
			}
		
			if (ClientPrefs.getPref('ShowMsTiming')) {
				if (msTimingTween == null) {
					msTimingTween = FlxTween.tween(mstimingTxt, {alpha: 0}, .2 / playbackRate, {
						startDelay: Conductor.crochet * 0.001 / playbackRate
					});
				} else {
					mstimingTxt.alpha = 1;
					msTimingTween.cancel();
				
					msTimingTween = FlxTween.tween(mstimingTxt, {alpha: 0}, .2 / playbackRate, {
						startDelay: Conductor.crochet * 0.001 / playbackRate
					});
				}
			}
		
			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween) {
					coolText.destroy();
					remove(comboSpr, true);
					comboSpr.destroy();
					remove(rating, true);
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}
	}

	public static function getNoteDiff(note:Note = null):Float {
		return switch(ClientPrefs.getPref('NoteDiffTypes')) {
			case 'Psych': Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.getPref('ratingOffset')) / instance.getActualPlaybackRate();
			case 'Simple': note.strumTime - Conductor.songPosition;
			default: 0;
		}
	}

	public var strumsBlocked:Array<Bool> = [];
	function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}

	function keyPressed(key:Int) {
		fillKeysPressed();
		keysPressed[key] = true;

		if (!cpuControlled && startedCountdown && !paused && key > -1) {
			if(!boyfriend.stunned && generatedMusic && !endingSong) {
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if (FlxG.sound.music != null && FlxG.sound.music.playing && !startingSong)
					Conductor.songPosition = FlxG.sound.music.time;

				var sortedNotesList:Array<Note> = [];				
				var canMiss:Bool = !ClientPrefs.getPref('ghostTapping');
				var notesStopped:Bool = false;

				notes.forEachAlive(function(daNote:Note) {
					if (!strumsBlocked[daNote.noteData] && daNote.mustPress && !daNote.blockHit && !daNote.tooLate) {
						if (!daNote.isSustainNote && !daNote.wasGoodHit) {
							if (!daNote.canBeHit && daNote.checkDiff(Conductor.songPosition)) daNote.update(0);
							if (daNote.canBeHit) {
								if (daNote.noteData == key) sortedNotesList.push(daNote);
								canMiss = !ClientPrefs.getPref('AntiMash');
							} else if (daNote.isSustainNote && daNote.noteData == key && ((daNote.wasGoodHit || daNote.prevNote.wasGoodHit) &&
								(daNote.parent != null && !daNote.parent.hasMissed && daNote.parent.wasGoodHit)))
									sortedNotesList.push(daNote);
						}
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				var pressNotes:Array<Note> = [];

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList) {
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 3)
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							if (epicNote.isSustainNote) {
								StrumPlayAnim(false, key);
								continue;
							}
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				} else {
					callOnLuas('onGhostTap', [key]);
					callOnScripts('onGhostTap', [key]);
					if (canMiss) noteMissPress(key);
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
			callOnLuas('onKeyPress', [key]);
			callOnScripts('onKeyPress', [key]);
		}
	}

	function onKeyRelease(event:KeyboardEvent):Void {
		if (cpuControlled && !startedCountdown && paused) return;

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(key > -1) keyReleased(key);
	}
	function keyReleased(key:Int) {
		if (!keysPressed[key]) return;
		fillKeysPressed();

		keysPressed[key] = false;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnLuas('onKeyRelease', [key]);
		callOnScripts('onKeyRelease', [key]);
	}

	function fillKeysPressed() {
		var keybinds:Int = keysArray[mania].length;
		if (strumsBlocked != null) while (strumsBlocked.length < keybinds) strumsBlocked.push(false);
		if (keysPressed != null) while (keysPressed.length < keybinds) keysPressed.push(false);
	}

	function getKeyFromEvent(key:FlxKey):Int {
		if (key != NONE) {
			for (i in 0...keysArray[mania].length) {
				for (j in 0...keysArray[mania][i].length) {
					if(key == keysArray[mania][i][j]) {
						return i;
					}
				}
			}
		}
		return -1;
	}

	function keysArePressed():Bool {
		for (i in 0...keysArray[mania].length) {
			for (j in 0...keysArray[mania][i].length) {
				if (FlxG.keys.checkStatus(keysArray[mania][i][j], PRESSED)) return true;
			}
		}
		return false;
	}

	function dataKeyIsPressed(data:Int):Bool {
		for (i in 0...keysArray[mania][data].length) {
			if (FlxG.keys.checkStatus(keysArray[mania][data][i], PRESSED)) return true;
		}

		return false;
	}

	//Hold Notes
	function processInputs():Void {
		if (startedCountdown) {
			notes.forEachAlive(function(daNote:Note) {
				if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.checkHit(Conductor.songPosition))
					opponentNoteHit(daNote);

				if (cpuControlled && !daNote.blockHit && daNote.mustPress && daNote.canBeHit && (daNote.isSustainNote
					? (daNote.parent == null || daNote.parent.wasGoodHit) : daNote.checkHit(Conductor.songPosition)))
					goodNoteHit(daNote);

				if (cpuControlled || boyfriend.stunned) return;
				
				if (daNote.isSustainNote && strumsBlocked[daNote.noteData] != true && dataKeyIsPressed(daNote.noteData % Note.ammo[mania]) && (daNote.parent == null
				|| daNote.parent.wasGoodHit) && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			#if ACHIEVEMENTS_ALLOWED
			if (keysArePressed() && !endingSong) {
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) startAchievement(achieve);
			}
			#end
		}
	}

	function opponentnoteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && !daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		callOnLuas('opponentnoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		callOnScripts('opponentnoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote.hasMissed) return;
		daNote.hasMissed = true;
		daNote.active = false;

		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		if (combo > maxCombo) maxCombo = combo;
		
		if(!practiceMode) songScore -= 10;
		vocals.volume = 0;

		totalPlayed++;

		if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		health -= daNote.missHealth * healthLoss;
		songMisses++;
		combo = 0;

		if(instakillOnMiss) doDeathCheck(true);
		RecalculateRating(true);

		var leData:Int = Std.int(Math.abs(daNote.noteData));
		var char:Character = daNote.gfNote ? gf : boyfriend;
		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
			char.playAnim('sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + 'miss' + daNote.animSuffix, true);

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		callOnScripts('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void { //You pressed a key when there was no notes to press for this key
		if(boyfriend.stunned || ClientPrefs.getPref('ghostTapping')) return; //fuck it

		if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		health -= 0.05 * healthLoss;
		vocals.volume = 0;
		totalPlayed++;
		if (combo > maxCombo) maxCombo = combo;
		combo = 0;

		if(instakillOnMiss) doDeathCheck(true);
		RecalculateRating(true);

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		if(boyfriend.hasMissAnimations) 
			boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);

		callOnLuas('noteMissPress', [direction]);
		callOnScripts('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void {
		if (!dontZoomCam) camZooming = true;
		if (SONG.needsVoices) vocals.volume = 1;

		note.hitByOpponent = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = .6;
		} else if (!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null && SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
				altAnim = '-alt';
			}

			var char:Character = note.gfNote ? gf : dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			if(char != null) {
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		var time:Float = .15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
			time += .15;

		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
		if (ClientPrefs.getPref('camMovement')) {
			if(!bfturn) moveCamOnNote(animToPlay);
		}

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		callOnScripts('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function moveCamOnNote(singArrows:String) {
		switch (singArrows) {
			case "singLEFT":
				camlockpoint.set(campoint.x - camMovement, campoint.y);
			case "singDOWN":
				camlockpoint.set(campoint.x, campoint.y + camMovement);
			case "singUP":
				camlockpoint.set(campoint.x, campoint.y - camMovement);
			case "singRIGHT":
				camlockpoint.set(campoint.x + camMovement, campoint.y);
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

		if (ClientPrefs.getPref('hitsoundVolume') > 0 && !note.hitsoundDisabled) 
			FlxG.sound.play(Paths.sound('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}'), ClientPrefs.getPref('hitsoundVolume'));

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		if (!note.isSustainNote) notesHitArray.unshift(Date.now());

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
		if (ClientPrefs.getPref('camMovement')) {
			if(bfturn) moveCamOnNote(animToPlay);
		}

		if(note.hitCausesMiss) {
			noteMiss(note);
			if(!note.noteSplashDisabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);

			if(!note.noMissAnimation) {
				switch(note.noteType) {
					case 'Hurt Note' | 'Kill Note': // Hurt note, Kill Note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			note.wasGoodHit = true;
			if (!note.isSustainNote) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			return;
		}

		if (!dontZoomCam) camZooming = true;
		if (SONG.needsVoices) vocals.volume = 1;
		health += note.hitHealth * healthGain;
		note.wasGoodHit = true;

		if (!note.isSustainNote) {
			combo += 1;
			popUpScore(note);
		}

		if(!note.noAnimation) {
			if(note.noteType == 'Hey!') {
				if(boyfriend.animOffsets.exists('hey')) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = .6;
				}
				if(gf != null && gf.animOffsets.exists('cheer')) {
					gf.playAnim('cheer', true);
					gf.specialAnim = true;
					gf.heyTimer = .6;
				}
			} else {
				if(note.gfNote) {
					if(gf != null) {
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				} else {
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}
			}
		}

		var time:Float = 0;
		if(cpuControlled) {
			time = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail')) {
				time += 0.15;
			}
		}
		StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);

		callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		callOnScripts('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

		if (!note.isSustainNote) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.getPref('splashOpacity') > 0 && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if((SONG.splashSkin != null || SONG.splashSkin != '') && SONG.splashSkin.length > 0) skin = SONG.splashSkin;
		var arrowHSV:Array<Array<Int>> = ClientPrefs.getPref('arrowHSV');
		var arrowIndex:Int = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania]);

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < arrowHSV.length) {
			hue = arrowHSV[arrowIndex][0] / 360;
			sat = arrowHSV[arrowIndex][1] / 100;
			brt = arrowHSV[arrowIndex][2] / 100;
			if(note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	public function charactersDance():Void {
		for (char in [gf, boyfriend, dad]) {
			if (char == null) continue;
			var speed = (gf != null && char == gf) ? gfSpeed : 1;
			var curAnim = char.animation.curAnim;
			if ((curAnim == null || !curAnim.name.startsWith('sing')) && !char.stunned
			&& curBeat % Math.round(speed * char.danceEveryNumBeats) == 0)
				char.dance();
		}
	}

	public function cleanupLuas(destroy:Bool = false) {
		for (lua in luaArray) {
			if (destroy) lua.call('onDestroy');
			if (destroy || lua.closed) lua.stop();
		}
		if (destroy) luaArray.resize(0);
	}

	override function destroy() {
		cleanupLuas(true);
		for (hx in scriptArray)
			hx.call('onDestroy');
		scriptArray.resize(0);

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

		subtitleManager.destroy();
		subtitleManager = null;
		FlxAnimationController.globalSpeed = 1;
		PsychVideo.clearAll();
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

		callOnLuas('onStepHit');
		callOnScripts('onStepHit', [curStep]);
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
				var funny:Float = Math.max(Math.min(healthBar.value, 1.9), .1);
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + .1))), Std.int(iconP1.height - (25 * funny)));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + .1))), Std.int(iconP2.height - (25 * ((2 - funny) + .1))));
			case "GoldenApple":
				if (curBeat % 2 == 0) {
					iconP1.scale.set(1.1, .8);
					iconP2.scale.set(1.1, 1.3);
	
					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
				} else {
					iconP1.scale.set(1.1, 1.3);
					iconP2.scale.set(1.1, .8);
	
					FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
				}
	
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		lastBeatHit = curBeat;

		callOnLuas('onBeatHit');
		callOnScripts('beatHit', [curBeat]);
	}

	override function sectionHit() {
		super.sectionHit();

		if (!startingSong && generatedMusic) changeDiscordPresence();
		if (SONG.notes[curSection] != null) {
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.getPref('camZooms')) {
				FlxG.camera.zoom += .015 * camZoomingMult;
				camHUD.zoom += .03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM) {
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		callOnLuas('onSectionHit');
		callOnScripts('onSectionHit', [curSection]);
	}

	public var presenceChangedByLua:Bool = false;
	public function changeDiscordPresence(?extraDetails:String, paused:Bool = false, force:Bool = false):Void {
		#if desktop
		if ((presenceChangedByLua && !force) || transitioning) return;
		var showTime:Bool = !paused && !startingSong && !isDead && generatedMusic;
		var scoreDetail:String = '[${MathUtil.floorDecimal(ratingPercent * 100, 2)}% - ${ratingFC} | Misses: ${songMisses}]';
		DiscordClient.changePresence(
			(extraDetails != null ? '${extraDetails} - ' : '') + (paused ? detailsPausedText : detailsText),
			'${SONG.song} (${storyDifficultyText})' + ((!startingSong && totalPlayed > 0) ? ' $scoreDetail' : ''),
			iconP2 != null ? iconP2.getCharacter() : '',
			showTime,
			!showTime ? 0 : Math.max(songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'), 0)
		);
		#end
	}

	#if HSCRIPT_ALLOWED
	public function executeHx(hxFile:String, restrict:Bool = false):Bool {
		for (script in scriptArray) if(script.scriptFile == hxFile) return false;
		#if MODS_ALLOWED
		var mod = restrict ? Paths.mods(hxFile) : Paths.modFolders(hxFile);
		if (FileSystem.exists(mod)) {
			scriptArray.push(new AlterScript(mod));
			return true;
		} else
		#end if (#if sys FileSystem.exists #else OpenFlAssets.exists #end(Paths.getPreloadPath(hxFile))) {
			scriptArray.push(new AlterScript(mod));
			return true;
		}

		return false;
	}
	#end

	public function executeLua(luaFile:String, restrict:Bool = false):FunkinLua {
		#if LUA_ALLOWED
		luaFile = FunkinLua.format(luaFile);

		#if MODS_ALLOWED
		var mod = restrict ? Paths.mods(luaFile) : Paths.modFolders(luaFile);
		if (FileSystem.exists(mod))
			return FunkinLua.execute(mod);
		else
		#end if (#if sys FileSystem.exists #else OpenFlAssets.exists #end(Paths.getPreloadPath(luaFile)))
			return FunkinLua.execute(Paths.getPreloadPath(luaFile));
		#end
		return null;
	}

	public function executeScript(folder:String, type:String) {
		#if (LUA_ALLOWED && sys)
		folder = folder.toLowerCase();
		folder = folder.endsWith('/') || folder.endsWith('\\') ? folder : '${folder}/';

		var foldersToCheck:Array<String> = [Paths.getPreloadPath(folder)];
		var filesPushed:Array<String> = [];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods(folder));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods('${Paths.currentModDirectory}/$folder'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods('${mod}/$folder'));
		#end

		var scriptArrays:Array<Dynamic> = (type == 'lua' ? luaArray : scriptArray);
		for (folder in foldersToCheck) {
			if (FileSystem.exists(folder)) {
				for (file in FileSystem.readDirectory(folder)) {
					if (!file.endsWith('.$type') || filesPushed.contains(file)) continue;
					scriptArrays.push((type == 'lua' ? FunkinLua.execute(folder + file) : new AlterScript(folder + file)));
					filesPushed.push(file);
				}
			}
		}
		#end
	}

	public function callOnScripts(event:String, ?args:Array<Any>):Void {
		return for (i in scriptArray) i.call(event, args);
	}

	public function callOnLuas(event:String, ?args:Array<Any>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];
		if(args == null) args = [];

		for (script in luaArray) {
			if(exclusions != null && exclusions.contains(script.scriptName))
				continue;

			var ret = script.call(event, args);
			if (ret == FunkinLua.Function_StopLua && !ignoreStops) break;
			if (ret != null && ret != FunkinLua.Function_Continue) returnVal = ret;
		}
		for (i in achievementsArray) i.call(event, args);
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (lua in luaArray) lua.set(variable, arg);
		for(i in achievementsArray) i.set(variable, arg);
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float = 0) {
		var grp = isDad ? strumLineNotes : playerStrums;
		var spr:StrumNote = grp.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			if (time > 0) spr.resetAnim = time / playbackRate;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		callOnScripts('onRecalculateRating');
		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if(ret != FunkinLua.Function_Stop) {
			if(totalPlayed < 1) ratingName = '?'; //Prevent divide by 0
			else { // Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				accuracy = MathUtil.floorDecimal(ratingPercent * 100, 2);
				ranks = CoolUtil.GenerateLetterRank(accuracy);

				// Rating Name
				if (ratingPercent >= 1)
					ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
				else {
					for (i in 0...ratingStuff.length - 1) {
						if(ratingPercent < ratingStuff[i][1]) {
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost

		setOnLuas('rating', accuracy);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingRank', ranks);
		setOnLuas('ratingFC', ratingFC);
	}

	public function getActualPlaybackRate():Float {
		return FlxG.sound.music != null ? FlxG.sound.music.getActualPitch() : playbackRate;
	}

	#if ACHIEVEMENTS_ALLOWED
	function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (practiceMode || cpuControlled);
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.exists(achievementName)) {
				var unlock:Bool = false;
				if (achievementName == WeekData.getWeekFileName() + '_nomiss') { // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss"
					if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				} else {
					switch(achievementName) {
						case 'ur_bad':
							if(ratingPercent < .2 && !practiceMode)
								unlock = true;
						case 'ur_good':
							if(ratingPercent >= 1 && !usedPractice)
								unlock = true;
						case 'oversinging':
							if(boyfriend.holdTimer >= 10 && !usedPractice)
								unlock = true;
						case 'hype':
							if(!boyfriendIdled && !usedPractice)
								unlock = true;
						case 'two_keys':
							if(!usedPractice) {
								var howManyPresses:Int = 0;
								for (j in 0...keysPressed.length) {
									if(keysPressed[j]) howManyPresses++;
								}
								if(howManyPresses <= 2) unlock = true;
							}
					}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end
}