package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import flixel.system.FlxSplash;
import lime.app.Application;
import haxe.Json;
import data.WeekData;
import utils.ClientPrefs;
import utils.CoolUtil;
import utils.MathUtil;
#if desktop
import utils.Discord.DiscordClient;
#end
import game.Highscore;
import game.Conductor;
import states.MainMenuState;
#if sys
import sys.FileSystem;
#end
typedef TitleData = {
	titlex:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	bgColor:String,
	useOldDance:Bool,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	static var doneFlixelSplash:Bool = false;

	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	
	var titlebg:FlxBackdrop;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	public static var titleJSON:TitleData = null;

	var gradientBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF0F5FFF);
	var gradtimer:Float = 0;

	var startingTween:FlxTween;

	override public function create():Void {
		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		curWacky = FlxG.random.getObject(getIntroTextShit());

		super.create();
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();
		Highscore.load();

		titleJSON = Json.parse(Paths.getTextFromFile('images/DaveDanceTitle.json'));

		if (!initialized) {
			if(FlxG.save.data != null && FlxG.save.data.fullscreen) {
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null) {
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		#if FLX_NO_DEBUG
		if (!initialized && ClientPrefs.getPref('FlxStartup') && !doneFlixelSplash) {
			doneFlixelSplash = true;
			FlxSplash.nextState = TitleState;
			FlxG.switchState(new FlxSplash());
			return;
		}
		#end

		FlxG.mouse.visible = false;
		if (ClientPrefs.getPref('flashing') == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized) {
				DiscordClient.initialize();
				Application.current.onExit.add(function(exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			if (initialized) startIntro();
			else {
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					startIntro();
				});
			}
		}
	}

	var daveDance:FlxSprite;
	var danceLeft:Bool = false;
	var foundXml:Bool = false;
	function startIntro() {
		if (!initialized) {
			if (FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		titlebg = new FlxBackdrop(Paths.image('thechecker'));
		titlebg.velocity.set(0, 110);
		titlebg.updateHitbox();
		titlebg.alpha = .5;
		titlebg.color = FlxColor.fromString('#${titleJSON.bgColor}');
		titlebg.screenCenter(X);
		add(titlebg);

		daveDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		daveDance.frames = Paths.getSparrowAtlas('DaveDanceTitle');
		if (titleJSON.useOldDance) {
			daveDance.animation.addByIndices('danceTitle', 'danceTitle', CoolUtil.numberArray(12), "", 24, false);
		} else {
			daveDance.animation.addByIndices('danceLeft', 'danceTitle', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			daveDance.animation.addByIndices('danceRight', 'danceTitle', CoolUtil.numberArray(30, 15), "", 24, false);
		}
		daveDance.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		add(daveDance);

		logoBl = new FlxSprite(0, 1500);
		logoBl.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		if (!FileSystem.exists(Paths.modsXml('FinalLogo'))) {
			logoBl.loadGraphic(Paths.image('FinalLogo'));
			logoBl.setGraphicSize(Std.int(logoBl.width * 1.5));
		} else {
			foundXml = true;
			logoBl.frames = Paths.getSparrowAtlas('FinalLogo');
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
		}
		logoBl.x = titleJSON.titlex;
		logoBl.updateHitbox();
		add(logoBl);

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
		
		titleText.antialiasing = ClientPrefs.getPref('globalAntialiasing');
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.getPref('globalAntialiasing');

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		var blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		if (initialized) skipIntro();
		else initialized = true;
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
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		gradtimer += 1;
		gradientBar.scale.y += Math.sin(gradtimer / 10) * 0.001;
		gradientBar.updateHitbox();
		gradientBar.y = FlxG.height - gradientBar.height;

		pressedEnter = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		
		if (newTitle) {
			titleTimer += MathUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro) {
			if (newTitle && !pressedEnter) {
				var timer:Float = titleTimer;
				if (timer >= 1) timer = -timer + 2;
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if (pressedEnter) {
				if (startingTween != null) {
					startingTween.cancel();
					startingTween = null;
					FlxTween.tween(logoBl, {y: -700}, 1, {ease: FlxEase.backIn});
				}

				if(titleText != null) {
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
					titleText.animation.play('press');
				}

				FlxG.camera.flash(ClientPrefs.getPref('flashing') ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				MainMenuState.firstStart = true;
				MainMenuState.finishedFunnyMove = false;

				new FlxTimer().start(1, function(tmr:FlxTimer) {
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro) {
			skipIntro();
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0) {
		for (i in 0...textArray.length) {
			var money:FlxText = new FlxText(0, 0, FlxG.width, textArray[i], 48);
			money.setFormat(Paths.font('comic.ttf'), 48, FlxColor.WHITE, CENTER);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0) {
		if (textGroup != null && credGroup != null) {
			var coolText:FlxText = new FlxText(0, 0, FlxG.width, text, 48);
			coolText.setFormat(Paths.font('comic.ttf'), 48, FlxColor.WHITE, CENTER);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText() {
		if (textGroup != null) {
			while (textGroup.members.length > 0) {
				if (credGroup != null) credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();
		
		if(logoBl != null && foundXml)
			logoBl.animation.play('bump', true);

		if(daveDance != null) {
			if (titleJSON.useOldDance) {
				daveDance.animation.play('danceTitle');
			} else {
				danceLeft = !danceLeft;
				if (danceLeft) daveDance.animation.play('danceRight');
				else daveDance.animation.play('danceLeft');
			}
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats) {
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					createCoolText(['Vs Dave and Bambi Created by:']);
				case 2:
					addMoreText('MoldyGH, MTM101, Stats45');
					addMoreText('Rapparep lol, TheBuilderXD, Edival');
					addMoreText('T5mpler, Erizur, Billy Bobbo');
				case 3:
					deleteCoolText();
					createCoolText(['Baby Shark\'s Big Show Created by:']);
				case 4:
					addMoreText('Pinkfong');
					addMoreText('Nickelodeon');
					addMoreText('SmartStudy');
				case 5:
					deleteCoolText();
					createCoolText(['Extra Keys Created by:']);
				case 6:
					addMoreText('tposejank');
					addMoreText('srPerez');
					addMoreText('Leather128');
				case 7:
					deleteCoolText();
					createCoolText(['Psych Engine Created by:']);
				case 8:
					addMoreText('Shadow Mario');
					addMoreText('RiverOaken');
					addMoreText('YoShubs');
					addMoreText('And Psych Engine Contributors!');
				case 9:
					deleteCoolText();
					createCoolText(['Bambisona and Babysharksona by']);
				case 10:
					addMoreText('Everyone');
				case 11:
					deleteCoolText();
					createCoolText([curWacky[0]]);
				case 12: addMoreText(curWacky[1]);
				case 13: deleteCoolText();
				case 14: addMoreText('Baby');
				case 15: addMoreText('Shark\'s');
				case 16:
					addMoreText('Funkin');
					addMoreText('The Full Game');
				case 17: 
					deleteCoolText();
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	function skipIntro():Void {
		if (!skippedIntro) {
			gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00, 0x553D0468, 0xC4FFE600], 1, 90, true);
	    	gradientBar.y = FlxG.height - gradientBar.height;
	     	gradientBar.scale.y = 0;
	    	gradientBar.updateHitbox();
	    	add(gradientBar);
			startingTween = FlxTween.tween(gradientBar, {'scale.y': 1.3}, 4, {ease: FlxEase.quadInOut});

			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);

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
}
