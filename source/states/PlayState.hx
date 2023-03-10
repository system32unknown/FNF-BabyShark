package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.animation.FlxAnimationController;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import haxe.Json;
import editors.ChartingState;
import editors.CharacterEditorState;
import animateatlas.AtlasFrameMaker;
import substates.GameOverSubstate;
import substates.PauseSubState;
import game.Note.EventNote;
import game.Conductor.Rating;
import game.Achievements.AchievementObject;
import game.Section.SwagSection;
import game.*;
import utils.*;
import stages.objects.*;
import ui.*;
import shaders.PulseEffect;
import data.StageData.StageFile;
import data.EkData.Keybinds;
import data.*;
import scripting.haxe.AlterScript;
import scripting.lua.*;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import handlers.PsychVideo;
import handlers.CutsceneHandler;

#if LUA_ALLOWED
using llua.Lua.Lua_helper;
#end

class PlayState extends MusicBeatState {
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', .2], //From 0% to 19%
		['Shit', .4], //From 20% to 39%
		['Bad', .5], //From 40% to 49%
		['Bruh', .6], //From 50% to 59%
		['Meh', .69], //From 60% to 68%
		['Nice', .7], //69%
		['Good', .8], //From 70% to 79%
		['Great', .9], //From 80% to 89%
		['Sick!', 1] //From 90% to 99%
	];
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartGroups:Map<String, ModchartGroup> = new Map<String, ModchartGroup>();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	public var modchartGroups:Map<String, ModchartGroup> = new Map();
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

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var playerLU:FlxTypedGroup<FlxSprite>;
	public var opponentLU:FlxTypedGroup<FlxSprite>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	var healthMax:Float = 2;
	public var combo:Int = 0;
	public var maxCombo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var fullComboFunction:Void->Void = null;

	public static var mania:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	private var updateLU:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	var screwYouTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleFog:DadBattleFog;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var disableTheTripper:Bool = false;
	var disableTheTripperAt:Int;
	var screenshader:PulseEffect = new PulseEffect();
	public var shaderFilters:Array<BitmapFilter> = [];

	var bgGirls:BackgroundGirls;
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BackgroundTank;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

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

	var mstimingTxt:FlxText = new FlxText(0, 0, 0, "0ms");
	var msTimingTween:VarTween;

	var songNameText:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

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

	// Debug buttons
	var debugKeysChart:Array<FlxKey>;
	var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	var keysArray:Array<Dynamic>;

	var precacheList:Map<String, String> = new Map<String, String>();

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo sprite object
	public static var lastLateEarly:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];
	public var songName:String;

	var globalAntialiasing:Bool = ClientPrefs.getPref('globalAntialiasing');
	var downScroll:Bool = ClientPrefs.getPref('downScroll');
	var hideHud:Bool = ClientPrefs.getPref('hideHud');
	var healthBarAlpha:Float = ClientPrefs.getPref('healthBarAlpha');
	var ratingDisplay:String = ClientPrefs.getPref('RatingDisplay');
	var showCombo:Bool = ClientPrefs.getPref('ShowCombo');
	var lowQuality:Bool = ClientPrefs.getPref('lowQuality');

	var useLuaGameOver:Bool = false;
	override public function create()
	{
		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.keyBinds.get('debug_1').copy();
		debugKeysCharacter = ClientPrefs.keyBinds.get('debug_2').copy();
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
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
			} else if (songMisses < 10) {
				ratingFC = 'SDCB';
			}
		};

		keysArray = Keybinds.fill();

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray[mania].length) {
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		screenshader.waveAmplitude = 1;
		screenshader.waveFrequency = 2;
		screenshader.waveSpeed = 1;
		screenshader.shader.uTime.value[0] = FlxG.random.float(-100000, 100000);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		mania = SONG.mania;
		if (mania < Note.minMania || mania > Note.maxMania)
			mania = Note.defaultMania;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if discord_rpc
		storyDifficultyText = Difficulty.getString();

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) {
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		} else detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);

		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

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
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky': //Week 2
				if(!lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': //Week 3
				if(!lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new PhillyTrain(2000, 360);
				add(phillyTrain);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', CoolUtil.numberArray(18), 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				var posX = 400;
				var posY = 200;
				if(!lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String) {
						if(name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': //Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if(!lowQuality) {
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if(!lowQuality) {
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BackgroundTank();
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		switch(songName) {
			case 'stress': GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		switch(curStage) {
			case 'spooky': add(halloweenWhite);
			case 'tank': add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		function addAbilityToUnlockAchievements(funkinLua:FunkinLua) {
			var lua = funkinLua.lua;
			if (lua != null) {
				lua.add_callback("giveAchievement", function(name:String) {
					if (luaArray.contains(funkinLua))
						throw 'Illegal attempt to unlock ' + name;
					@:privateAccess
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
				if (i.song != null)
				{
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
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck) {
			if(FileSystem.exists(folder)) {
				for (file in FileSystem.readDirectory(folder)) {
					if (file.endsWith('.lua') && !filesPushed.contains(file)) {
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					} else if (file.endsWith('.hx') && !filesPushed.contains(file)) {
						scriptArray.push(new AlterScript(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
			startLuasOnFolder('stages/' + curStage + '.lua');
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo': gfVersion = 'gf-car';
				case 'mall' | 'mallEvil': gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil': gfVersion = 'gf-pixel';
				case 'tank': gfVersion = 'gf-tankmen';
				default: gfVersion = 'gf';
			}

			switch(songName) {
				case 'stress': gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend) {
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if(gfVersion == 'pico-speaker') {
				if(!lowQuality) {
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length) {
						if(FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
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
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		
		gfChecknull = (gf != null ? gf.curCharacter : "gf");
		if(dad.curCharacter == gfChecknull) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null) gf.visible = false;
		}

		switch(curStage) {
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				addBehindDad(evilTrail);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.getPref('middleScroll') ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		playerLU = new FlxTypedGroup<FlxSprite>();
		playerLU.cameras = [camHUD];

		opponentLU = new FlxTypedGroup<FlxSprite>();
		opponentLU.cameras = [camHUD];

		switch(ClientPrefs.getPref('LUType').toLowerCase()) {
			case 'only p1': add(playerLU);
			case 'both': 
				if (!ClientPrefs.getPref('middleScroll')) {
					add(playerLU);
					add(opponentLU);
				}
		}

		var showTime:Bool = (ClientPrefs.getPref('timeBarType') != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 20);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = showTime;
		if(downScroll) timeTxt.y = FlxG.height - 35;

		if(ClientPrefs.getPref('timeBarType') == 'Song Name') {
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.setPosition(0, timeTxt.y + (timeTxt.height / 4) - 2);
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

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null) {
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.9;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !hideHud;
		healthBarBG.setAdd(-4, -4);
		if(downScroll) healthBarBG.y = .11 * FlxG.height;
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

		screwYouTxt = new FlxText(2, songNameText.y, 0, SONG.screwYou.trim(), 16);
		screwYouTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		screwYouTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		screwYouTxt.scrollFactor.set();
		screwYouTxt.visible = !hideHud;
		screwYouTxt.cameras = [camHUD];
		add(screwYouTxt);

		if (screwYouTxt.text != null && screwYouTxt.text != "")
			songNameText.y -= 20;

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		songNameText.cameras = [camHUD];
		judgementCounter.cameras = [camHUD];
		doof.cameras = [camHUD];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys()) {
			startLuasOnFolder('custom_notetypes/' + notetype + '.lua');
		}
		for (event in eventPushedMap.keys()) {
			startLuasOnFolder('custom_events/' + event + '.lua');
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		if(eventNotes.length > 1) {
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/${Paths.CHART_PATH}/' + songName + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/${Paths.CHART_PATH}/' + songName + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/${Paths.CHART_PATH}/' + songName + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + 'data/${Paths.CHART_PATH}/' + songName + '/')); // using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck) {
			if(FileSystem.exists(folder)) {
				for (file in FileSystem.readDirectory(folder)) {
					if (file.endsWith('.lua') && !filesPushed.contains(file)) {
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					} else if (file.endsWith('.hx') && !filesPushed.contains(file)) {
						scriptArray.push(new AlterScript(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene) {
			switch (daSong) {
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1 * playbackRate, {
						startDelay: 0.1,
						onComplete: function(twn:FlxTween) {
							camHUD.visible = true;
							remove(whiteScreen, true);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if (gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7 * playbackRate, {
						onComplete: function(twn:FlxTween) {
							remove(blackScreen, true);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer) {
						camHUD.visible = true;
						remove(blackScreen, true);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					if (ClientPrefs.getPref('week7CutScene'))
						tankIntro();
					else startCountdown();

				default: startCountdown();
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.getPref('hitsoundVolume') > 0) precacheList.set('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}', 'sound');
		for (i in 1...4) precacheList.set('missnote$i', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if (ClientPrefs.getPref('pauseMusic') != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.getPref('pauseMusic')), 'music');
		}

		precacheList.set('alphabet', 'image');
	
		#if discord_rpc
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Conductor.safeZoneOffset = (ClientPrefs.getPref('safeFrames') / 60) * 1000;
		callOnLuas('onCreatePost', []);
		callOnScripts('create', []);

		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList) {
			switch(type) {
				case 'image': Paths.image(key);
				case 'sound': Paths.sound(key);
				case 'music': Paths.music(key);
			}
		}
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float {
		if(generatedMusic) {
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.getPref('safeFrames') / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
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
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.visible = false;
					startCharacterLua(newDad.curCharacter);
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
				}
		}
	}

	function startCharacterLua(name:String) {
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush) {
			for (script in luaArray) {
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
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
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueBoxPsych.DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void {
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		if (songName == 'roses' || songName == 'thorns') {
			remove(black, true);

			if (songName == 'thorns') {
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer) {
			black.alpha -= 0.15;

			if (black.alpha > 0) {
				tmr.reset(0.3);
			} else {
				if (dialogueBox != null) {
					if (songName == 'thorns') {
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1) {
								swagTimer.reset();
							} else {
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function() {
									remove(senpaiEvil, true);
									remove(red, true);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					} else {
						add(dialogueBox);
					}
				} else startCountdown();

				remove(black, true);
			}
		});
	}

	function tankIntro() {
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function() {
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff  * playbackRate, {ease: FlxEase.quadInOut});
			moveCamera('dad');
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName) {
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function() {
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function() {
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function() {
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function() {
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function() {
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4 * playbackRate, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5 * playbackRate, {ease: FlxEase.quadInOut, startDelay: 4 * playbackRate});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1 * playbackRate, {ease: FlxEase.quadInOut, startDelay: 4.5 * playbackRate});
				};

				cutsceneHandler.timer(4, function() {
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String) {
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1 * playbackRate, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite) {
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!lowQuality) {
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!lowQuality) {
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function() {
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1) {
						foregroundSprites.forEach(function(spr:BGSprite) {
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function() {
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function() {
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1 * playbackRate, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25 * playbackRate, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String) {
						if(name == 'dieBitch') { //Next part
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						} else {
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String) {
								if(name != 'idle') {
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String) {
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function() {
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function() {
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function() {
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function() {
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String) {
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25 * playbackRate, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function() {
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	var camMovement:Float = 40;
	var velocity:Float = 1;
	var campointx:Float = 0;
	var campointy:Float = 0;
	var camlockx:Float = 0;
	var camlocky:Float = 0;
	var camlock:Bool = false;
	var bfturn:Bool = false;

	function cacheCountdown() {
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function updateLuaDefaultPos() {
		for (i in 0...playerStrums.length) {
			setOnLuas('defaultPlayerStrumPOS' + i, [playerStrums.members[i].x, playerStrums.members[i].y]);
			setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...opponentStrums.length) {
			setOnLuas('defaultOpponentStrumPOS' + i, [opponentStrums.members[i].x, opponentStrums.members[i].y]);
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
				strumLay.cameras = [camHUD];
				strumLay.screenCenter(Y);
				istrums[1].add(strumLay);
			}
		}
	}

	public function startCountdown():Void
	{
		if (startedCountdown) {
			callOnLuas('onStartCountdown', []);
			callOnScripts('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if (ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);

			addLUStrums();
			updateLuaDefaultPos();
	
			setOnLuas('defaultMania', SONG.mania);

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);
			callOnScripts('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			} else if (skipCountdown) {
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer) {
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned) {
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned) {
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned) {
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = globalAntialiasing;
				if (isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if (curStage == 'mall') {
					if(!lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				var introSndPaths:Array<String> = [
					"intro3" + introSoundsSuffix, "intro2" + introSoundsSuffix,
					"intro1" + introSoundsSuffix, "introGo" + introSoundsSuffix
				];
					
				if (swagCounter > 0 && swagCounter <= 3)
					readySetGo(introAlts[swagCounter - 1], antialias, swagCounter - 1);
				FlxG.sound.play(Paths.sound(introSndPaths[swagCounter]), 0.6);

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.getPref('opponentStrums') || note.mustPress) {
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.getPref('middleScroll') && !note.mustPress) {
							note.alpha *= .35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnScripts('onCountdownTick', [swagCounter]);
				swagCounter += 1;
			}, 4);
		}
	}

	function readySetGo(path:String, alias:Bool, ind:Int = 0):Void {
		var antialias:Bool = alias;
		var sprArray:Array<FlxSprite> = [countdownReady, countdownSet, countdownGo];

		var spr:FlxSprite = sprArray[ind];
		spr = new FlxSprite().loadGraphic(Paths.image(path));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();

		if (isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));
		spr.updateHitbox();

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);

		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, (Conductor.crochet / 1000) * playbackRate, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween) {
				remove(spr, true);
				spr.destroy();
			}
		});
	}

	public function addBehindGF(obj:FlxObject) {
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject) {
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxObject) {
		insert(members.indexOf(dadGroup), obj);
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

	var scoreTweenSetting:Array<Dynamic> = [1.1, .2, 'backOut'];
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

			scoreTxt.scale.set(scoreTweenSetting[1], scoreTweenSetting[1]);
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, scoreTweenSetting[2] * playbackRate, {
				ease: LuaUtils.getTweenEaseByString(scoreTweenSetting[3]),
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

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void {
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if(startOnTime > 0) {
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5 * playbackRate, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5 * playbackRate, {ease: FlxEase.circOut});

		switch(curStage) {
			case 'tank':
				if(!lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite) {
					spr.dance();
				});
		}

		#if discord_rpc
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
		callOnScripts('onSongStart', []);
	}

	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	function generateSong(dataPath:String):Void {
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch(songSpeedType) {
			case "multiplicative": songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant": songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices) vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		else vocals = new FlxSound();

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.chart(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsChart(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) { //Event Notes
				for (i in 0...event[1].length) {
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.getPref('noteOffset'),
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
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
				swagNote.sustainLength = Math.round(songNotes[2] / Conductor.stepCrochet) * Conductor.stepCrochet;
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
				swagNote.noteType = songNotes[3];

				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
				if(floorSus > 0) {
					if(floorSus == 1) floorSus++;
					for (susNote in 0...floorSus) {
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
					}
				}

				if (!noteTypeMap.exists(swagNote.noteType))
					noteTypeMap.set(swagNote.noteType, true);
			}
		}
		for (event in songData.events) { //Event Notes
			for (i in 0...event[1].length) {
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.getPref('noteOffset'),
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1': charType = 2;
					case 'dad' | 'opponent' | '0': charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Dadbattle Spotlight':
				if (WeekData.getWeekFileName() == 'week1' && curStage == 'stage') {
					dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
					dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					dadbattleBlack.alpha = 0.25;
					dadbattleBlack.visible = false;
					add(dadbattleBlack);

					dadbattleLight = new BGSprite('spotlight', 400, -400);
					dadbattleLight.alpha = 0.375;
					dadbattleLight.blend = ADD;
					dadbattleLight.visible = false;
					add(dadbattleLight);

					dadbattleFog = new DadBattleFog();
					add(dadbattleFog);
				}

			case 'Philly Glow':
				if (WeekData.getWeekFileName() == 'week3' && curStage == 'philly') {
					blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blammedLightsBlack.visible = false;
					insert(members.indexOf(phillyStreet), blammedLightsBlack);

					phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

					phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
					phillyGlowGradient.visible = false;
					insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
					if(!ClientPrefs.getPref('flashing')) phillyGlowGradient.intendedAlpha = 0.7;

					precacheList.set('philly/particle', 'image'); //precache particle image
					phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
					phillyGlowParticles.visible = false;
					insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
				}

			case 'Play Video Sprite':
				loadVideo(Std.string(event.value1));
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
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

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void {
		for (i in 0...Note.ammo[mania]) {
			var twnDuration:Float = (4 / mania) * playbackRate;
			var twnStart:Float = 0.5 + ((0.8 / mania) * i) * playbackRate;

			var targetAlpha:Float = 1;
			if (player < 1) {
				if (!ClientPrefs.getPref('opponentStrums')) targetAlpha = 0;
				else if (ClientPrefs.getPref('middleScroll')) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.getPref('middleScroll') ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = downScroll;
			babyArrow.scrollFactor.set();
			if (!isStoryMode && !skipArrowStartTween && mania > 1) {
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
			} else {
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1) {
				playerStrums.add(babyArrow);
			} else {
				if (ClientPrefs.getPref('middleScroll')) {
					var separator:Int = Note.separator[mania];
					babyArrow.x += 310;
					if(i > separator) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
			callOnLuas('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);
			callOnScripts('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);

			if (ClientPrefs.getPref('showKeybindsOnStart') && player == 1) {
				for (j in 0...keysArray[mania][i].length) {
					var daKeyTxt:FlxText = new FlxText(babyArrow.x, babyArrow.y - 10, 0, InputFormatter.getKeyName(keysArray[mania][i][j]), 32);
					daKeyTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					daKeyTxt.borderSize = 1.25;
					daKeyTxt.alpha = 0;
					daKeyTxt.size = 32 - mania; //essentially if i ever add 0k!?!?
					daKeyTxt.x = babyArrow.x + (babyArrow.width / 2);
					daKeyTxt.x -= daKeyTxt.width / 2;
					add(daKeyTxt);
					daKeyTxt.cameras = [camHUD];
					daKeyText.push(daKeyTxt);
					var textY:Float = (j == 0 ? babyArrow.y - 32 : ((babyArrow.y - 32) + babyArrow.height) - daKeyTxt.height);
					daKeyTxt.y = textY;

					if (mania > 1 && !skipArrowStartTween) {
						FlxTween.tween(daKeyTxt, {y: textY + 32, alpha: 1}, twnDuration, {ease: FlxEase.circOut, startDelay: twnStart});
					} else {
						daKeyTxt.y += 16;
						daKeyTxt.alpha = 1;
					}
					new FlxTimer().start(Conductor.crochet * 0.001 * 12, function(_) {
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
			if (note.changeAnim) {
				note.animation.play(Note.keysShit.get(mania).get('letters')[noteData % tMania]);
			}
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
				oldStrum.cameras = [camHUD];
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
		if (paused) {
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (FlxG.sound.music != null && !startingSong) {
				resyncVocals();
			}

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) {
				if (!tmr.finished) tmr.active = true;
			});
			FlxTween.globalManager.forEach(function(twn:FlxTween) {
				if (!twn.finished) twn.active = true;
			});

			PsychVideo.isActive(true);

			paused = false;
			callOnLuas('onResume', []);

			#if discord_rpc
			if (startTimer != null && startTimer.finished) {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
			} else DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void {
		#if discord_rpc
		if (health > 0 && !paused) {
			if (Conductor.songPosition > .0) {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.getPref('noteOffset'));
			} else DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		PsychVideo.isActive(true);
		callOnLuas('onFocus', []);
		callOnScripts('onFocus', []);
		super.onFocus();
	}

	override public function onFocusLost():Void {
		#if discord_rpc
		if (health > 0 && !paused)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		PsychVideo.isActive(false);
		callOnLuas('onFocusLost', []);
		callOnScripts('onFocusLost', []);
		super.onFocusLost();
	}

	override public function onResize(Width:Int, Height:Int):Void {
		callOnLuas('onResize', [Width, Height]);
		callOnScripts('onResize', [Width, Height]);
		super.onResize(Width, Height);
	}

	function resyncVocals():Void {
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length) {
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float) {
		callOnLuas('onUpdate', [elapsed]);
		callOnScripts('update', [elapsed]);

		grpNoteSplashes.forEachDead(function(splash:NoteSplash) {
			if (grpNoteSplashes.length > 1) {
				grpNoteSplashes.remove(splash, true);
				splash.destroy();
			}
		});

		if(disableTheTripperAt == curStep || isDead)
			disableTheTripper = true;

		screenshader.update(elapsed);
		if(disableTheTripper && screenshader.ampmul >= 0) {
			screenshader.ampmul -= (elapsed / 2);
		}

		if(ClientPrefs.getPref('camMovement')) {
			if(camlock) camFollow.set(camlockx, camlocky);
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
					if (!ClientPrefs.getPref('middleScroll')) {
						for (strumLU in strums)
							for (i in 0...strumLU[1].members.length)
								if (strumLU[1].members[i] != null)
									strumLU[1].members[i].x = strumLU[0].members[i].x;
					}
			}
		}

		switch (curStage) {
			case 'philly':
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha <= 0) {
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, MathUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = MathUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else boyfriendIdleTime = 0;
		}

		super.update(elapsed);

		scoreTxt.x = Math.floor((FlxG.width / 2) - (scoreTxt.width / 2));
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
			if (nps > maxNPS)
				maxNPS = nps;
			
			UpdateScoreText();
		}

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause) {
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene) {
			openChartEditor();
		}

		switch(ClientPrefs.getPref('IconBounceType')) {
			case "Vanilla":
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, .85)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, .85)));
			case "Kade" | "SC": // Stolen from Vanilla Engine
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, .5)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, .5)));
			case "Psych":
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, MathUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP1.scale.set(mult, mult);
				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, MathUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP2.scale.set(mult, mult);
			case "Dave" | "BP":
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, .88)), Std.int(FlxMath.lerp(150, iconP1.height, .88)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, .88)), Std.int(FlxMath.lerp(150, iconP2.height, .88)));
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		final iconOffset:Int = 26;
		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
		if (health > healthMax)
			health = healthMax;

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

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startedCountdown)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

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
					var timebarType:String = ClientPrefs.getPref('timeBarType');
					var curTime:Float = Conductor.songPosition - ClientPrefs.getPref('noteOffset');
					if(curTime < 0) curTime = 0;
					songPercent = curTime / songLength;

					var songCalc:Float = songLength - curTime;
					switch (timebarType) {
						case 'Time Elapsed' | 'Time Position' | 'Name Elapsed' | 'Name Time Position':
							songCalc = curTime;
					}

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0) secondsTotal = 0;

					var timePos:String = FlxStringUtil.formatTime(secondsTotal) + " / " + FlxStringUtil.formatTime(Math.floor(songLength / 1000));
					if (timebarType != 'Song Name')
						switch (timebarType) {
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
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, MathUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(defaultHudCamZoom, camHUD.zoom, MathUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.getPref('noReset') && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong) {
			health = 0;
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
				callOnScripts('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic) {
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
				
				if(startedCountdown) {
					var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
					notes.forEachAlive(function(daNote:Note) {
						var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
						if(!daNote.mustPress) strumGroup = opponentStrums;
					
						if (strumGroup.members[daNote.noteData] == null) daNote.noteData = mania;
					
						var strumX:Float = strumGroup.members[daNote.noteData].x;
						var strumY:Float = strumGroup.members[daNote.noteData].y;
						var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
						var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
						var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
						var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;
					
						strumX += daNote.offsetX;
						strumY += daNote.offsetY;
						strumAngle += daNote.offsetAngle;
						strumAlpha *= daNote.multAlpha;
					
						if (daNote.randomized) {
							if (strumScroll) { //Downscroll
								daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed * daNote.localScrollSpeed);
							} else { //Upscroll
								daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed * daNote.localScrollSpeed);
							}
						} else {
							if (strumScroll) { //Downscroll
								daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
							} else { //Upscroll
								daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
							}
						}
					
						var angleDir = strumDirection * Math.PI / 180;
						if(daNote.isSustainNote)
							daNote.angle = strumDirection - 90;
	
						if (daNote.copyAngle)
							daNote.angle = strumDirection - 90 + strumAngle;
					
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
									if(isPixelStage) {
										daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * daPixelZoom;
									} else {
										daNote.y -= 19;
									}
								}
								daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
								daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1) * Note.scales[mania];
							}
						}
					
						if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
							opponentNoteHit(daNote);
						}
					
						if(!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit) {
							if(daNote.isSustainNote) {
								if(daNote.canBeHit) {
									goodNoteHit(daNote);
								}
							} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
								goodNoteHit(daNote);
							}
						}
					
						var center:Float = strumY + Note.swagWidth / 2;
						if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
							(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							if (strumScroll) {
								if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center) {
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;
								
									daNote.clipRect = swagRect;
								}
							} else {
								if (daNote.y + daNote.offset.y * daNote.scale.y <= center) {
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;
								
									daNote.clipRect = swagRect;
								}
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
				} else {
					notes.forEachAlive(function(daNote:Note) {
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function openPauseMenu()
	{
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
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
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
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				#if discord_rpc
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
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
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				if (WeekData.getWeekFileName() == 'week1' && curStage == 'stage') {
					var val:Null<Int> = Std.parseInt(value1);
					if(val == null) val = 0;

					switch(Std.parseInt(value1)) {
						case 1, 2, 3: //enable and target dad
							if (val == 1) { //enable
								dadbattleBlack.visible = true;
								dadbattleLight.visible = true;
								dadbattleFog.visible = true;
								defaultCamZoom += 0.12;
							}

							var who:Character = dad;
							if(val > 2) who = boyfriend;
							//2 only targets dad
							dadbattleLight.alpha = 0;
							new FlxTimer().start(0.12, function(tmr:FlxTimer) {
								dadbattleLight.alpha = 0.375;
							});
							dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

						default:
							dadbattleBlack.visible = false;
							dadbattleLight.visible = false;
							defaultCamZoom -= 0.12;
							FlxTween.tween(dadbattleFog, {alpha: 0}, 1 * playbackRate, {onComplete: function(twn:FlxTween) {
								dadbattleFog.visible = false;
							}});
					}
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0': value = 0;
					case 'gf' | 'girlfriend' | '1': value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter == gfChecknull) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Philly Glow':
				if (WeekData.getWeekFileName() == 'week3' && curStage == 'philly') {
					var lightId:Int = Std.parseInt(value1);
					if(Math.isNaN(lightId)) lightId = 0;

					var doFlash:Void->Void = function() {
						var color:FlxColor = FlxColor.WHITE;
						if(!ClientPrefs.getPref('flashing')) color.alphaFloat = 0.5;

						FlxG.camera.flash(color, 0.15, null, true);
					};
					
					var chars:Array<Character> = [boyfriend, gf, dad];
					switch(lightId)
					{
						case 0:
							if(phillyGlowGradient.visible)
							{
								doFlash();
								if(ClientPrefs.getPref('camZooms'))
								{
									FlxG.camera.zoom += 0.5;
									camHUD.zoom += 0.1;
								}

								blammedLightsBlack.visible = false;
								phillyWindowEvent.visible = false;
								phillyGlowGradient.visible = false;
								phillyGlowParticles.visible = false;
								curLightEvent = -1;

								for (who in chars)
								{
									who.color = FlxColor.WHITE;
								}
								phillyStreet.color = FlxColor.WHITE;
							}

						case 1: //turn on
							curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							var flashing:Bool = ClientPrefs.getPref('flashing');

							if(!phillyGlowGradient.visible)
							{
								doFlash();
								if(ClientPrefs.getPref('camZooms')) {
									FlxG.camera.zoom += 0.5;
									camHUD.zoom += 0.1;
								}

								blammedLightsBlack.visible = true;
								blammedLightsBlack.alpha = 1;
								phillyWindowEvent.visible = true;
								phillyGlowGradient.visible = true;
								phillyGlowParticles.visible = true;
							}
							else if(flashing)
							{
								var colorButLower:FlxColor = color;
								colorButLower.alphaFloat = 0.25;
								FlxG.camera.flash(colorButLower, 0.5, null, true);
							}

							var charColor:FlxColor = color;
							if(!flashing) charColor.saturation *= 0.5;
							else charColor.saturation *= 0.75;

							for (who in chars) {
								who.color = charColor;
							}
							phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle) {
								particle.color = color;
							});
							phillyGlowGradient.color = color;
							phillyWindowEvent.color = color;

							color.brightness *= 0.5;
							phillyStreet.color = color;

						case 2: // spawn particles
							if(!lowQuality) {
								var particlesNum:Int = FlxG.random.int(8, 12);
								var width:Float = (2000 / particlesNum);
								var color:FlxColor = phillyLightsColors[curLightEvent];
								for (j in 0...3)
								{
									for (i in 0...particlesNum)
									{
										var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
										phillyGlowParticles.add(particle);
									}
								}
							}
							phillyGlowGradient.bop();
					}
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.getPref('camZooms') && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Set Camera Zoom':
				var defCamZoom:Float = Std.parseFloat(value1);
				var defHudZoom:Float = Std.parseFloat(value2);
				if(Math.isNaN(defCamZoom)) defCamZoom = defaultCamZoom;
				if(Math.isNaN(defHudZoom)) defHudZoom = 1;
				defaultCamZoom = defCamZoom;
				defaultHudCamZoom = defHudZoom;

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend': char = boyfriend;
					case 'gf' | 'girlfriend': char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
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
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.set(val1, val2);
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
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
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

			case '\"Screw you!\" Text Change':
				if (screwYouTxt.text != null)
					if (songNameText.y != songNameText.y - 20)
						songNameText.y -= 20;

				screwYouTxt.text = value1;

				if(screwYouTxt.text == null || screwYouTxt.text == "")
					songNameText.y = FlxG.height - songNameText.height;
				else songNameText.y = (FlxG.height - songNameText.height) - 20;

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();

			case 'Rainbow Eyesore':
				if(ClientPrefs.getPref('shaders')) {
					var splitedVal:Array<String> = value1.trim().split(',');
					var shadeLen:Int = (splitedVal[2] != null ? Std.parseInt(splitedVal[2]) : 0);

					disableTheTripper = false;
					disableTheTripperAt = Std.parseInt(splitedVal[0]);

					screenshader.waveSpeed = Std.parseFloat(splitedVal[1]);
					screenshader.shader.uTime.value[0] = FlxG.random.float(-100000, 100000);
					screenshader.ampmul = 1;

					if (shaderFilters[shadeLen] == null)
						shaderFilters[shadeLen] = new ShaderFilter(screenshader.shader);

					switch(value2.trim().toLowerCase()) {
						case 'camhud' | 'hud':
							camHUD.setFilters(shaderFilters);
						case 'camother' | 'other':
							camOther.setFilters(shaderFilters);
						default: camGame.setFilters(shaderFilters);
					}
				}

			case 'Change Scroll Speed':
				if (songSpeedType == "constant") return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0) songSpeed = newValue;
				else {
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 * playbackRate, {
						onComplete: function(twn:FlxTween) {
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
				if (killMe.length > 1) {
					LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe, true, true), killMe[killMe.length - 1], trueVal != null ? trueVal : value2);
				} else {
					LuaUtils.setVarInArray(this, value1, trueVal != null ? trueVal : value2);
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection) {
			moveCamera('gf');
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection) {
			moveCamera('dad');
			if(ClientPrefs.getPref('camMovement')) {
				campointx = camFollow.x;
				campointy = camFollow.y;
				bfturn = false;
				camlock = false;
				cameraSpeed = 1;
			}
			callOnLuas('onMoveCamera', ['dad']);
		} else {
			moveCamera('boyfriend');
			if(ClientPrefs.getPref('camMovement')) {
				campointx = camFollow.x;
				campointy = camFollow.y;	
				bfturn = true;
				camlock = false;
				cameraSpeed = 1;
			}
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(moveCameraTo:Dynamic) {
		if(moveCameraTo == 'dad' || moveCameraTo) {
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		} else if(moveCameraTo == 'boyfriend' || !moveCameraTo) {
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1) {
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
		} else {
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
		}
	}

	function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000) * playbackRate, {ease: FlxEase.elasticInOut, 
				onComplete: function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.getPref('noteOffset') <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.getPref('noteOffset') / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	public var transitioning = false;
	public function endSong():Void {
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

			if(doDeathCheck()) return;
		}

		notes.forEachAlive(function(note:Note) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		});

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
			var customAchieve:String = checkForAchievement(achievementWeeks);

			if (achieve != null || customAchieve != null) {
				startAchievement(customAchieve != null ? customAchieve : achieve);
				return;
			}
		}
		#end

		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);

			playbackRate = 1;

			if (chartingMode) {
				openChartEditor();
				return;
			}

			if (isStoryMode) {
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
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

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (songName == "eggnog");
					if (winterHorrorlandNext) {
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					SONG = Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			} else {
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
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
	public var totalNotesHit:Float = 0.0;

	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore() {
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
		screwYouTxt.y = songNameText.y;
		if (screwYouTxt.text != null && screwYouTxt.text != "")
			songNameText.y -= 20;

		for (dakey in daKeyText)
			dakey.font = font;
		screwYouTxt.font = font;
	}

	var scoreSeparator:String = "|";
	function getMissText(hidden:Bool = false, sepa:String = ' '):String {
		var missText = "";
		var sepaSpace:String = (sepa != '\n' ? scoreSeparator + ' ' : '');
		if (cpuControlled || hidden) return missText;

		switch (ClientPrefs.getPref('ScoreType')) {
			case 'Alter':
				missText = sepaSpace + 'Misses:$songMisses';
			case 'Kade':
				missText = '${sepa != '\n' ? scoreSeparator + ' Combo Breaks:' : 'Combo Breaks: '}$songMisses';
			case 'Psych':
				missText = sepaSpace + 'Misses: $songMisses';

		} return missText + sepa;
	}

	function UpdateScoreText() {
		var tempText:String = (ClientPrefs.getPref('ShowNPSCounter') ? (ClientPrefs.getPref('ScoreType') == 'Kade' ? 'NPS:$nps (Max:$maxNPS) $scoreSeparator ' : 'NPS:$nps ($maxNPS) $scoreSeparator ') : '');
		var tempMiss:String = getMissText(ClientPrefs.getPref('movemissjudge'));
		
		switch(ClientPrefs.getPref('ScoreType')) {
			case 'Alter':
				tempText += 'Score:${!cpuControlled ? songScore : botScore} ';
				tempText += tempMiss;
				tempText += '$scoreSeparator Accuracy:$accuracy%' + (ratingName != '?' ? ' [$ratingName, $ranks] - $ratingFC' : ' [?, ?] - ?');
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

	private function popUpScore(note:Note = null):Void {
		var noteDiff = getNoteDiff(note);

		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var score:Int = 500;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);
		var daTiming:String = "";
		var msTiming:Float = 0;

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled) {
			spawnNoteSplashOnNote(note);
		}

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
			var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
			coolText.screenCenter();
			coolText.x = FlxG.width * 0.35;
			
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
			if (ratingDisplay == "Hud") {
				rating.cameras = [camHUD];
			}
			rating.screenCenter();
			rating.x = coolText.x - 40;
			rating.y -= 60;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.visible = !hideHud && showRating;
			rating.x += comboOffset[0][0];
			rating.y -= comboOffset[0][1];
		
			if (daTiming != "") {
				timing.loadGraphic(Paths.image(pixelShitPart1 + 'ratings/' + daTiming.toLowerCase() + pixelShitPart2));
			}
			if (ratingDisplay == "Hud") {
				timing.cameras = [camHUD];
			}
			timing.screenCenter();
			timing.x = coolText.x - 130;
			timing.acceleration.y = 550 * playbackRate * playbackRate;
			timing.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			timing.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			timing.visible = !hideHud && ClientPrefs.getPref('ShowLateEarly');
			timing.x += comboOffset[3][0];
			timing.y -= comboOffset[3][1];
		
			if (ClientPrefs.getPref('ShowMsTiming') && mstimingTxt != null) {
				msTiming = MathUtil.truncateFloat(noteDiff / playbackRate);
				
				mstimingTxt.setFormat(flixel.system.FlxAssets.FONT_DEFAULT, 20, FlxColor.WHITE, CENTER);
				mstimingTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
				mstimingTxt.visible = !hideHud;
				mstimingTxt.text = msTiming + "ms";
				if (ratingDisplay == "Hud") {
					mstimingTxt.cameras = [camHUD];
				}
			
				switch (daRating.name) {
					case 'shit' | 'bad': mstimingTxt.color = FlxColor.RED;
					case 'good': mstimingTxt.color = FlxColor.GREEN;
					case 'sick': mstimingTxt.color = FlxColor.CYAN;
					case 'epic': mstimingTxt.color = FlxColor.fromString('#784FFF');
				}
				add(mstimingTxt);
			}
		
			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'ratings/combo' + pixelShitPart2));
			if (ratingDisplay == "Hud") {
				comboSpr.cameras = [camHUD];
			}
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboSpr.visible = !hideHud;
			comboSpr.x += comboOffset[2][0];
			comboSpr.y -= comboOffset[2][1];
		
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
				rating.antialiasing = globalAntialiasing;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * .7));
				comboSpr.antialiasing = globalAntialiasing;
				timing.setGraphicSize(Std.int(timing.width * .7));
				timing.antialiasing = globalAntialiasing;
			} else {
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * .85));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * .85));
				timing.setGraphicSize(Std.int(timing.width * daPixelZoom * .85));
			}
		
			comboSpr.updateHitbox();
			rating.updateHitbox();
			timing.updateHitbox();
		
			var seperatedScore:Array<Int> = [];
			var comboSplit:Array<String> = (combo + '').split('');
		
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
				if (ratingDisplay == "Hud") {
					numScore.cameras = [camHUD];
				}
				numScore.screenCenter();
				numScore.x = (coolText.x + (43 * daLoop) - 90) + comboOffset[1][0];
				numScore.y += 80 - comboOffset[1][1];
			
				if (!ClientPrefs.getPref('comboStacking'))
					lastScore.push(numScore);
			
				if (!isPixelStage) {
					numScore.antialiasing = globalAntialiasing;
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
		var notediff:Float = 0;
		switch(ClientPrefs.getPref('NoteDiffTypes')) {
			case 'Psych':
				notediff = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.getPref('ratingOffset'));
			case 'Kade':
				if (note != null) notediff = note.strumTime - Conductor.songPosition;
				else notediff = Conductor.safeZoneOffset;
			case 'Simple':
				notediff = note.strumTime - Conductor.songPosition;
		}

		return notediff;
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong) {
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.getPref('ghostTapping');

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note) {
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit) {
						if (daNote.noteData == key) {
							sortedNotesList.push(daNote);
						}
						canMiss = !ClientPrefs.getPref('AntiMash');
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList) {
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				} else {
					callOnLuas('onGhostTap', [key]);
					callOnScripts('onGhostTap', [key]);
					if (canMiss) {
						noteMissPress(key);
					}
				}

				// this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm') {
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
			callOnScripts('onKeyPress', [key]);
		}
	}

	function sortHitNotes(a:Note, b:Note):Int {
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && startedCountdown && !paused && key > -1) {
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null) {
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
			callOnScripts('onKeyRelease', [key]);
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int {
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

	private function keysArePressed():Bool {
		for (i in 0...keysArray[mania].length) {
			for (j in 0...keysArray[mania][i].length) {
				if (FlxG.keys.checkStatus(keysArray[mania][i][j], PRESSED)) return true;
			}
		}

		return false;
	}

	private function dataKeyIsPressed(data:Int):Bool {
		for (i in 0...keysArray[mania][data].length) {
			if (FlxG.keys.checkStatus(keysArray[mania][data][i], PRESSED)) return true;
		}

		return false;
	}

	//Hold Notes
	private function keyShit():Void {
		if (startedCountdown && !boyfriend.stunned && generatedMusic) {
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note) {
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && dataKeyIsPressed(daNote.noteData % Note.ammo[mania]) && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if (keysArePressed() && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
				   startAchievement(achieve);
				}
				#end
			} else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
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
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) {
			gf.playAnim('sad');
		}
		if (combo > maxCombo) maxCombo = combo;
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		
		if(instakillOnMiss) {
			vocals.volume = 0;
			doDeathCheck(true);
		}

		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if (daNote.gfNote) char = gf;

		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations) {
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		callOnScripts('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void { //You pressed a key when there was no notes to press for this key
		if(ClientPrefs.getPref('ghostTapping')) return; //fuck it

		if (!boyfriend.stunned) {
			health -= 0.05 * healthLoss;
			if(instakillOnMiss) {
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) {
				gf.playAnim('sad');
			}
			if (combo > maxCombo) maxCombo = combo;
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) songMisses++;
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			vocals.volume = 0;
		}
		callOnLuas('noteMissPress', [direction]);
		callOnScripts('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void {
		if (songName != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if (!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null) {
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null) {
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
		note.hitByOpponent = true;

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
		var camTimer:FlxTimer;

		if (ClientPrefs.getPref('camMovement') && !isPixelStage) {
			if(!bfturn) {
				switch (animToPlay) {
					case "singLEFT":
						camlockx = campointx - camMovement;
						camlocky = campointy;
					case "singDOWN":
						camlocky = campointy + camMovement;
						camlockx = campointx;
					case "singUP":
						camlocky = campointy - camMovement;
						camlockx = campointx;
					case "singRIGHT":
						camlockx = campointx + camMovement;
						camlocky = campointy;
				}
				camTimer = new FlxTimer().start(1);
				cameraSpeed = velocity;
				camlock = true;
				if(camTimer.finished) {
					camlock = false;
					cameraSpeed = 1;
					camFollow.set(campointx, campointy);
					camTimer = null;
				} 
			}
		}

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		callOnScripts('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote) {
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.getPref('hitsoundVolume') > 0 && !note.hitsoundDisabled) {
				FlxG.sound.play(Paths.sound('hitsounds/${Std.string(ClientPrefs.getPref('hitsoundTypes')).toLowerCase()}'), ClientPrefs.getPref('hitsoundVolume'));
			}

			var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
			if(!note.mustPress) strumGroup = opponentStrums;

			if (!note.isSustainNote)
				notesHitArray.unshift(Date.now());

			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
			var camTimer:FlxTimer;

			if (ClientPrefs.getPref('camMovement')) {
				if(bfturn) {
					switch (animToPlay) {
						case "singLEFT":
							camlockx = campointx - camMovement;
							camlocky = campointy;
						case "singDOWN":
							camlocky = campointy + camMovement;
							camlockx = campointx;
						case "singUP":
							camlocky = campointy - camMovement;
							camlockx = campointx;
						case "singRIGHT":
							camlockx = campointx + camMovement;
							camlocky = campointy;
					}
					
					camTimer = new FlxTimer().start(1);
					cameraSpeed = velocity;
					camlock = true;
					if(camTimer.finished) {
						camlock = false;
						cameraSpeed = 1;
						camFollow.set(campointx, campointy);
						camTimer = null;
					} 
				}
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

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

			if (!note.isSustainNote) {
				combo += 1;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];

				if(note.gfNote) {
					if(gf != null) {
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				} else {
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			} else {
				var spr = playerStrums.members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);

			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
			callOnScripts('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
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
			var hue:Float = arrowHSV[arrowIndex][0] / 360;
			var sat:Float = arrowHSV[arrowIndex][1] / 100;
			var brt:Float = arrowHSV[arrowIndex][2] / 100;
			
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

	var fastCarCanDrive:Bool = true;
	function resetFastCar():Void {
		fastCar.setPosition(-12600, FlxG.random.int(140, 250));
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive() {
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer) {
			resetFastCar();
			carTimer = null;
		});
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.getPref('camZooms')) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5 * playbackRate);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5 * playbackRate);
			}
		}

		if (ClientPrefs.getPref('flashing')) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075 * playbackRate);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25 * playbackRate, {startDelay: 0.15 * playbackRate});
		}
	}

	function killHenchmen():Void
	{
		if(!lowQuality && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		PsychVideo.clearAll();
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) return;

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
		callOnScripts('onStepHit', [curStep]);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) return;

		if (generatedMusic) {
			notes.sort(FlxSort.byY, downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
		
		switch (ClientPrefs.getPref('IconBounceType')) {
			case 'Vanilla' | 'Kade':
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
			case "Psych":
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
			case "Dave" | "BP":
				var funny:Float = Math.max(Math.min(healthBar.value, 1.9), .1);
	
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + .1))), Std.int(iconP1.height - (25 * funny)));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + .1))), Std.int(iconP2.height - (25 * ((2 - funny) + .1))));

				if (ClientPrefs.getPref('IconBounceType') == "BP") {
					if (curBeat % 4 == 0) {
						FlxTween.angle(iconP1, -30, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP2, 30, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
					}
				}
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
			case "SC":
				var funny:Float = (healthBar.percent * .01) + .01;
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (2 + funny))), Std.int(iconP2.height - (25 * (2 + funny))));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))), Std.int(iconP2.height - (25 * (2 - funny))));
		
				iconP1.scale.set(1.1, .8);
				iconP2.scale.set(1.1, .8);
		
				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut}); 
		
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned) {
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned) {
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned) {
			dad.dance();
		}

		switch (curStage) {
			case 'tank':
				if(!lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite) {
					spr.dance();
				});

			case 'school':
				if(!lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer) {
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();

			case "philly":
				phillyTrain.beatHit(curBeat);

				if (curBeat % 4 == 0) {
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) {
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
		callOnScripts('beatHit', [curBeat]);
	}

	override function sectionHit() {
		super.sectionHit();

		if (SONG.notes[curSection] != null) {
			if (generatedMusic && !endingSong && !isCameraOnForcedPos) {
				moveCameraSection();
			}

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
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
		callOnScripts('sectionHit', [curSection]);
	}

	#if LUA_ALLOWED
	public function startLuasOnFolder(luaFile:String) {
		for (script in luaArray) {
			if(script.scriptName == luaFile) return false;
		}

		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(luaToLoad)) {
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		} else {
			luaToLoad = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaToLoad)) {
				luaArray.push(new FunkinLua(luaToLoad));
				return true;
			}
		}
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad)) {
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		#end
		return false;
	}
	#end

	public function callOnScripts(event:String, args:Array<Dynamic>):Void {
		return for (i in scriptArray) i.call(event, args);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions != null && exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if(myValue == FunkinLua.Function_StopLua && !ignoreStops)
				break;

			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			if(myValue != null && myValue != FunkinLua.Function_Continue)
				returnVal = myValue;
		}
		for (i in achievementsArray) i.call(event, args);
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
			luaArray[i].set(variable, arg);
		for(i in achievementsArray) i.set(variable, arg);
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if (isDad) spr = strumLineNotes.members[id];
		else spr = playerStrums.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time / playbackRate;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

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

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (practiceMode || cpuControlled);
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.exists(achievementName)) {
				var unlock:Bool = false;
				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('_nomiss')) { // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss"
					if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				} else {
					switch(achievementName) {
						case 'ur_bad':
							if(ratingPercent < .2 && !practiceMode) {
								unlock = true;
							}
						case 'ur_good':
							if(ratingPercent >= 1 && !usedPractice) {
								unlock = true;
							}
						case 'roadkill_enthusiast':
							if(Achievements.henchmenDeath >= 100) {
								unlock = true;
							}
						case 'oversinging':
							if(boyfriend.holdTimer >= 10 && !usedPractice) {
								unlock = true;
							}
						case 'hype':
							if(!boyfriendIdled && !usedPractice) {
								unlock = true;
							}
						case 'two_keys':
							if(!usedPractice) {
								var howManyPresses:Int = 0;
								for (j in 0...keysPressed.length) {
									if(keysPressed[j]) howManyPresses++;
								}
	
								if(howManyPresses <= 2) {
									unlock = true;
								}
							}
						case 'toastie':
							if(lowQuality && !globalAntialiasing && !ClientPrefs.getPref('shaders')) {
								unlock = true;
							}
						case 'debugger':
							if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
								unlock = true;
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

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}