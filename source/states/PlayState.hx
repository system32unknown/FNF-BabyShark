package states;

import haxe.Timer;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.util.FlxSort;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;
import shaders.ErrorHandledShader;
import backend.Highscore;
import backend.Song;
import backend.Judgement;
import states.editors.*;
import substates.GameOverSubstate;
import substates.PauseSubState;
import objects.Note.EventNote;
import objects.*;
import utils.*;
import utils.system.MemoryUtil;
import data.*;
import psychlua.*;
import cutscenes.DialogueBoxPsych;
#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import alterhscript.AlterHscript;
import hscript.Printer;
#end

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

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedRate:Float = 1;
	public var songSpeedType:String = "multiplicative";

	public final noteKillTime:Float = 350;
	public var noteKillOffset:Float = 0;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = '';
	public static var uiPostfix:String = '';
	public static var isPixelStage(get, never):Bool;
	@:noCompletion static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");
	public var popupAntialias:Bool = true;

	@:noCompletion static function set_stageUI(value:String):String {
		uiPrefix = uiPostfix = "";
		if (value != "normal") {
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 1500;

	public var inst:FlxSound;
	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	public var gameOverChar:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var unspawnSustainNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	public static var splashUsing:Array<Array<NoteSplash>>;
	public static var splashMoment:Vector<Int>;
	var splashCount:Int = ClientPrefs.data.splashCount != 0 ? ClientPrefs.data.splashCount : 2147483647;

	public var canTweenCamZoom:Bool = false;
	public var canTweenCamZoomBoyfriend:Float = 1;
	public var canTweenCamZoomDad:Float = 1;
	public var canTweenCamZoomGf:Float = 1.3;

	public var dontZoomCam:Bool = false;
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingFrequency:Float = 4;
	public var camZoomingDecay:Float = 1;

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	var healthLerp:Float = 1;

	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var judgeData:Array<Judgement> = Judgement.loadDefault();
	public static var mania:Int = 3;

	var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = .05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

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

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	public var hscriptArray:Array<HScript> = [];
	var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';
	public var introSoundNames:Array<String> = [];

	var keysArray:Array<String>;
	public var pressHit:Int = 0;

	public var popUpGroup:FlxTypedSpriteGroup<Popup>;
	public var uiGroup:FlxSpriteGroup;
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	public var songName:String;

	var downScroll:Bool = ClientPrefs.data.downScroll;
	var middleScroll:Bool = ClientPrefs.data.middleScroll;
	var hideHud:Bool = ClientPrefs.data.hideHud;
	var timeType:String = ClientPrefs.data.timeBarType; 

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	var optimizeSpawnNote:Bool = ClientPrefs.data.optimizeSpawnNote;

	static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;
	override public function create() {
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearStoredMemory();
		if (nextReloadAll) {
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;
		noteKillOffset = noteKillTime;
		
		startCallback = startCountdown;
		endCallback = endSong;

		instance = this;
		PauseSubState.songName = null; //Reset to default

		FlxG.sound.music?.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		camGame = initPsychCamera(); camHUD = new FlxCamera(); camOther = new FlxCamera();
		camHUD.bgColor.alpha = camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		persistentUpdate = persistentDraw = true;

		Conductor.setBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		if (SONG.mania == null || SONG.mania < EK.minMania || SONG.mania > EK.maxMania) SONG.mania = EK.defaultMania;
		mania = SONG.mania;
		keysArray = EK.fillKeys()[mania];
		splashUsing = [for (_ in 0...EK.keys(mania)) []];
		splashMoment = new Vector<Int>(EK.keys(mania), 0);

		storyDifficultyText = Difficulty.getString();
		#if DISCORD_ALLOWED
		if (isStoryMode) detailsText = 'Story Mode: ${WeekData.getCurrentWeek().weekName}';
		else detailsText = "Freeplay";
		detailsPausedText = 'Paused - $detailsText';
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if (SONG.stage == null || SONG.stage.length < 1) SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));
		curStage = SONG.stage;

		var stageData:data.StageData.StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0) stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) stageUI = "pixel";

		popupAntialias = ClientPrefs.data.antialiasing && !isPixelStage;

		BF_X = stageData.boyfriend[0]; BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0]; GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0]; DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		boyfriendCameraOffset ??= [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		opponentCameraOffset ??= [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		girlfriendCameraOffset ??= [0, 0];

		introSoundNames = stageData.introSounds;
		if (introSoundNames == null || introSoundNames.length < 4) introSoundNames = ["intro3", "intro2", "intro1", "introGo"];
		for (sndName in introSoundNames) {
			if (sndName == null) continue;
			introSoundNames[introSoundNames.indexOf(sndName)] = sndName.trim(); // trim trailing spaces in the sound, just in case, JUST in case.
		}

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
			case 'davehouse' | 'davehouse-night' | 'davehouse-sunset': new states.stages.DaveHouse(); //Week Dave
			case 'bambifarm' | 'bambifarm-night' | 'bambifarm-sunset': new states.stages.BambiFarm(); //Week Bambi
		}
		if (isPixelStage) introSoundsSuffix = '-pixel';

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend) {
			if (SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(.95, .95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
	
		if (stageData.objects != null && stageData.objects.length > 0) {
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list) if (!StageData.reservedNames.contains(key)) variables.set(key, spr);
		} else {
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}

		#if (LUA_ALLOWED && HSCRIPT_ALLOWED) // "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/')) for (file in FileSystem.readDirectory(folder)) {
			if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
			if (file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
		}
		#end

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null) {
			final mid:FlxPoint = gf.getGraphicMidpoint();
			camPos.add(mid.x + gf.cameraPosition[0], mid.y + gf.cameraPosition[1]);
			mid.put();
		}
		
		if (dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if (gf != null) gf.visible = false;
		}

		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('stages/$curStage.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('stages/$curStage.hx'); #end

		if (gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);

		add(noteGroup = new FlxTypedGroup<FlxBasic>());
		showPopups = ClientPrefs.data.showComboCounter && (showRating || showComboNum);
		if (showPopups) add(popUpGroup = new FlxTypedSpriteGroup<Popup>());
		add(uiGroup = new FlxSpriteGroup());

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = timeType != 'Disabled';
		timeTxt = new FlxText(0, 19, 400, "", 16);
		timeTxt.gameCenter(X);
		timeTxt.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.visible = updateTime = showTime;
		if (downScroll) timeTxt.y = FlxG.height - 35;
		if (timeType == 'Song Name') timeTxt.text = SONG.song + ' - $storyDifficultyText' + (playbackRate != 1 ? ' (${playbackRate}x)' : '');

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', () -> return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.gameCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar); uiGroup.add(timeTxt);

		noteGroup.add(strumLineNotes);
		generateSong();
		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		healthBar = new Bar(0, downScroll ? 50 : FlxG.height * .9, 'healthBar', () -> return healthLerp, 0, 2);
		healthBar.gameCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		if (!instakillOnMiss) uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP2 = new HealthIcon(dad.healthIcon);
		for (icon in [iconP1, iconP2]) {
			icon.y = healthBar.y - (icon.height / 2);
			icon.visible = !hideHud;
			icon.alpha = ClientPrefs.data.healthBarAlpha;
			if (ClientPrefs.data.healthTypes == 'Psych') icon.iconType = 'psych';
			if (!instakillOnMiss) uiGroup.add(icon);
		}

		scoreTxt = new FlxText(FlxG.width / 2, Math.floor(healthBar.y + 35), FlxG.width);
		scoreTxt.setFormat(Paths.font("babyshark.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		scoreTxt.visible = !hideHud;
		scoreTxt.scrollFactor.set();
		scoreTxt.gameCenter(X);
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y + (downScroll ? 70 : -90), FlxG.width - 800, Language.getPhrase("Botplay", "BOTPLAY"), 32);
		botplayTxt.setFormat(Paths.font("babyshark.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);

		uiGroup.cameras = noteGroup.cameras = [camHUD];
		if (showPopups) popUpGroup.cameras = (ClientPrefs.data.ratingDisplay == "Hud" ? [camHUD] : [camGame]);
		startingSong = true;

		for (notetype in noteTypes) {
			#if LUA_ALLOWED startLuasNamed('custom_notetypes/$notetype.lua'); #end
			#if HSCRIPT_ALLOWED startHScriptsNamed('custom_notetypes/$notetype.hx'); #end
		}
		for (event in eventsPushed) {
			#if LUA_ALLOWED startLuasNamed('custom_events/$event.lua'); #end
			#if HSCRIPT_ALLOWED startHScriptsNamed('custom_events/$event.hx'); #end
		}
		noteTypes = null; eventsPushed = null;

		if (songName == 'tutorial') {
			canTweenCamZoom = dontZoomCam = true;
			canTweenCamZoomBoyfriend = 1;
			canTweenCamZoomDad = canTweenCamZoomGf = 1.3;
		}
		// SONG SPECIFIC SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/${Paths.CHART_PATH}/$songName/')) for (file in FileSystem.readDirectory(folder)) {
			if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
			if (file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
		}

		if (eventNotes.length > 1) {
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}
		startCallback();
		recalculateRating();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		if (ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsounds/${Std.string(ClientPrefs.data.hitsoundTypes).toLowerCase()}');
		if (!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
		else if (Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none') Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));
		resetRPC();
	
		stagesFunc((stage:BaseStage) -> stage.createPost());
		callOnScripts('onCreatePost');

		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = .000001; //cant make it invisible or it won't allow precaching

		super.create();
		Paths.clearUnusedMemory();

		cacheCountdown();
		cachePopUpScore();
		GameOverSubstate.cache();

		if (eventNotes.length < 1) checkEventNote();

		if (ClientPrefs.data.disableGC) {
			MemoryUtil.enable();
			MemoryUtil.collect(true);
			MemoryUtil.enable(false);
		}
	}

	function set_songSpeed(value:Float):Float {
		if (generatedMusic) {
			final ratio:Float = value / songSpeed; //funny word huh
			if (ratio != 1) for (note in notes.members) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, noteKillTime / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float {
		#if FLX_PITCH
		if (generatedMusic) {
			FlxG.sound.music.pitch = vocals.pitch = value;

			final ratio:Float = playbackRate / value; //funny word huh
			if (ratio != 1) for (note in notes.members) note.resizeByRatio(ratio);
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		#if VIDEOS_ALLOWED if (videoCutscene != null && videoCutscene.videoSprite != null) videoCutscene.videoSprite.bitmap.rate = value; #end
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
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
		Sys.println(text);
	}

	public function reloadHealthBarColors() {
		healthBar.setColors(CoolUtil.getColor(dad.healthColorArray), CoolUtil.getColor(boyfriend.healthColorArray));
		timeBar.setColors(CoolUtil.getColor(dad.healthColorArray), FlxColor.GRAY);
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch (type) {
			case 0:
				if (!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = .00001;
					startCharacterScripts(newBoyfriend.curCharacter);
					HealthIcon.returnGraphic(newBoyfriend.healthIcon);
				}

			case 1:
				if (!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = .00001;
					startCharacterScripts(newDad.curCharacter);
					HealthIcon.returnGraphic(newDad.healthIcon);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(.95, .95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = .00001;
					startCharacterScripts(newGf.curCharacter);
					HealthIcon.returnGraphic(newGf.healthIcon);
				}
		}
	}

	function startCharacterScripts(name:String) {
		#if LUA_ALLOWED // Lua
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if (FileSystem.exists(replacePath)) {
			luaFile = replacePath;
			doPush = true;
		} else {
			luaFile = Paths.getSharedPath(luaFile);
			if (FileSystem.exists(luaFile)) doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if (lime.utils.Assets.exists(luaFile)) doPush = true;
		#end

		if (doPush) {
			for (script in luaArray) if (script.scriptName == luaFile) {
				doPush = false;
				break;
			}
			if (doPush) new FunkinLua(luaFile);
		}
		#end

		#if HSCRIPT_ALLOWED // HScript
		var doPush:Bool = false;
		var scriptFile:String = 'characters/$name.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(replacePath)) {
			scriptFile = replacePath;
			doPush = true;
		} else
		#end 
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if (FileSystem.exists(scriptFile)) doPush = true;
		}
		
		if (doPush) {
			if (AlterHscript.instances.exists(scriptFile)) doPush = false;
			if (doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String):Dynamic return variables.get(tag);

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(.95, .95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, autoAdjust:Bool = true, playOnLoad:Bool = true):VideoSprite {
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		if (#if sys FileSystem #else OpenFlAssets #end.exists(fileName)) foundFile = true;

		if (foundFile) {
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop, autoAdjust);
			if (forMidSong) videoCutscene.videoSprite.bitmap.rate = playbackRate;
			if (!forMidSong) {
				function onVideoEnd():Void {
					if (!isDead && generatedMusic && SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos) {
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true; inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
			else add(videoCutscene);
			if (playOnLoad) videoCutscene.play();
			return videoCutscene;
		} else #if (LUA_ALLOWED || HSCRIPT_ALLOWED) addTextToDebug('Video not found: $fileName', FlxColor.RED) #else FlxG.log.error('Video not found: $fileName') #end;
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	public function startAndEnd() {
		if (endingSong) endSong();
		else startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String):Void {
		if (psychDialogue != null) return;

		if (dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			psychDialogue.finishThing = () -> {
				psychDialogue = null;
				startAndEnd();
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
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
		for (asset in getCountdownSpriteNames(stageUI)) Paths.image(asset);
		for (sound in introSoundNames) Paths.sound("countdown/" + sound + introSoundsSuffix, true, false); // this should cover backwards compat
	}

	function getCountdownSpriteNames(?givenUI:Null<String>):Array<String> {
		givenUI ??= stageUI;
		return switch (givenUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["countdown/ready", "countdown/set" ,"countdown/go"];
			default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
		};
	}

	public function startCountdown():Bool {
		if (startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if (ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0); generateStaticArrows(1);
			for (i in 0...playerStrums.length) {setOnScripts('defaultPlayerStrumX$i', playerStrums.members[i].x); setOnScripts('defaultPlayerStrumY$i', playerStrums.members[i].y);}
			for (i in 0...opponentStrums.length) {setOnScripts('defaultOpponentStrumX$i', opponentStrums.members[i].x); setOnScripts('defaultOpponentStrumY$i', opponentStrums.members[i].y);}
			setOnScripts('mania', SONG.mania);

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			botplaySine = Conductor.songPosition * .18;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			moveCameraSection();
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - noteKillOffset);
				return true;
			} else if (skipCountdown) {
				setSongTime(0);
				return true;
			}

			var introSprites:Array<String> = getCountdownSpriteNames(stageUI);
			var tick:Countdown = THREE;
			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, (tmr:FlxTimer) -> {
				charactersDance(tmr.loopsLeft);
				switch (swagCounter) {
					case 0:
						CoolUtil.playSoundSafe(Paths.sound("countdown/" + introSoundNames[0] + introSoundsSuffix, true, false), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introSprites[0]);
						CoolUtil.playSoundSafe(Paths.sound("countdown/" + introSoundNames[1] + introSoundsSuffix, true, false), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introSprites[1]);
						CoolUtil.playSoundSafe(Paths.sound("countdown/" + introSoundNames[2] + introSoundsSuffix, true, false), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introSprites[2]);
						CoolUtil.playSoundSafe(Paths.sound("countdown/" + introSoundNames[3] + introSoundsSuffix, true, false), 0.6);
						tick = GO;
					case 4: tick = START;
				}

				if (!skipArrowStartTween) notes.forEachAlive((note:Note) -> {
					if (ClientPrefs.data.opponentStrums || note.mustPress) {
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if (middleScroll && !note.mustPress) note.alpha *= .35;
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
		var countdownGraphic = Paths.image(image);
		if (countdownGraphic == null) {
			var dum:FlxSprite = new FlxSprite();
			FlxTimer.wait(Conductor.crochet / 1000, () -> dum.destroy());
			return dum; // return an empty sprite if the image doesn't exist
		}

		final spr:FlxSprite = new FlxSprite(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();
		if (isPixelStage) spr.setGraphicSize(Std.int(spr.width * daPixelZoom));
		spr.gameCenter();
		spr.antialiasing = popupAntialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {alpha: 0}, Conductor.crochet / 1000, {ease: FlxEase.cubeInOut, onComplete: (twn:FlxTween) -> {remove(spr, true); spr.destroy();}});
		return spr;
	}

	public function clearNotesBefore(time:Float) {
		var i:Int = unspawnNotes.length - 1;
		var daNote:Note = unspawnNotes[i];
		while (daNote.strumTime - noteKillOffset < time) {
			daNote.ignoreNote = true;
			daNote.kill(); unspawnNotes.remove(daNote); daNote.destroy();
			daNote = unspawnNotes[--i];
		}

		i = notes.length - 1;
		daNote = notes.members[i];
		while (daNote.strumTime - noteKillOffset < time) {
			daNote.ignoreNote = true;
			invalidateNote(daNote);
			daNote = notes.members[--i];
		}
	}
	public dynamic function updateScore(miss:Bool = false) {
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop) return;
		updateScoreText();
		callOnScripts('onUpdateScore', [miss]);
	}
	public dynamic function updateScoreText() {
		var tempText:String = '${!ClientPrefs.data.showNPS ? '' : Language.getPhrase('nps_text', 'NPS: {1}/{2} | ', [bfNpsVal, bfNpsMax])}' + Language.getPhrase('score_text', 'Score: {1} ', [flixel.util.FlxStringUtil.formatMoney(songScore, false)]);
		if (!cpuControlled) {
			if (!instakillOnMiss) tempText += Language.getPhrase('miss_text', '| Misses: {1} ', [songMisses]); 
			tempText += Language.getPhrase('accuracy_text', '| Accuracy: {1}% |', [ratingAccuracy]) + (totalPlayed != 0 ? ' (${Language.getPhrase(ratingFC)}) ${Language.getPhrase('rating_$ratingName', ratingName)}' : ' ?');
		} else tempText += Language.getPhrase('hits_text', '| Hits: {1}', [combo]);
		scoreTxt.text = tempText;
	}

	public dynamic function fullComboFunction() {
		var fullhits:Array<Int> = [for (judge in judgeData) judge.hits];
		ratingFC = "";
		if (songMisses == 0) {
			if (fullhits[3] > 0 || fullhits[4] > 0) ratingFC = 'FC';
			else if (fullhits[2] > 0) ratingFC = 'GFC';
			else if (fullhits[1] > 0) ratingFC = 'SFC';
			else if (fullhits[0] > 0) ratingFC = "PFC";
		} else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function setSongTime(time:Float) {
		if (!inStarting) {
			FlxG.sound.music.pause(); vocals.pause();

			FlxG.sound.music.time = time - Conductor.offset;
			#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
			FlxG.sound.music.play();

			if (Conductor.songPosition < vocals.length) {
				vocals.time = time - Conductor.offset;
				#if FLX_PITCH vocals.pitch = playbackRate; #end
				vocals.play();
			} else vocals.pause();
		}
		Conductor.songPosition = time;
	}

	public function startNextDialogue() callOnScripts('onNextDialogue', [dialogueCount++]);
	public function skipDialogue() callOnScripts('onSkipDialogue', [dialogueCount]);

	var inStarting:Bool = false;
	function startSong():Void {
		startingSong = false;
		inStarting = true; // prevent play inst double times

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onFinish.add(() -> finishSong());
		vocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if (paused) {FlxG.sound.music.pause(); vocals.pause();}

		stagesFunc((stage:BaseStage) -> stage.startSong());
		songLength = FlxG.sound.music.length; // Song duration in a float, useful for the time left feature
		FlxTween.tween(timeBar, {alpha: 1}, .5 * playbackRate, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, .5 * playbackRate, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED if (autoUpdateRPC) DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', true, songLength / playbackRate); #end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
		inStarting = false;
	}

	var noteTypes:Array<String> = [];
	var eventsPushed:Array<String> = [];
	function generateSong():Void {
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		songSpeed = switch (songSpeedType) {
			case "constant": ClientPrefs.getGameplaySetting('scrollspeed');
			case "multiplicative": SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			default: SONG.speed;
		}

		var songData:SwagSong = SONG;
		Conductor.bpm = songData.bpm;

		vocals = new FlxSound();
		try {if (SONG.needsVoices) vocals.loadEmbedded(Paths.voices(SONG.song));} catch (e:Dynamic) {}
		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		inst = new FlxSound();
		try {inst.loadEmbedded(Paths.inst(songData.song));} catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);

		noteGroup.add(notes = new FlxTypedGroup<Note>());

		try {
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if (eventsChart != null) for (event in eventsChart.events) for (i in 0...event[1].length) makeEvent(event, i); //Event Notes
		} catch (e:Dynamic) {}

		var daBpm:Float = Conductor.bpm;
		var strumTimeVector:Vector<Float> = new Vector<Float>(EK.strums(mania), 0.0);

		var oldNote:Note = null;
		var sectionNoteCnt:Float = 0;
		for (section in PlayState.SONG.notes) {
			sectionNoteCnt = 0;
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm) daBpm = section.bpm;
			for (songNotes in section.sectionNotes) {
				var strumTime:Float = songNotes[0];
				var noteColumn:Int = Std.int(songNotes[1] % EK.keys(mania));
				var holdLength:Float = songNotes[2];
				var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				var gottaHitNote:Bool = (songNotes[1] < EK.keys(mania));

				if (ClientPrefs.data.skipGhostNotes && sectionNoteCnt != 0) {
					if (Math.abs(strumTimeVector[noteColumn] - strumTime) <= ClientPrefs.data.ghostRange) continue;
					else strumTimeVector[noteColumn] = strumTime;
				}

				var swagNote:Note = new Note(strumTime, noteColumn, oldNote);
				swagNote.gfNote = (section.gfSection && (!songData.isOldVersion ? gottaHitNote : !gottaHitNote) == section.mustHitSection);
				swagNote.animSuffix = section.altAnim && !gottaHitNote ? "-alt" : "";
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = holdLength;
				swagNote.noteType = noteType;
				swagNote.scrollFactor.set(); swagNote.updateSkin(SONG.arrowSkin ?? null);
				unspawnNotes.push(swagNote);
				oldNote = swagNote;

				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.;
				var roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
				if (roundSus > 0) {
					for (susNote in 0...roundSus + 1) {
						var sustainNote:Note = new Note(strumTime + (curStepCrochet * susNote), noteColumn, oldNote, true);
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						sustainNote.isSustainEnds = (susNote == roundSus);
						unspawnSustainNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);
						sustainNote.updateSkin(SONG.arrowSkin ?? null);
						sustainNote.correctionOffset = Note.originalHeight / 2;

						if (!isPixelStage) {
							if (oldNote.isSustainNote) {
								oldNote.sustainScale = (Note.SUSTAIN_SIZE / oldNote.frameHeight) / playbackRate;
								if (oldNote.sustainScale != 1) oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
							}
							if (downScroll) sustainNote.correctionOffset = 0;
						} else if (oldNote.isSustainNote) {
							oldNote.sustainScale /= playbackRate;
							if (oldNote.sustainScale != 1) oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}
						oldNote = sustainNote;
					}
				}
				if (!noteTypes.contains(swagNote.noteType)) noteTypes.push(swagNote.noteType);
			}
		}

		for (event in songData.events) for (i in 0...event[1].length) makeEvent(event, i);
		for (usn in unspawnSustainNotes) unspawnNotes.push(usn);
		unspawnSustainNotes.resize(0);
		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if (eventsPushed.contains(event.event)) return;

		stagesFunc(stage -> stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	function eventPushedUnique(event:EventNote) {
		switch (event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend': charType = 2;
					case 'dad' | 'opponent': charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}
				addCharacterToList(event.value2, charType);
			case 'Play Sound': Paths.sound(event.value1);
		}
		stagesFunc((stage:BaseStage) -> stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
		if (returnedValue != null && returnedValue != 0) return returnedValue;

		return switch (event.event) {
			case 'Kill Henchmen': 280;
			default: 0;
		}
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int) {
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 ?? '', subEvent.value2 ?? '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	public function generateStaticArrows(player:Int):Void {
		var strumLine:FlxPoint = FlxPoint.get(middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, downScroll ? (FlxG.height - 150) : 50);
		for (i in 0...EK.keys(mania)) {
			var tempMania:Int = mania;
			if (tempMania == 0) tempMania = 1;
			var targetAlpha:Float = 1;
			if (player < 1) {
				if (!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if (middleScroll) targetAlpha = .35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLine.x, strumLine.y, i, player);
			babyArrow.downScroll = downScroll;
			if (((!isStoryMode || deathCounter > 0) && !skipArrowStartTween) && mania > 1) {
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, (4 / tempMania) * playbackRate, {ease: FlxEase.circOut, startDelay: .5 + ((.8 / tempMania) * i) * playbackRate});
			} else babyArrow.alpha = targetAlpha;

			if (player < 1 && middleScroll) {
				babyArrow.x += 310;
				if (i > EK.midArray[mania]) babyArrow.x += FlxG.width / 2 + 25; //Up and Right
			}

			(player == 1 ? playerStrums : opponentStrums).add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
			callOnLuas('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);
			callOnHScript('onSpawnStrum', [babyArrow]);
		}
		strumLine.put();
	}

	override function openSubState(SubState:FlxSubState) {
		stagesFunc(stage -> stage.openSubState(SubState));
		if (paused && FlxG.sound.music != null) {FlxG.sound.music.pause(); vocals.pause();}
		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState() {
		super.closeSubState();
		stagesFunc(stage -> stage.closeSubState());
		if (paused) {
			if (FlxG.sound.music != null && !startingSong && canResync) resyncVocals();

			FlxTimer.globalManager.forEach((tmr:FlxTimer) -> if (!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach((twn:FlxTween) -> if (!twn.finished) twn.active = true);

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	override public function onFocus():Void {
		callOnScripts('onFocus');
		super.onFocus();
		#if DISCORD_ALLOWED if (!paused && health > 0) resetRPC(Conductor.songPosition > 0.0); #end
		callOnScripts('onFocusPost');
	}

	override public function onFocusLost():Void {
		callOnScripts('onFocusLost');
		super.onFocusLost();
		if (!paused && ClientPrefs.data.autoPausePlayState && !tryPause()) {
			#if DISCORD_ALLOWED if (health > 0 && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")"); #end
		}
		callOnScripts('onFocusLostPost');
	}

	public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false) {
		#if DISCORD_ALLOWED
		if (!autoUpdateRPC) return;
		if (showTime) DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', true, (songLength - Conductor.songPosition - ClientPrefs.data.noteOffset) / playbackRate);
		else DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)');
		#end
	}

	function resyncVocals():Void {
		if (finishTimer != null || (transitioning && endingSong)) return;
		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		if (FlxG.sound.music.time < vocals.length) {
			vocals.time = FlxG.sound.music.time;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
			vocals.play();
		} else vocals.pause();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	var hit:Int = 0;
	var popUpHitNote:Note = null;
	var totalCnt:Int = 0;

	var skipBf:Int = 0;
	var skipCnt:Int = 0;

	var nps:IntMap<Float> = new IntMap<Float>();
	var bfNpsVal:Float = 0;
	var bfNpsMax:Float = 0;
	var bfSideHit:Float = 0;

	override function update(elapsed:Float) {
		if (popUpHitNote != null) popUpHitNote = null;
		hit = skipBf = 0;

		splashMoment.fill(0);
		if (ClientPrefs.data.camMovement && camlock) camFollow.setPosition(camlockpoint.x, camlockpoint.y);

		if (!inCutscene && !paused && !freezeCamera) FlxG.camera.followLerp = .04 * cameraSpeed * playbackRate;
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if (botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (Controls.justPressed('pause')) tryPause();
		if (!endingSong && !inCutscene && allowDebugKeys) {
			if (Controls.justPressed('debug_1')) openChartEditor();
			else if (Controls.justPressed('debug_2')) openCharacterEditor();
		}

		for (icon in [iconP1, iconP2]) icon.bopUpdate(elapsed, playbackRate);

		if (startedCountdown && !paused) {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset) {
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 2.5));
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				if (timeDiff > 1000 * playbackRate) Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (startingSong) {
			if (startedCountdown && Conductor.songPosition >= Conductor.offset) startSong();
			else if (!startedCountdown) Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		} else if (!paused && updateTime) {
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = curTime / songLength;

			var songCalc:Float = songLength - curTime;
			if (timeType == 'Time Elapsed' || timeType == 'Time Position' || timeType == 'Name Elapsed' || timeType == 'Name Time Position') songCalc = curTime;

			var formattedsec:String = StringUtil.formatTime(Math.floor(Math.max(0, (songCalc / playbackRate) / 1000)));
			var formattedtxt:String = '${SONG.song} ${(playbackRate != 1 ? '(${playbackRate}x) ' : '')}';
			var timePos:String = '$formattedsec / ${StringUtil.formatTime(Math.floor((songLength / playbackRate) / 1000))}';
			if (timeType != 'Song Name') timeTxt.text = switch (timeType) {
				case 'Time Left' | 'Time Elapsed': formattedsec;
				case 'Time Position': timePos;
				case 'Name Left' | 'Name Elapsed': '$formattedtxt($formattedsec)';
				case 'Name Time Position' | _: '$formattedtxt($timePos)';
			}
		}

		if (camZooming) {
			var ratio:Float = Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate);
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, ratio);
			camHUD.zoom = FlxMath.lerp(defaultHudCamZoom, camHUD.zoom, ratio);
		}

		#if debug
		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		#end

		if (!ClientPrefs.data.noReset && Controls.justPressed('reset') && canReset && !inCutscene && startedCountdown && !endingSong && !practiceMode) health = 0;
		doDeathCheck();

		if (!ClientPrefs.data.processFirst) {noteSpawn(); noteUpdate();}
		else {noteUpdate(); noteSpawn();}
		skipCnt = skipBf;
		if (skipCnt > 0) combo += skipBf;
		notes.sort(FlxSort.byY, downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (healthBar.bounds != null && health > healthBar.bounds.max) health = healthBar.bounds.max;
		healthLerp = ClientPrefs.data.smoothHealth ? FlxMath.lerp(healthLerp, health, .25) : health;
		updateIconsPosition();

		if (showPopups && popUpHitNote != null) popUpScore(popUpHitNote);
		if (ClientPrefs.data.showNPS) {
			var npsTime:Int = Math.round(Conductor.songPosition);
			if (bfSideHit > 0) nps.set(npsTime, bfSideHit);
			for (key => value in nps) {
				if (key + 1000 > npsTime) {
					if (bfSideHit > 0) {
						bfNpsVal += bfSideHit;
						bfSideHit = 0;
					} else continue;
				} else {
					bfNpsVal -= value;
					nps.remove(key);
				}
			}

			bfNpsMax = Math.max(bfNpsVal, bfNpsMax);
			updateScoreText();
		}

		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function tryPause():Bool {
		if (startedCountdown && canPause) {
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if (ret != LuaUtils.Function_Stop) {
				openPauseMenu();
				return true;
			}
		}
		return false;
	}

	public dynamic function updateIconsPosition() {
		final iconOffset:Int = 26;
		iconP1.x = (iconP1.iconType == 'psych' ? healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset : healthBar.barCenter - iconOffset);
		iconP2.x = (iconP2.iconType == 'psych' ? healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2 : healthBar.barCenter - (iconP2.width - iconOffset));
	}

	public function noteSpawn() {
		var noteSpawnTimout:Float = Timer.stamp();
		if (unspawnNotes.length > totalCnt) {
			var targetNote:Note = unspawnNotes[totalCnt];
			var fixedPosition:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;

			var castHold:Bool = targetNote.isSustainNote;
			var castMust:Bool = targetNote.mustPress;

			var shownTime:Float = castHold ? Math.max(spawnTime / songSpeed, Conductor.stepCrochet) : spawnTime / songSpeed;
			var shownRealTime:Float = shownTime * .001;
			var isDisplay:Bool = targetNote.strumTime - fixedPosition < shownTime;
			while (isDisplay) {
				var canBeHit:Bool = fixedPosition > targetNote.strumTime; // false is before, true is after
				var tooLate:Bool = fixedPosition > targetNote.strumTime + noteKillOffset;
				var noteJudge:Bool = castHold ? tooLate : canBeHit;

				var isCanPass:Bool = !ClientPrefs.data.skipSpawnNote || Timer.stamp() - noteSpawnTimout < shownRealTime;
				if ((!noteJudge || !optimizeSpawnNote) && isCanPass) {
					var dunceNote:Note = targetNote;
					dunceNote.spawned = true;
					dunceNote.strum = (!dunceNote.mustPress ? opponentStrums : playerStrums).members[dunceNote.noteData];
					notes.add(dunceNote);
					
					callOnLuas('onSpawnNote', [totalCnt, dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
					callOnHScript('onSpawnNote', [dunceNote]);
					if (ClientPrefs.data.processFirst && dunceNote.strum != null) {
						dunceNote.followStrumNote(songSpeed);
						if (canBeHit && dunceNote.isSustainNote && dunceNote.strum.sustainReduce) dunceNote.clipToStrumNote();
					}
				} else {
					strumHitId = targetNote.noteData + (castMust ? EK.keys(mania) : 0) & 255;
					if (cpuControlled) {
						if (!castHold && castMust) ++skipBf;
					} else if (castMust) noteMissCommon(targetNote.noteData);
				}
				unspawnNotes[totalCnt] = null; ++totalCnt;
				if (unspawnNotes.length > totalCnt) targetNote = unspawnNotes[totalCnt]; else break;

				castHold = targetNote.isSustainNote;
				castMust = targetNote.mustPress;

				shownTime = castHold ? Math.max(spawnTime / songSpeed, Conductor.stepCrochet) : spawnTime / songSpeed;
				shownRealTime = shownTime * .001;
				isDisplay = targetNote.strumTime - fixedPosition < shownTime;
			}
		}
	}

	public function noteUpdate() {
		if (!generatedMusic) return;
		if (!inCutscene) {
			if (!cpuControlled) keysCheck();
			else playerDance();

			if (notes.length > 0) {
				if (startedCountdown) {
					notes.forEach((daNote:Note) -> {
						if (daNote.exists && daNote.strum != null) {
							var canBeHit:Bool = Conductor.songPosition - daNote.strumTime > 0;
							if (ClientPrefs.data.updateSpawnNote) daNote.strum = (!daNote.mustPress ? opponentStrums : playerStrums).members[daNote.noteData];
							daNote.followStrumNote(songSpeed);
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset) {
								if (daNote.mustPress) {
									if (cpuControlled) goodNoteHit(daNote);
									else if (!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);
								} else {
									if (!daNote.hitByOpponent) opponentNoteHit(daNote);
									if (daNote.ignoreNote && !endingSong) noteMiss(daNote, true);
								}
								invalidateNote(daNote);
								canBeHit = false;
							}
							if (canBeHit) {
								if (daNote.mustPress) {
									if (!daNote.blockHit || daNote.isSustainNote) {
										if (cpuControlled) goodNoteHit(daNote);
										else if (!CoolUtil.toBool(pressHit & 1 << daNote.noteData) && daNote.isSustainNote && !daNote.wasGoodHit && Conductor.songPosition - daNote.strumTime > Conductor.stepCrochet) noteMiss(daNote);
									}
								} else if (!daNote.hitByOpponent && !daNote.ignoreNote || daNote.isSustainNote) opponentNoteHit(daNote);
								if (daNote.isSustainNote && daNote.strum.sustainReduce) daNote.clipToStrumNote();
							}
						} else if (daNote == null) invalidateNote(daNote);
					});
				} else notes.forEachAlive((daNote:Note) -> daNote.canBeHit = daNote.wasGoodHit = false);
			}
		}
		checkEventNote();
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float {
		if (!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null) return health = value;

		health = value; // update health bar
		var newPercent:Null<Float> = FlxMath.remapToRange(healthBar.bounded, healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent ?? 0);

		if (healthBar.percent < 20) {iconP1.setState(1); iconP2.setState(2);}
		else if (healthBar.percent > 80) {iconP1.setState(2); iconP2.setState(1);}
		else {iconP1.setState(0); iconP2.setState(0);}
		return health;
	}

	function openPauseMenu() {
		FlxG.camera.followLerp = 0;
		FlxTimer.globalManager.forEach((tmr:FlxTimer) -> if (!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach((twn:FlxTween) -> if (!twn.finished) twn.active = false);
		persistentUpdate = false; persistentDraw = true;
		paused = true;

		if (FlxG.sound.music != null) {FlxG.sound.music.pause(); vocals.pause();}
		if (!cpuControlled) for (note in playerStrums) if (note.animation.curAnim != null && note.animation.curAnim.name != 'static') {
			note.playAnim('static');
			note.resetAnim = 0;
		}
		openSubState(new PauseSubState());
		#if DISCORD_ALLOWED if (autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)'); #end
	}

	function openChartEditor() {
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false; persistentDraw = true;
		chartingMode = true;
		paused = true;
		FlxG.sound.music?.stop(); vocals?.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, true);
		DiscordClient.resetClientID();
		#end
		FlxG.switchState(() -> new ChartingState());
	}

	function openCharacterEditor() {
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		FlxG.sound.music?.stop();
		vocals?.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		FlxG.switchState(() -> new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false):Bool {
		if (((skipHealthCheck && instakillOnMiss) || health <= (healthBar.bounds != null ? healthBar.bounds.min : 0)) && !practiceMode && !isDead && gameOverTimer == null) {
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if (ret != LuaUtils.Function_Stop) {
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				canResync = canPause = false;
				#if VIDEOS_ALLOWED if (videoCutscene != null) {videoCutscene.destroy(); videoCutscene = null;} #end

				persistentUpdate = persistentDraw = false;
				FlxTimer.globalManager.clear(); FlxTween.globalManager.clear();
				FlxG.camera.filters = [];
				#if VIDEOS_ALLOWED for (vid in VideoSprite._videos) vid.destroy(); VideoSprite._videos = []; #end

				if (GameOverSubstate.deathDelay > 0) {
					gameOverTimer = FlxTimer.wait(GameOverSubstate.deathDelay, () -> {
						vocals.stop(); FlxG.sound.music.stop();
						openSubState(new GameOverSubstate());
						gameOverTimer = null;
					});
				} else {
					vocals.stop(); FlxG.sound.music.stop();
					openSubState(new GameOverSubstate());
				}

				#if DISCORD_ALLOWED if (autoUpdateRPC) DiscordClient.changePresence('Game Over - $detailsText', '${SONG.song} ($storyDifficultyText)'); #end
				return isDead = true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while (eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime) return;

			triggerEvent(eventNotes[0].event, eventNotes[0].value1 ?? '', eventNotes[0].value2 ?? '', leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if (Math.isNaN(flValue1)) flValue1 = null;
		if (Math.isNaN(flValue2)) flValue2 = null;
		strumTime ??= Conductor.songPosition;

		switch (eventName) {
			case 'Hey!':
				var value:Int = switch (value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0': 0;
					case 'gf' | 'girlfriend' | '1': 1;
					default: 2;
				}

				if (flValue2 == null || flValue2 <= 0) flValue2 = .6;

				if (value != 0) {
					if (dad.curCharacter.startsWith('gf')) {
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if (value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if (flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					flValue1 ??= .015;
					flValue2 ??= .03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Set Camera Zoom':
				flValue1 ??= defaultCamZoom;
				flValue2 ??= 1;
				defaultCamZoom = flValue1;
				defaultHudCamZoom = flValue2;

			case 'Play Animation':
				var char:Character = dad;
				switch (value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend': char = boyfriend;
					case 'gf' | 'girlfriend': char = gf;
					default:
						if (flValue2 == null) flValue2 = 0;
						switch (Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null) {
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if (camFollow != null) {
					isCameraOnForcedPos = false;
					if (flValue1 != null || flValue2 != null) {
						isCameraOnForcedPos = true;
						if (flValue1 == null) flValue1 = 0;
						if (flValue2 == null) flValue2 = 0;
						camFollow.setPosition(flValue1, flValue2);
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend': char = gf;
					case 'boyfriend' | 'bf': char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;
						switch (val) {
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
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;

					if (duration > 0 && intensity != 0) targetsArray[i].shake(intensity, duration * playbackRate);
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend': charType = 2;
					case 'dad' | 'opponent': charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType) {
					case 0:
						if (boyfriend.curCharacter != value2) {
							if (!boyfriendMap.exists(value2)) addCharacterToList(value2, charType);

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = .00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2) {
							if (!dadMap.exists(value2)) addCharacterToList(value2, charType);

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = .00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if (wasGf && gf != null) gf.visible = true;
							} else if (gf != null) gf.visible = false;
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if (gf != null) {
							if (gf.curCharacter != value2) {
								if (!gfMap.exists(value2)) addCharacterToList(value2, charType);

								var lastAlpha:Float = gf.alpha;
								gf.alpha = .00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant") {
					if (flValue1 == null) flValue1 = 1;
					if (flValue2 == null) flValue2 = 0;

					final newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if (flValue2 <= 0) {songSpeed = newValue; songSpeedRate = flValue1;}
					else songSpeedTween = FlxTween.tween(this, {songSpeed: newValue, songSpeedRate: flValue1}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete: (twn:FlxTween) -> songSpeedTween = null});
				}

			case 'Set Property':
				try {
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;
	
					var split:Array<String> = value1.split('.');
					if (split.length > 1) LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], trueValue);
					else LuaUtils.setVarInArray(this, value1, trueValue);
				} catch (e:Dynamic) {
					var errorMsg:String = Type.getClassName(Type.getClass(e)) == 'String' ? e : e.message;
					var len:Int = errorMsg.indexOf('\n') + 1;
					if (len <= 0) len = errorMsg.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + errorMsg.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + errorMsg.substr(0, len));
					#end
				}
			case 'Play Sound':
				if (flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'Set Camera Bop': // P-slice event notes
				if (flValue2 == null) flValue2 = 1;
				if (flValue1 == null) flValue1 = 4;
				camZoomingMult = flValue2;
				camZoomingFrequency = flValue1;
		}
		stagesFunc((stage:BaseStage) -> stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	public function moveCameraSection():Void {
		var section:SwagSection = SONG.notes[curSection];
		if (section == null) return;

		if (gf != null && section.gfSection) {
			moveCamera('gf');
			return;
		}

		var camCharacter:String = (!section.mustHitSection ? 'dad' : 'boyfriend');
		bfturn = (camCharacter == 'boyfriend');
		moveCamera(camCharacter);
		if (ClientPrefs.data.camMovement) {
			campoint.set(camFollow.x, camFollow.y);
			camlock = false;
		}
	}

	public var lastCameraTarget(default, null):String = '';
	public function moveCameraScriptCall(char:String):Void {
		if (lastCameraTarget != char) {
			callOnScripts('onMoveCamera', [char]);
			lastCameraTarget = char;
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(moveCameraTo:Dynamic) {
		if (moveCameraTo == 'dad' || moveCameraTo) {
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			if (canTweenCamZoom) tweenCamZoom(canTweenCamZoomDad); moveCameraScriptCall('dad');
		} else if ((moveCameraTo == 'boyfriend' || moveCameraTo == 'bf') || !moveCameraTo) {
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			if (canTweenCamZoom) tweenCamZoom(canTweenCamZoomBoyfriend); moveCameraScriptCall('boyfriend');
		} else {
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			if (canTweenCamZoom) tweenCamZoom(canTweenCamZoomGf); moveCameraScriptCall('gf');
		}
	}

	public function tweenCamZoom(zoom:Float = 1):Void {
		if (cameraTwn == null && FlxG.camera.zoom != zoom) cameraTwn = FlxTween.tween(FlxG.camera, {zoom: zoom}, (Conductor.stepCrochet * 4 / 1000) * playbackRate, {ease: FlxEase.elasticInOut, onComplete: (_) -> cameraTwn = null});
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void {
		updateTime = false;
		FlxG.sound.music.volume = vocals.volume = 0;
		vocals.pause();
		if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) endCallback();
		else finishTimer = FlxTimer.wait(ClientPrefs.data.noteOffset / 1000, () -> endCallback());
	}

	public var transitioning = false;
	public function endSong():Bool {
		timeBar.visible = timeTxt.visible = false;
		canPause = false; endingSong = true;
		camZooming = inCutscene = updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED checkForAchievement([WeekData.getWeekFileName() + '_nomiss', 'ur_bad', 'ur_good', 'toastie']); #end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if (ret != LuaUtils.Function_Stop && !transitioning) {
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent)) percent = 0;
			if (!practiceMode && !cpuControlled) {
				Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent);
				Highscore.saveCombo(Song.loadedSongName, '$ratingFC, $ratingName', storyDifficulty);
			}
			playbackRate = 1;

			if (chartingMode) {openChartEditor(); return false;}
			if (isStoryMode) {
				campaignScore += songScore;
				campaignMisses += songMisses;
				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0) {
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					FlxG.switchState(() -> new StoryMenuState());

					if (!practiceMode && !cpuControlled) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				} else {
					var difficulty:String = Difficulty.getFilePath();
					MusicBeatState.skipNextTransIn = MusicBeatState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(() -> new PlayState(), false, false);
				}
			} else {
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				canResync = false;
				FlxG.switchState(() -> new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while (notes.length > 0) invalidateNote(notes.members[0]);
		unspawnNotes = []; eventNotes = [];
	}

	public var totalPlayed:Float = 0.;
	public var totalNotesHit:Float = 0.;

	public var showPopups:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	var uiFolder:String = "";
	function cachePopUpScore():Void {
		if (stageUI != "normal") uiFolder = uiPrefix + "UI/";
		if (showPopups) {
			for (rating in judgeData) Paths.image(uiFolder + 'judgements/${rating.image}' + uiPostfix);
			for (i in 0...10) Paths.image(uiFolder + 'judgements/number/num$i' + uiPostfix);
		}
	}

	var daRating:Judgement;
	inline function addScore(note:Note = null):Void {
		var noteDiff:Float = getNoteDiff(note) / playbackRate;
		daRating = Judgement.getTiming(noteDiff, cpuControlled);

		totalNotesHit += switch (ClientPrefs.data.accuracyType) {
			case 'Note': 1;
			case 'Millisecond': (daRating.name == 'epic' ? 1 : Judgement.minHitWindow / (noteDiff / playbackRate)); // Much like Kade's "Complex" but less broken
			default: daRating.ratingMod;
		}
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		songScore += daRating.score;

		if (daRating.noteSplash && !note.noteSplashData.disabled) spawnNoteSplashOnNote(note);
		if (!note.ratingDisabled) {
			songHits++; totalPlayed++;
			recalculateRating();
		}
	}

	public var ratingAcc:FlxPoint = FlxPoint.get();
	public var ratingVel:FlxPoint = FlxPoint.get();
	function popUpScore(note:Note = null):Void {
		var daloop:Null<Int> = 0;

		var seperatedScore:Array<Null<Float>> = [];
		var tempCombo:Null<Int> = combo;
		var tempNotes:Null<Int> = tempCombo;

		var comboOffset:Array<Array<Int>> = ClientPrefs.data.comboOffset;
		final placement:Float = FlxG.width * .35;
		if (!ClientPrefs.data.comboStacking && popUpGroup.members.length > 0) {
			for (spr in popUpGroup) {
				spr.kill();
				popUpGroup.remove(spr);
			}
		}

		var ratingPop:Popup = null;
		if (showRating) {
			ratingPop = popUpGroup.recycle(Popup);
			ratingPop.setupPopupData(RATING, uiFolder + 'judgements/${daRating.image}' + uiPostfix);
			ratingPop.gameCenter(Y).y -= 60 + comboOffset[0][1];
			ratingPop.x = placement - 40 + comboOffset[0][0];
			popUpGroup.add(ratingPop);
			ratingPop.doTween();
		}

		if (showComboNum) {
			while (tempCombo >= 10) {
				seperatedScore.unshift(Std.int(tempCombo / 10) % 10);
				tempCombo = Std.int(tempCombo / 10);
			}
			seperatedScore.push(tempNotes % 10);
			for (i in seperatedScore) {
				var numScore:Popup = popUpGroup.recycle(Popup);
				numScore.setupPopupData(NUMBER, uiFolder + 'judgements/number/num$i' + uiPostfix);
				numScore.x = placement + (43 * daloop) - 50 + comboOffset[1][0] - 43 / 2 * (Std.string(tempNotes).length - 1);
				numScore.gameCenter(Y).y += 20 - comboOffset[1][1];
				popUpGroup.add(numScore);
				numScore.doTween();
				++daloop;
			}
		}
		popUpGroup.sort((_:Int, p1:Popup, p2:Popup) -> {
			if (p1 != null && p2 != null) return FlxSort.byValues(FlxSort.ASCENDING, p1.popUpTime, p2.popUpTime);
			else return 0;
		});
		for (i in seperatedScore) i = null;
		daloop = tempCombo = null;
	}

	public static function getNoteDiff(note:Note = null):Float {
		return switch (ClientPrefs.data.noteDiffTypes) {
			case 'Psych': Math.abs(note.hitTime + ClientPrefs.data.ratingOffset);
			case 'Simple' | _: note.hitTime;
		}
	}

	public var strumsBlocked:Array<Bool> = [];
	function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:flixel.input.keyboard.FlxKey = event.keyCode;
		#if debug @:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return; #end
		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(Controls.convertStrumKey(keysArray, eventKey));
	}

	function keyPressed(key:Int) {
		if (cpuControlled || paused || inCutscene || key < 0 || key > playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if (ret == LuaUtils.Function_Stop) return;

		var lastTime:Float = Conductor.songPosition; // more accurate hit time for the ratings?
		if (Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter((n:Note) -> {
			var canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort((a:Note, b:Note) -> Std.int(a.strumTime - b.strumTime));

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note
			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];
				if (doubleNote.noteData == funnyNote.noteData) {
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.) invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime) funnyNote = doubleNote;
				}
			}
			goodNoteHit(funnyNote);
			if (showPopups && popUpHitNote != null) popUpScore(funnyNote);
		} else {
			if (ClientPrefs.data.ghostTapping) callOnScripts('onGhostTap', [key]);
			else noteMissPress(key);
		}
		Conductor.songPosition = lastTime;

		final spr:StrumNote = playerStrums.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm') {
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	function onKeyRelease(event:KeyboardEvent):Void {
		var key:Int = Controls.convertStrumKey(keysArray, event.keyCode);
		if (key > -1) keyReleased(key);
	}

	function keyReleased(key:Int) {
		if (cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if (ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if (spr != null) {
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	function keysCheck():Void {
		var holdArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		pressHit = 0;
		for (index => key in keysArray) {
			holdArray.push(Controls.pressed(key));
			releaseArray.push(Controls.released(key));
			pressHit |= holdArray[index] ? 1 << index : 0;
		}
		if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic) {
			if (notes.length > 0) for (n in notes) { // I can't do a filter here, that's kinda awesome
				if ((n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit) && n.isSustainNote) {
					if (holdArray[n.noteData]) goodNoteHit(n);
				}
			}
			if (!holdArray.contains(true) || endingSong) playerDance();
		}

		if (strumsBlocked.contains(true) && releaseArray.contains(true))
			for (i in 0...releaseArray.length) if (releaseArray[i] || strumsBlocked[i]) keyReleased(i);
	}

	function noteMiss(daNote:Note, opponent:Bool = false):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote.missed) return;
		notes.forEachAlive((note:Note) -> {
			if (daNote != note && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) invalidateNote(note);
		});

		if (!opponent) {
			noteMissCommon(daNote.noteData, daNote);
			stagesFunc((stage:BaseStage) -> stage.noteMiss(daNote));
		}
		var result:Dynamic = callOnLuas('${opponent ? 'opponent' : ''}noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('${opponent ? 'opponent' : ''}noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void { // You pressed a key when there was no notes to press for this key
		if (ClientPrefs.data.ghostTapping) return; // fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, .2));
		stagesFunc((stage:BaseStage) -> stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null) {
		var subtract:Float = pressMissDamage;
		if (note != null) subtract = note.missHealth;

		if (instakillOnMiss) doDeathCheck(true);

		health -= subtract * healthLoss;
		songScore -= 10;
		if (!endingSong) songMisses++;
		totalPlayed++;
		recalculateRating(true);

		var char:Character = boyfriend;
		if ((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if (char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations) {
			var postfix:String = '';
			if (note != null) postfix = note.animSuffix;
			char.playAnim(singAnimations[EK.gfxHud[mania][Std.int(Math.abs(direction))]] + 'miss$postfix', true);
			if (char != gf && combo > 5 && gf != null && gf.hasAnimation('sad')) {
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		combo = 0;
		vocals.volume = 0;
		if (note != null) note.missed = true;
	}

	function opponentNoteHit(note:Note):Void {
		if (note.hitByOpponent) return;
		if (!dontZoomCam) camZooming = true;
		vocals.volume = 1;

		var isSus:Bool = note.isSustainNote;
		var leData:Int = Math.floor(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);
		if (result == LuaUtils.Function_Stop) return;

		var animToPlay:String = singAnimations[EK.gfxHud[mania][leData]];
		if (leType == 'Hey!' && dad.hasAnimation('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = .6;
		} else if (!note.noAnimation) {
			var char:Character = note.gfNote ? gf : dad;
			if (char != null) {
				var canPlay:Bool = !note.isSustainNote || !ClientPrefs.data.holdAnim;
				if (isSus) {
					var holdAnim:String = animToPlay + '-hold';
					if (char.animation.exists(holdAnim)) animToPlay = holdAnim;
					if (char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
				}
				if (canPlay) char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;
			}
		}

		strumPlayAnim(true, leData);
		if (ClientPrefs.data.camMovement && !bfturn) moveCamOnNote(animToPlay);
		note.hitByOpponent = true;

		stagesFunc((stage:BaseStage) -> stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);
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
		if (camTimer.finished) {
			camlock = false;
			camFollow.setPosition(campoint.x, campoint.y);
			camTimer = null;
		} 
	}

	function goodNoteHit(note:Note):Void {
		if (note.wasGoodHit || (cpuControlled && note.ignoreNote)) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.floor(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);
		if (result == LuaUtils.Function_Stop) return;

		note.wasGoodHit = true;
		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		var animToPlay:String = singAnimations[EK.gfxHud[mania][leData]];
		if (ClientPrefs.data.camMovement && bfturn) moveCamOnNote(animToPlay);

		if (!dontZoomCam) camZooming = true;
		if (!note.hitCausesMiss) { //Common notes
			if (!note.noAnimation) {
				var char:Character = boyfriend;
				var animCheck:String = 'hey';
				if (note.gfNote) {
					char = gf;
					animCheck = 'cheer';
				}

				if (char != null) {
					var canPlay:Bool = !note.isSustainNote || !ClientPrefs.data.holdAnim;
					if (isSus) {
						var holdAnim:String = animToPlay + note.animSuffix + '-hold';
						if (char.animation.exists(holdAnim)) animToPlay = holdAnim;
						if (char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}

					if (canPlay) char.playAnim(animToPlay + note.animSuffix, true);
					char.holdTimer = 0;

					if (leType == 'Hey!' && char.hasAnimation(animCheck)) {
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = .6;
					}
				}
			}

			strumPlayAnim(false, leData % EK.keys(mania));
			vocals.volume = 1;

			if (!isSus) {
				++combo; ++bfSideHit;
				if (showPopups) popUpHitNote = note;
				addScore(note);
			}
			health += note.hitHealth * healthGain;
		} else { // Notes that count as a miss if you hit them (Hurt notes for example)
			if (!note.noMissAnimation && leType == 'Hurt Note' && boyfriend.hasAnimation('hurt')) {
				boyfriend.playAnim('hurt', true);
				boyfriend.specialAnim = true;
			}
			noteMiss(note);
		}
		if (ClientPrefs.data.splashAlpha != 0 && !note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
		stagesFunc((stage:BaseStage) -> stage.goodNoteHit(note));

		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if (!isSus) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		if (note == null) return;
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	var noteSplashframes:Int = -1;
	public function spawnNoteSplashOnNote(note:Note) {
		if (!note.mustPress) return;
		var targetSplash:NoteSplash = null;
		var splashNoteData:Int = note.noteData;
		if (splashMoment[splashNoteData] < splashCount) {
			var frameId:Int = noteSplashframes = -1;
			var splashStrum:StrumNote = playerStrums.members[note.noteData];
			if (note.strum != splashStrum) note.strum = splashStrum;
			
			if (splashUsing[splashNoteData].length >= splashCount) {
				for (index => splash in splashUsing[splashNoteData]) {
					if (splash.alive && noteSplashframes < splash.animation.curAnim.curFrame) {
						noteSplashframes = splash.animation.curAnim.curFrame;
						frameId = index;
						targetSplash = splash;
					}
				}
				if (frameId != -1) targetSplash.killLimit(frameId);
			}
			if (splashStrum != null) spawnNoteSplash(splashStrum.x, splashStrum.y, splashNoteData, note);
			++splashMoment[splashNoteData];
		}
	}

	public function spawnNoteSplash(x:Float = 0, y:Float = 0, splashNoteData:Int = -1, note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = note.strum;
		splash.spawnSplashNote(x, y, splashNoteData, note);
		if (splashNoteData >= 0) splashUsing[splashNoteData].push(splash);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if (CustomSubstate.instance != null) {closeSubState(); resetSubState();}

		for (lua in luaArray) {lua.call('onDestroy'); lua.stop();}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		for (script in hscriptArray) if (script != null) {
			if (script.exists('onDestroy')) script.call('onDestroy');
			script.destroy();
		}
		hscriptArray = null;
		stagesFunc((stage:BaseStage) -> stage.destroy());
		#if VIDEOS_ALLOWED if (videoCutscene != null) {videoCutscene.destroy(); videoCutscene = null;} #end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.camera.filters = [];
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		NoteSplash.configs.clear();
		instance = null;
		backend.NoteLoader.dispose(); Paths.popUpFramesMap.clear();

		super.destroy();
	}

	var lastStepHit:Int = -1;
	override function stepHit() {
		super.stepHit();
		if (curStep == lastStepHit) return;

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;
	override function beatHit() {
		if (lastBeatHit >= curBeat) return;
		
		if (ClientPrefs.data.camZooms && camZooming && FlxG.camera.zoom < 1.35 && (curBeat % camZoomingFrequency) == 0) {
			FlxG.camera.zoom += .015 * camZoomingMult;
			camHUD.zoom += .03 * camZoomingMult;
		}

		for (i => icon in [iconP1, iconP2]) {
			icon.bop({
				curBeat: curBeat,
				playbackRate: playbackRate,
				gfSpeed: gfSpeed,
				healthBarPercent: healthBar.bounded
			}, "ClientPrefs", i);
		}

		if (curBeat > 0) charactersDance(curBeat);
		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function charactersDance(beat:Int, force:Bool = false):Void {
		for (char in [gf, boyfriend, dad]) {
			if (char == null) continue;
			var speed:Int = (gf != null && char == gf) ? gfSpeed : 1;
			if ((char.isAnimationNull() || !char.getAnimationName().startsWith('sing')) && !char.stunned && beat % Math.round(speed * char.danceEveryNumBeats) == 0) char.dance(force);
		}
	}
	public function playerDance():Void {
		var anim:String = boyfriend.getAnimationName();
		if (boyfriend.holdTimer > boyfriend.charaCrochet * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss')) boyfriend.dance();
	}

	override function sectionHit() {
		if (SONG.notes[curSection] != null) {
			if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection();

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
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String):Bool {
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad)) luaToLoad = Paths.getSharedPath(luaFile);
		
		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if (OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray) if (script.scriptName == luaToLoad) return false;
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String):Bool {
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if (FileSystem.exists(scriptToLoad)) {
			if (AlterHscript.instances.exists(scriptToLoad)) return false;
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}
	public function initHScript(file:String) {
		var newScript:HScript = null;
		try {
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		} catch (e:hscript.Expr.Error) {
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			AlterHscript.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (AlterHscript.instances.get(file), HScript);
			if (newScript != null) newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		args ??= [];
		exclusions ??= [];
		excludeValues ??= [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(event:String, ?args:Array<Any>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		args ??= [];
		exclusions ??= [];
		excludeValues ??= [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray) {
			if (script.closed) {
				arr.push(script);
				continue;
			}

			if (exclusions.contains(script.scriptName)) continue;

			var ret:Dynamic = script.call(event, args);
			if ((ret == LuaUtils.Function_StopLua || ret == LuaUtils.Function_StopAll) && !excludeValues.contains(ret) && !ignoreStops) {
				returnVal = ret;
				break;
			}
			
			if (ret != null && !excludeValues.contains(ret)) returnVal = ret;
			if (script.closed) arr.push(script);
		}

		if (arr.length > 0) for (script in arr) luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];
		var len:Int = hscriptArray.length;
		if (len < 1) return returnVal;

		for (script in hscriptArray) {
			@:privateAccess
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin)) continue;

			var callValue:AlterCall = script.call(funcToCall, args);
			if (callValue != null) {
				var myValue:Dynamic = callValue.returnValue;
				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) {
					returnVal = myValue;
					break;
				}
				if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
			}
		}
		#end
		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, ?exclusions:Array<String>) {
		if (exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, ?exclusions:Array<String>) {
		#if LUA_ALLOWED
		if (exclusions == null) exclusions = [];
		for (script in luaArray) {
			if (exclusions.contains(script.scriptName)) continue;
			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, ?exclusions:Array<String>) {
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if (exclusions.contains(script.origin)) continue;
			script.interp.setVar(variable, arg);
		}
		#end
	}

	var strumHitId:Int = -1;
	function strumPlayAnim(isDad:Bool, id:Int) {
		if (!ClientPrefs.data.lightStrum) return;
		var strumSpr:StrumNote = null;
		var strumART:Float = 0;
		strumHitId = id + (isDad ? 0 : EK.keys(mania));
		if (!CoolUtil.toBool(hit & 1 << strumHitId)) {
			strumSpr = (isDad ? opponentStrums : playerStrums).members[id];
			if (strumSpr != null) {
				strumSpr.playAnim('confirm', true);
				var strumCurAnim:flixel.animation.FlxAnimation = strumSpr.animation.curAnim;
				strumSpr.resetAnim = (1 / strumCurAnim.frameRate) * strumCurAnim.numFrames;
			}
			hit |= 1 << strumHitId;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public var ratingAccuracy:Float = 0;
	public function recalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if (ret != LuaUtils.Function_Stop) {
			ratingName = '?';
			if (totalPlayed != 0) { // Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				ratingAccuracy = MathUtil.floorDecimal(ratingPercent * 100, 2);
				if (ratingPercent < 1) // Rating Name
					for (i in 0...ratingStuff.length - 1) {
						final daRating = ratingStuff[i];
						if (ratingPercent < cast daRating[1]) {
							ratingName = daRating[0];
							break;
						}
					}
				else ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
			}
			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingAccuracy', ratingAccuracy);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

	#if ACHIEVEMENTS_ALLOWED
	function checkForAchievement(achievesToCheck:Array<String> = null) {
		if (chartingMode) return;

		var usedPractice:Bool = (practiceMode || cpuControlled);
		if (cpuControlled) return;

		for (name in achievesToCheck) {
			if (!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') { // common achievements
				switch (name) {
					case 'ur_bad': unlock = (ratingPercent < .2 && !practiceMode);
					case 'ur_good': unlock = (ratingPercent >= 1 && !usedPractice);
					case 'toastie': unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);
				}
			} else if (isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice) unlock = true; // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			if (unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader {
		if (!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);
	
		#if (!flash && MODS_ALLOWED && sys)
		if (!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName)) {
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String):Bool {
		if (!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name)) {
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/')) {
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if (FileSystem.exists(frag)) {
				frag = File.getContent(frag);
				found = true;
			} else frag = null;

			if (FileSystem.exists(vert)) {
				vert = File.getContent(vert);
				found = true;
			} else vert = null;

			if (found) {
				runtimeShaders.set(name, [frag, vert]);
				return true;
			}
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.YELLOW);
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