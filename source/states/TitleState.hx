package states;

import haxe.io.Path;
import haxe.Json;
#if desktop
import utils.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import lime.app.Application;
import openfl.Assets;
import data.WeekData;
import utils.PlayerSettings;
import utils.ClientPrefs;
import game.Highscore;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var gradientBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF0F5FFF);
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	
	var logoBl:FlxSprite;
	var logoBlTwo:FlxSprite;
	var titleLogos:Array<FlxSprite> = [new FlxSprite(100, 1500), new FlxSprite(100, 1500)];
	var titleText:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var gradtimer:Float = 0;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

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

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');

		ClientPrefs.loadPrefs();
		Highscore.load();

		if(!initialized) {
			if(FlxG.save.data != null && FlxG.save.data.fullscreen) {
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null) {
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

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

			if (initialized)
				startIntro();
			else {
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					startIntro();
				});
			}
		}
	}

	function startIntro() {
		if (!initialized) {
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

		Conductor.changeBPM(150);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		titleLogos[0].frames = Paths.getSparrowAtlas('logoBumpin');
		titleLogos[0].animation.addByPrefix('bump', 'logo bumpin', 24, false);
		titleLogos[0].animation.play('bump');

		titleLogos[1].loadGraphic(Paths.image('BSF3D'));
		
		for (logo in titleLogos) {
			logo.antialiasing = ClientPrefs.getPref('globalAntialiasing');
			logo.setGraphicSize(Std.int(logo.width * .7));
			logo.updateHitbox();
			add(logo);
		}

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

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		gradtimer += 1;
		gradientBar.scale.y += Math.sin(gradtimer / 10) * 0.001;
		gradientBar.updateHitbox();
		gradientBar.y = FlxG.height - gradientBar.height;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}
		
		if (newTitle) {
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter) {
				var logoInt:Int = 0;
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.getPref('flashing') ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				MainMenuState.firstStart = true;
				MainMenuState.finishedFunnyMove = false;

				for (logo in titleLogos) {
					logoInt++;
					FlxTween.tween(logo, {x: ((logoInt % 2 == 0) ? 2000: -2000)}, 2.2, {ease: FlxEase.circInOut});
				}

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
		if(textGroup != null && credGroup != null) {
			var coolText:FlxText = new FlxText(0, 0, FlxG.width, text, 48);
			coolText.setFormat(Paths.font('comic.ttf'), 48, FlxColor.WHITE, CENTER);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText() {
		while (textGroup.members.length > 0) {
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();
		
		FlxTween.tween(FlxG.camera, {zoom:1.05}, 0.3, {ease: FlxEase.quadOut, type: BACKWARD});

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					createCoolText(['Vs Dave and Bambi Created by:']);
				case 2:
					addMoreText('MoldyGH, MTM101', -60);
					addMoreText('Rapparep lol, TheBuilderXD', -60);
					addMoreText('T5mpler, Erizur, Billy Bobbo', -60);
					addMoreText('Marcello_TIMEnice30', -60);
				case 3:
					deleteCoolText();
					createCoolText(['Baby Shark\'s Big Show Created by:']);
				case 4:
					addMoreText('Pinkfong and Nickelodeon');
				case 5:
					deleteCoolText();
					createCoolText(['Altertoriel Engine Created by:']);
				case 6:
					addMoreText('Altertoriel');
				case 7:
					deleteCoolText();
					createCoolText(['Psych Engine Created by:']);
				case 8:
					addMoreText('Shadow Mario', 15);
					addMoreText('RiverOaken', 15);
					addMoreText('YoShubs', 15);
				case 9:
					deleteCoolText();
					createCoolText([curWacky[0]]);
				case 10:
					addMoreText(curWacky[1]);
				case 11:
					deleteCoolText();
					createCoolText(['Current Time is..']);	
				case 12:
					addMoreText(Date.now().toString());
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Baby');
				case 15:
					addMoreText('Shark\'s');
				case 16:
					addMoreText('Funkin');
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			var logoInt:Int = 0;
			gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00, 0x553D0468, 0xC4FFE600], 1, 90, true);
	    	gradientBar.y = FlxG.height - gradientBar.height;
	     	gradientBar.scale.y = 0;
	    	gradientBar.updateHitbox();
	    	add(gradientBar);
	     	FlxTween.tween(gradientBar, {'scale.y': 1.3}, 4, {ease: FlxEase.quadInOut});

			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			for (logo in titleLogos) {
				logoInt++;
				FlxTween.tween(logo, {y: ((logoInt % 2 == 0) ? 100: 200)}, 1.4, {ease: FlxEase.expoInOut});
				logo.angle = ((logoInt % 2 == 0) ? -4 : 4);
				new FlxTimer().start(0.01, function(tmr:FlxTimer) {
					if (logo.angle == ((logoInt % 2 == 0) ? -4 : 4))
						FlxTween.angle(logo, logo.angle, ((logoInt % 2 == 0) ? 4 : -4), 4, {ease: FlxEase.quartInOut});
					if (logo.angle == ((logoInt % 2 == 0) ? 4 : -4))
						FlxTween.angle(logo, logo.angle, ((logoInt % 2 == 0) ? -4 : 4), 4, {ease: FlxEase.quartInOut});
				}, 0);
			}
			skippedIntro = true;
		}
	}
}