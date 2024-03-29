package states;

import flixel.addons.transition.FlxTransitionableState;
import states.MainMenuState;
import flixel.group.FlxGroup;

@:structInit class TitleData {
	public var titlex:Float = 0;
	public var titley:Float = 1500;
	public var titlesize:Float = 1.5;
	public var starty:Float = 50;
	public var gfx:Float = 512;
	public var gfy:Float = 40;
	public var backgroundSprite:String = '';
	public var bpm:Float = 148;
	public var gradients:Array<String> = ["0x553D0468", "0xC4FFE600"];
}

class TitleState extends MusicBeatState {
	public static var skippedIntro:Bool = false;
	
	var gf:FlxSprite;
	var foundXml:Bool = false;
	
	var logo:FlxSprite;
	var titleText:FlxSprite;

	var credGroup:FlxGroup;
	var textGroup:FlxGroup;

	final titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	final titleTextAlphas:Array<Float> = [1, .64];

	var randomPhrase:Array<String> = [];
	var titleJson:TitleData;

	var startingTween:FlxTween;
	var gradientBar:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF0F5FFF);
	var gradtimer:Float = 0;

	override function create():Void {
		Paths.clearStoredCache();
		FlxTransitionableState.skipNextTransOut = false;
		FlxG.mouse.visible = false;
		persistentUpdate = true;

		super.create();

		final balls:Dynamic = tjson.TJSON.parse(Paths.getTextFromFile('data/titleData.json'));
		titleJson = {
			titlex: balls.titlex,
			titley: balls.titley,
			titlesize: balls.titlesize,
			starty: balls.starty,
			gfx: balls.gfx,
			gfy: balls.gfy,
			backgroundSprite: balls.backgroundSprite,
			bpm: balls.bpm,
			gradients: balls.gradients
		}

		if (FreeplayState.vocals == null) {
			Conductor.usePlayState = false;
			Conductor.mapBPMChanges(true);
			Conductor.bpm = titleJson.bpm;
		}

		if (titleJson.backgroundSprite != null && titleJson.backgroundSprite.length > 0 && titleJson.backgroundSprite != "none") {
			final bg:FlxSprite = new FlxSprite(Paths.image(titleJson.backgroundSprite));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.active = false;
			add(bg);
		}

		gradientBar = flixel.util.FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00, CoolUtil.colorFromString(titleJson.gradients[0]), CoolUtil.colorFromString(titleJson.gradients[1])], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		gradientBar.scale.y = 0;
		gradientBar.updateHitbox();
		gradientBar.visible = false;
		gradientBar.alpha = .75;
		add(gradientBar);

		gf = new FlxSprite(titleJson.gfx, titleJson.gfy);
		gf.antialiasing = ClientPrefs.data.antialiasing;
		gf.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gf.animation.addByIndices('left', 'gfDance', [30].concat([for (i in 0...15) i]), "", 24, false);
		gf.animation.addByIndices('right', 'gfDance', [for (i in 15...30) i], "", 24, false);
		gf.animation.play('right');
		gf.alpha = .0001;
		add(gf);

		logo = new FlxSprite(titleJson.titlex, titleJson.titley);
		logo.antialiasing = ClientPrefs.data.antialiasing;
		if(!FileSystem.exists(Paths.modsXml('logobumpin'))) {
			logo.loadGraphic(Paths.image('logobumpin'));
			logo.setGraphicSize(Std.int(logo.width * titleJson.titlesize));
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
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		} else {
			newTitle = false;
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.active = false;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		add(credGroup = new FlxGroup());
		textGroup = new FlxGroup();

		randomPhrase = getIntroTextShit();

		if (!skippedIntro) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		} else skipIntro();

		Paths.clearUnusedCache();
	}

	function getIntroTextShit():Array<String> {
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		return FlxG.random.getObject([for (i in firstArray) i.split('--')]);
	}

	var newTitle:Bool = false;
	var titleTextTimer:Float = 0;
	var pressedEnter:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		gradientBar.scale.y += Math.sin(gradtimer++ / 10) * .001;
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
	
					if (ClientPrefs.data.flashing) titleText.active = true;
					titleText.animation.play('press');
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
	
					FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
					FlxG.sound.play(Paths.sound('confirmMenu'), .7);
	
					MainMenuState.firstStart = true;
					MainMenuState.finishedFunnyMove = false;
	
					FlxTimer.wait(1.5, () -> {
						FlxTransitionableState.skipNextTransIn = false;
						FlxG.switchState(() -> new MainMenuState());
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

	function createCoolText(textArray:Array<String>, ?offset:Float = 0) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, 0, textArray[i]);
			money.screenCenter(X).y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0) {
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text);
			coolText.screenCenter(X).y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteText() {
		while (textGroup.members.length > 0) {
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit() {
		super.beatHit();
		
		gf.animation.play(curBeat % 2 == 0 ? 'left' : 'right', true);
		if(foundXml) logo.animation.play('bump', true);

		if(!skippedIntro) {
			switch (curBeat) {
				case 2: createCoolText(['Vs Dave and Bambi by:']);
				case 3:
					addMoreText('MoldyGH, MTM101, Stats45');
					addMoreText('Rapparep lol, TheBuilderXD, Edival');
					addMoreText('T5mpler, Erizur, Billy Bobbo');
				case 4:
					deleteText();
					createCoolText(['Baby Shark\'s Big Show by:']);
				case 5:
					addMoreText('Pinkfong');
					addMoreText('Nickelodeon');
					addMoreText('SmartStudy');
				case 6:
					deleteText();
					createCoolText(['Psych Engine by:']);
				case 7:
					addMoreText('Shadow Mario');
					addMoreText('Riveren');
					addMoreText('And Psych Engine Contributors!');
				case 8:
					deleteText();
					createCoolText(['Altertoriel']);
				case 9:
					addMoreText('Presents!');
				case 10:
					deleteText();
					createCoolText([randomPhrase[0]]);
				case 11: addMoreText(randomPhrase[1]);
				case 12: deleteText();
				case 13: addMoreText('Baby');
				case 14: addMoreText('Shark\'s');
				case 15: addMoreText('Big Funkin!');
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

		FlxTween.tween(logo, {y: titleJson.starty}, 1.4, {ease: FlxEase.expoInOut});
		new FlxTimer().start(.01, (tmr:FlxTimer) -> {
			if (logo.angle == -4) FlxTween.angle(logo, logo.angle, 4, 4, {ease: FlxEase.quartInOut});
			if (logo.angle == 4) FlxTween.angle(logo, logo.angle, -4, 4, {ease: FlxEase.quartInOut});
		}, 0);

		deleteText();
	}
}
