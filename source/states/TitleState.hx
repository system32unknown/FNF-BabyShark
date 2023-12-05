package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxFrame;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxGradient;
import haxe.Json;
import backend.Highscore;
import states.MainMenuState;

@:structInit
class TitleData {
	public var titlex:Float = 0;
	public var titley:Float = 1500;
	public var starty:Float = 50;
	public var gfx:Float = 512;
	public var gfy:Float = 40;
	public var bpm:Float = 148;
	public var gradients:Array<String> = ["0x553D0468", "0xC4FFE600"];
}

class TitleState extends MusicBeatState {
	public static var skippedIntro:Bool = false;
	
	var gf:FlxSprite;
	var version:FlxText;
	var foundXml:Bool = false;
	
	var logo:FlxSprite;
	var titleText:FlxSprite;

	final titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	final titleTextAlphas:Array<Float> = [1, .64];

	var randomPhrase:Array<String> = [];
	var titleJson:TitleData;

	var startingTween:FlxTween;
	var gradientBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF0F5FFF);
	var gradtimer:Float = 0;

	var textGroup:FlxTypedGroup<FlxText>;

	override function create():Void {
		Paths.clearStoredCache();
		FlxTransitionableState.skipNextTransOut = false;
		persistentUpdate = true;

		super.create();

		final balls = Json.parse(Paths.getTextFromFile('data/titleData.json'));
		titleJson = {
			titlex: balls.titlex,
			titley: balls.titley,
			starty: balls.starty,
			gfx: balls.gfx,
			gfy: balls.gfy,
			bpm: balls.bpm,
			gradients: balls.gradients
		}

		if (FreeplayState.vocals == null) {
			Conductor.usePlayState = false;
			Conductor.mapBPMChanges(true);
			Conductor.bpm = titleJson.bpm;
		}

		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00, CoolUtil.colorFromString(titleJson.gradients[0]), CoolUtil.colorFromString(titleJson.gradients[1])], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		gradientBar.scale.y = 0;
		gradientBar.updateHitbox();
		gradientBar.visible = false;
		gradientBar.alpha = .75;
		add(gradientBar);

		gf = new FlxSprite(titleJson.gfx, titleJson.gfy);
		gf.antialiasing = ClientPrefs.getPref('Antialiasing');
		gf.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gf.animation.addByIndices('left', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gf.animation.addByIndices('right', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gf.animation.play('right');
		gf.alpha = .0001;
		add(gf);

		logo = new FlxSprite(titleJson.titlex, titleJson.titley);
		logo.antialiasing = ClientPrefs.getPref('Antialiasing');
		if (!FileSystem.exists(Paths.modsXml('logobumpin'))) {
			logo.loadGraphic(Paths.image('logobumpin'));
			logo.setGraphicSize(Std.int(logo.width * 1.5));
		} else {
			foundXml = true;
			logo.frames = Paths.getSparrowAtlas('logobumpin');
			logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logo.animation.play('bump');
		}
		logo.updateHitbox();
		logo.alpha = 0.0001;
		logo.angle = -4;
		add(logo);

		titleText = new FlxSprite(125, 576);
		titleText.visible = false;
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
		titleText.active = false;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		version = new FlxText(0, 0, 0, 'Alter Engine v${Main.engineVer.version} (${Main.engineVer.COMMIT_HASH.trim().substring(0, 7)}) | Baby Shark\'s Funkin\' v${FlxG.stage.application.meta.get('version')}', 16);
		version.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, CENTER);
		version.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		version.scrollFactor.set();
		version.y = FlxG.height - version.height;
		version.screenCenter(X);
		version.visible = false;
		add(version);

		add(textGroup = new FlxTypedGroup<FlxText>());

		randomPhrase = FlxG.random.getObject(getIntroTextShit());

		if (!skippedIntro) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		} else skipIntro();

		Paths.clearUnusedCache();
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

	var newTitle:Bool = false;
	var titleTextTimer:Float = 0;
	var pressedEnter:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		gradtimer++;
		gradientBar.scale.y += Math.sin(gradtimer / 10) * .001;
		gradientBar.updateHitbox();
		gradientBar.y = FlxG.height - gradientBar.height;

		if (controls.ACCEPT) {
			if (skippedIntro) {
				if (!pressedEnter) {
					pressedEnter = true;
					if (startingTween != null) {
						startingTween.cancel();
						startingTween = null;
						FlxTween.tween(logo, {y: -700}, 1, {ease: FlxEase.backIn});
					}
	
					if (ClientPrefs.getPref('flashing')) titleText.active = true;
					titleText.animation.play('press');
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
	
					FlxG.camera.flash(ClientPrefs.getPref('flashing') ? FlxColor.WHITE : 0x4CFFFFFF, 1);
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	
					MainMenuState.firstStart = true;
					MainMenuState.finishedFunnyMove = false;
	
					new FlxTimer().start(1.5, function(tmr:FlxTimer) {
						FlxTransitionableState.skipNextTransIn = false;
						MusicBeatState.switchState(new MainMenuState());
					});
				}
			} else skipIntro();
		}

		if (newTitle && !pressedEnter) {
			titleTextTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTextTimer > 2) titleTextTimer -= 2;

			var timer:Float = titleTextTimer;
			if (timer >= 1) timer = (-timer) + 2;
			timer = FlxEase.quadInOut(timer);
			
			titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
			titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
		}
	}

	function createText(textArray:Array<String>, offset:Float = 0) {
		for (i in 0...textArray.length)
			addMoreText(textArray[i], offset, i);
	}

	function addMoreText(text:String, offset:Float = 0, i:Int = -1) {
		if (textGroup != null) {
			final txt:FlxText = new FlxText(0, ((i == -1 ? textGroup.length : i) * 60) + 200 + offset, FlxG.width, text, 48);
			txt.screenCenter(X);
			txt.setFormat(Paths.font("babyshark.ttf"), 48, FlxColor.WHITE, CENTER);
			textGroup.add(txt);
		}
	}

	inline function deleteText() while (textGroup.members.length > 0) textGroup.remove(textGroup.members[0], true);

	override function beatHit() {
		super.beatHit();
		
		gf.animation.play(curBeat % 2 == 0 ? 'left' : 'right', true);
		if(foundXml) logo.animation.play('bump', true);

		if(!skippedIntro) {
			switch (curBeat) {
				case 2: createText(['Vs Dave and Bambi by:']);
				case 3:
					addMoreText('MoldyGH, MTM101, Stats45');
					addMoreText('Rapparep lol, TheBuilderXD, Edival');
					addMoreText('T5mpler, Erizur, Billy Bobbo');
				case 4:
					deleteText();
					createText(['Baby Shark\'s Big Show by:']);
				case 5:
					addMoreText('Pinkfong');
					addMoreText('Nickelodeon');
					addMoreText('SmartStudy');
				case 6:
					deleteText();
					createText(['Psych Engine by:']);
				case 7:
					addMoreText('Shadow Mario');
					addMoreText('Riveren');
					addMoreText('And Psych Engine Contributors!');
				case 8:
					deleteText();
					createText(['Altertoriel']);
				case 9:
					addMoreText('Presents!');
				case 10:
					deleteText();
					createText([randomPhrase[0]]);
				case 11: addMoreText(randomPhrase[1]);
				case 12: deleteText();
				case 13: addMoreText('Baby');
				case 14: addMoreText('Shark\'s');
				case 15:
					addMoreText('Funkin');
					addMoreText('The Full Game');
				case 16: skipIntro();
			}
		}
	}

	function skipIntro() {
		startingTween = FlxTween.tween(gradientBar, {'scale.y': 1.3}, 4, {ease: FlxEase.quadInOut});

		FlxG.camera.flash(FlxColor.WHITE, 2);
		skippedIntro = true;

		gf.alpha = 1;
		logo.alpha = 1;
		titleText.visible = true;
		gradientBar.visible = true;
		version.visible = true;

		FlxTween.tween(logo, {y: titleJson.starty}, 1.4, {ease: FlxEase.expoInOut});
		new FlxTimer().start(.01, (tmr:FlxTimer) -> {
			if (logo.angle == -4) FlxTween.angle(logo, logo.angle, 4, 4, {ease: FlxEase.quartInOut});
			if (logo.angle == 4) FlxTween.angle(logo, logo.angle, -4, 4, {ease: FlxEase.quartInOut});
		}, 0);

		deleteText();
	}
}
