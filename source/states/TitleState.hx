package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxFrame;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxGradient;
import tjson.TJSON as Json;
import backend.Highscore;
import states.MainMenuState;
#if sys import sys.FileSystem; #end

typedef TitleData = {
	titlex:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	bpm:Float,
	gradients:Array<String>
}

class TitleState extends MusicBeatState {
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	
	var bg:FlxSprite;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;

	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	public static var titleJSON:TitleData = null;

	var gradientBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF0F5FFF);
	var gradtimer:Float = 0;

	var textGroup:FlxTypedGroup<FlxText>;
	var blackScreen:FlxSprite;

	var startingTween:FlxTween;

	override function create():Void {
		onInit();

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		Mods.loadTopMod();

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

	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	function createIntro() {
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		logoBl = new FlxSprite(0, 1500);
		logoBl.antialiasing = ClientPrefs.getPref('Antialiasing');
		if (!FileSystem.exists(Paths.modsXml('logobumpin'))) {
			logoBl.loadGraphic(Paths.image('logobumpin'));
			logoBl.setGraphicSize(Std.int(logoBl.width * 1.5));
		} else {
			foundXml = true;
			logoBl.frames = Paths.getSparrowAtlas('logobumpin');
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
		}
		logoBl.updateHitbox();
		logoBl.x = titleJSON.titlex;

		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.antialiasing = ClientPrefs.getPref('Antialiasing');
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

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
			Conductor.bpm = titleJSON.bpm;
		}

		add(bg);
		add(gfDance);
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
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt', Paths.getPreloadPath());
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		return [for (i in firstArray) i.split('--')];
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

		gradtimer++;
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
			
			titleText.color = FlxColor.interpolate(FlxColor.fromString(titleJSON.gradients[0]), FlxColor.fromString(titleJSON.gradients[1]), timer);
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
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (pressedEnter && !skippedIntro)
			skipIntro();

		super.update(elapsed);
	}

	function createCoolText(textArray:Dynamic, offset:Float = 0) {
		if (Std.isOfType(textArray, String))
			addMoreText(textArray, offset, 1);
		else {
			for (i in 0...textArray.length)
				addMoreText(textArray[i], offset, i);
		}
	}

	function addMoreText(text:String, offset:Float = 0, i:Int = -1) {
		if (textGroup != null) {
			var coolText:FlxText = new FlxText(0, ((i == -1 ? textGroup.length : i) * 60) + 200 + offset, FlxG.width, text, 48);
			coolText.setFormat(Paths.font("babyshark.ttf"), 48, FlxColor.WHITE, CENTER);
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

		if(gfDance != null) {
			danceLeft = !danceLeft;
			gfDance.animation.play(danceLeft ? 'danceRight' : 'danceLeft');
		}

		if(!closedState) {
			switch (sickBeats++) {
				case 0: createCoolText(['Vs Dave and Bambi by:']);
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
					createCoolText(['Altertoriel']);
				case 9:
					addMoreText('Presents!');
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
			new FlxTimer().start(.01, (tmr:FlxTimer) -> {
				if (logoBl.angle == -4) FlxTween.angle(logoBl, logoBl.angle, 4, 4, {ease: FlxEase.quartInOut});
				if (logoBl.angle == 4) FlxTween.angle(logoBl, logoBl.angle, -4, 4, {ease: FlxEase.quartInOut});
			}, 0);
			skippedIntro = true;
		}
	}

	public static function onInit() {
		Paths.clearStoredCache();
		Paths.clearUnusedCache();

		#if LUA_ALLOWED Mods.pushGlobalMods(); #end

		FlxG.mouse.visible = false;
		ClientPrefs.toggleVolumeKeys(true);
		FlxG.keys.preventDefaultKeys = [TAB];
	}
}
