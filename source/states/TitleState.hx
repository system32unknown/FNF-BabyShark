package states;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxGradient;
import lime.app.Application;
import haxe.Json;
import data.WeekData;
import utils.CoolUtil;
import game.Highscore;
import game.Conductor;
import states.MainMenuState;
import states.OutdatedState;
#if sys
import sys.FileSystem;
#end
typedef TitleData = {
	starty:Float,
	bgColor:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	
	var bg:FlxSprite;
	var titlebg:FlxBackdrop;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	public static var titleJSON:TitleData = null;
	var mustUpdate:Bool = false;

	var gradientBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF0F5FFF);
	var gradtimer:Float = 0;

	var textGroup:FlxTypedGroup<FlxText>;
	var blackScreen:FlxSprite;

	var startingTween:FlxTween;

	override function create():Void {
		Paths.clearUnusedCache();
		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end

		if (!closedState)
			getBuildVer("https://raw.githubusercontent.com/system32unknown/FNF-BabyShark/main/version.txt");

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		Mods.loadTheFirstEnabledMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		super.create();
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();
		Highscore.load();

		titleJSON = Json.parse(Paths.getTextFromFile('data/titleData.json'));

		if(FlxG.save.data != null) {
			if(FlxG.save.data.fullscreen != null) FlxG.fullscreen = FlxG.save.data.fullscreen;
			if (FlxG.save.data.weekCompleted != null) StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		persistentUpdate = persistentDraw = true;

		if (FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			createIntro();
			if (initialized) startIntro();
			else new FlxTimer().start(1, startIntro);
		}
	}

	function createIntro() {
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		titlebg = new FlxBackdrop(Paths.image('thechecker'));
		titlebg.velocity.set(0, 110);
		titlebg.updateHitbox();
		titlebg.color = FlxColor.fromString('0x7F${titleJSON.bgColor}');
		titlebg.screenCenter(X);

		logoBl = new FlxSprite(FlxG.width / 2, 1500);
		logoBl.antialiasing = ClientPrefs.getPref('Antialiasing');
		if (!FileSystem.exists(Paths.modsXml('FinalLogo'))) {
			logoBl.loadGraphic(Paths.image('FinalLogo'));
			logoBl.setGraphicSize(Std.int(logoBl.width * 1.5));
		} else {
			foundXml = true;
			logoBl.frames = Paths.getSparrowAtlas('FinalLogo');
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
		}
		logoBl.updateHitbox();
		logoBl.screenCenter(X);

		titleText = new FlxSprite(125, 576);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.getPref('flashing') ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		} else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.antialiasing = ClientPrefs.getPref('Antialiasing');
		titleText.animation.play('idle');
		titleText.updateHitbox();

		textGroup = new FlxTypedGroup<FlxText>();
		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00, 0x553D0468, 0xC4FFE600], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		gradientBar.scale.y = 0;
		gradientBar.updateHitbox();
	}

	var foundXml:Bool = false;
	function startIntro(?_) {
		Conductor.songPosition = 0;
		super.update(0);

		if (FreeplayState.vocals == null) {
			Conductor.usePlayState = false;
			Conductor.mapBPMChanges(true);
			Conductor.changeBPM(titleJSON.bpm);
		}

		add(bg);
		add(titlebg);
		add(logoBl);
		add(titleText);

		add(blackScreen);
		add(textGroup);

		if (initialized) skipIntro();
		else {
			curWacky = FlxG.random.getObject(getIntroTextShit());
			initialized = true;

			beatHit();
			sickBeats = curBeat + 1;
		}
	}

	function getIntroTextShit():Array<Array<String>> {
		var fullText:String = Paths.getTextFromFile('data/introText.txt');
		return [for (i in fullText.split('\n')) i.split('--')];
	}

	var transitioning:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var pressedEnter:Bool = false;

	override function update(elapsed:Float) {
		if (!initialized) return super.update(elapsed);

		if (!transitioning) {
			if (FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			} 
			Conductor.songPosition = FlxG.sound.music.time;
		} else if (skippedIntro) Conductor.songPosition += elapsed * 1000;

		gradtimer += 1;
		gradientBar.scale.y += Math.sin(gradtimer / 10) * .001;
		gradientBar.updateHitbox();
		gradientBar.y = FlxG.height - gradientBar.height;

		pressedEnter = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		if (skippedIntro && newTitle && titleText.animation.curAnim.name == 'idle') {
			titleTimer += FlxMath.bound(elapsed / 1.5, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;

			var timer:Float = titleTimer;
			if (timer >= 1) timer = -timer + 2;
			timer = FlxEase.quadInOut(timer);
			
			titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
			titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
		}

		if (!transitioning && skippedIntro) {
			if (pressedEnter) {
				if (startingTween != null) {
					startingTween.cancel();
					startingTween = null;
					FlxTween.tween(logoBl, {y: -700}, 1, {ease: FlxEase.backIn});
				}

				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.getPref('flashing') ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				MainMenuState.firstStart = true;
				MainMenuState.finishedFunnyMove = false;

				new FlxTimer().start(1, function(tmr:FlxTimer) {
					if (mustUpdate) MusicBeatState.switchState(new OutdatedState());
					else MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (pressedEnter && !skippedIntro)
			skipIntro();

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, offset:Float = 0) {
		for (i in 0...textArray.length) addMoreText(textArray[i], offset, i);
	}

	function addMoreText(text:String, offset:Float = 0, i:Int = -1) {
		if (textGroup != null) {
			var coolText:FlxText = new FlxText(0, ((i == -1 ? textGroup.length : i) * 60) + 200 + offset, FlxG.width, text, 48);
			coolText.setFormat(Paths.font('comic.ttf'), 48, FlxColor.WHITE, CENTER);
			coolText.screenCenter(X);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText() {
		while (textGroup.members.length > 0)
			textGroup.remove(textGroup.members[0], true);
	}

	var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit() {
		super.beatHit();
		
		if(logoBl != null && foundXml)
			logoBl.animation.play('bump', true);

		if(!closedState) {
			switch (sickBeats++) {
				case 0:
					createCoolText(['Vs Dave and Bambi by:']);
				case 1:
					addMoreText('MoldyGH, MTM101, Stats45');
					addMoreText('Rapparep lol, TheBuilderXD, Edival');
					addMoreText('T5mpler, Erizur, Billy Bobbo');
				case 2:
					deleteCoolText();
					createCoolText(['Baby Shark\'s Big Show by:']);
				case 3:
					addMoreText('Pinkfong');
					addMoreText('Nickelodeon');
					addMoreText('SmartStudy');
				case 4:
					deleteCoolText();
					createCoolText(['Extra Keys by:']);
				case 5:
					addMoreText('tposejank');
					addMoreText('srPerez');
					addMoreText('Leather128');
				case 6:
					deleteCoolText();
					createCoolText(['Psych Engine by:']);
				case 7:
					addMoreText('Shadow Mario');
					addMoreText('Riveren');
					addMoreText('And Psych Engine Contributors!');
				case 8:
					deleteCoolText();
					createCoolText(['Doo Doo Doo,']);
				case 9:
					addMoreText('Almost there!');
				case 10:
					deleteCoolText();
					createCoolText([curWacky[0]]);
				case 11: addMoreText(curWacky[1]);
				case 12: deleteCoolText();
				case 13: addMoreText('Baby');
				case 14: addMoreText('Shark\'s');
				case 15:
					addMoreText('Funkin');
					addMoreText('The Full Game');
				case 16: 
					deleteCoolText();
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	function skipIntro():Void {
		if (!skippedIntro) {
	    	add(gradientBar);
			startingTween = FlxTween.tween(gradientBar, {'scale.y': 1.3}, 4, {ease: FlxEase.quadInOut});

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(textGroup);
			remove(blackScreen);

			FlxTween.tween(logoBl, {y: titleJSON.starty}, 1.4, {ease: FlxEase.expoInOut});
			logoBl.angle = -4;
			new FlxTimer().start(0.01, function(tmr:FlxTimer) {
				if (logoBl.angle == -4)
					FlxTween.angle(logoBl, logoBl.angle, 4, 4, {ease: FlxEase.quartInOut});
				if (logoBl.angle == 4)
					FlxTween.angle(logoBl, logoBl.angle, -4, 4, {ease: FlxEase.quartInOut});
			}, 0);
			skippedIntro = true;
		}
	}

	function getBuildVer(verhttp:String) {
		if (!FunkinInternet.isOnline) return;
		
		var http = new haxe.Http(verhttp);
		var returnedData:Array<String> = [];

		http.onData = function(data:String) {
			returnedData[0] = data.substring(0, data.indexOf(';'));
			returnedData[1] = data.substring(data.indexOf('-'), data.length);

			if (Main.engineVersion.version != returnedData[0].trim()) {
				mustUpdate = true;
				OutdatedState.needVer = returnedData[0];
				OutdatedState.currChanges = returnedData[1];
			}
		}

		http.onError = function(error) {
			trace('error: $error');
		}

		http.request();
	}
}
