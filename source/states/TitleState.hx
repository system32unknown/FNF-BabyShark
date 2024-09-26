package states;

import haxe.Http;

typedef TitleData = {
	var titlex:Float;
	var titley:Float;
	var titlesize:Float;
	var titlestarty:Float;
	var startx:Float;
	var starty:Float;
	var gfx:Float;
	var gfy:Float;
	var backgroundSprite:String;
	var bpm:Float;

	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Bool;
}

class TitleState extends MusicBeatState {
	public static var skippedIntro:Bool = false;
	
	var gf:FlxSprite;
	var foundXml:Bool = false;
	
	var logo:FlxSprite;
	var titleText:FlxSprite;

	var textGroup:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();

	final titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	final titleTextAlphas:Array<Float> = [1, .64];

	var randomPhrase:Array<String> = [];
	var titletimer:Float = 0;

	public static var updateVersion:String;
	var mustUpdate:Bool = false;

	override function create():Void {
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();
		FlxTransitionableState.skipNextTransOut = false;
		FlxG.mouse.visible = false;
		persistentUpdate = persistentDraw = true;

		#if CHECK_FOR_UPDATES checkUpdate(); #end
		loadJsonData();
		Conductor.bpm = musicBPM;

		gf = new FlxSprite(gfPosition.x, gfPosition.y);
		gf.antialiasing = ClientPrefs.data.antialiasing;
		gf.frames = Paths.getSparrowAtlas(characterImage);
		if(!useIdle) {
			gf.animation.addByIndices('left', animationName, danceRightFrames, "", 24, false);
			gf.animation.addByIndices('right', animationName, danceLeftFrames, "", 24, false);
			gf.animation.play('right');
		} else {
			gf.animation.addByPrefix('idle', animationName, 24, false);
			gf.animation.play('idle');
		}
		gf.alpha = .0001;
		add(gf);

		logo = new FlxSprite(logoPosition.x, logoPosition.y);
		logo.antialiasing = ClientPrefs.data.antialiasing;
		if(!FileSystem.exists(Paths.modsXml('logobumpin'))) {
			logo.loadGraphic(Paths.image('logobumpin'));
			logo.setGraphicSize(Std.int(logo.width * titleSize));
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

		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.visible = false;
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<flixel.graphics.frames.FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		if (newTitle = animFrames.length > 0) {
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
			FlxTween.num(0, 1, 2, {type: PINGPONG, ease: FlxEase.quadInOut}, num -> titleTextTimer = num);
		} else {
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.active = false;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);
		add(textGroup);

		randomPhrase = getIntroTextShit();

		if (!skippedIntro) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		} else skipIntro();
	}

	// JSON data
	var characterImage:String = 'gfDanceTitle';
	var animationName:String = 'gfDance';

	var titleStartY:Float = 50;
	var titleSize:Float = 1.1;
	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(0, 1500);
	var enterPosition:FlxPoint = FlxPoint.get(125, 576);

	var useIdle:Bool = false;
	var musicBPM:Float = 148;
	var danceLeftFrames:Array<Int> = [for (i in 15...30) i];
	var danceRightFrames:Array<Int> = [30].concat([for (i in 0...15) i]);

	function loadJsonData() {
		if(Paths.fileExists('data/titleData.json')) {
			var titleRaw:String = Paths.getTextFromFile('data/titleData.json');
			if(titleRaw != null && titleRaw.length > 0) {
				try {
					var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);
					gfPosition.set(titleJSON.gfx, titleJSON.gfy);
					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					titleSize = titleJSON.titlesize;
					titleStartY = titleJSON.titlestarty;
					musicBPM = titleJSON.bpm;

					if(titleJSON.animation != null && titleJSON.animation.length > 0) animationName = titleJSON.animation;
					if(titleJSON.dance_left != null && titleJSON.dance_left.length > 0) danceLeftFrames = titleJSON.dance_left;
					if(titleJSON.dance_right != null && titleJSON.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
					useIdle = (titleJSON.idle == true);

					if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0) {
						var bg:FlxSprite = new FlxSprite(Paths.image(titleJSON.backgroundSprite));
						bg.antialiasing = ClientPrefs.data.antialiasing;
						bg.active = false;
						add(bg);
					}
				} catch(e:haxe.Exception) Logs.trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}', WARNING);
			} else Logs.trace('No Title JSON detected, using default values.', WARNING);
		}
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

		titletimer++;
		if (skippedIntro) logo.angle = Math.sin(titletimer / 270) * 5;

		if (controls.ACCEPT) {
			if (skippedIntro) {
				if (!pressedEnter) {
					pressedEnter = true;
					FlxTween.tween(logo, {y: -700}, 1, {ease: FlxEase.backIn});
	
					if (ClientPrefs.data.flashing) titleText.active = true;
					titleText.animation.play('press');
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;

					FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF);
					FlxG.sound.play(Paths.sound('confirmMenu'), .7);
	
					FlxTimer.wait(1.5, () -> {
						FlxTransitionableState.skipNextTransIn = false;
						if (mustUpdate) FlxG.switchState(() -> new OutdatedState());
						else FlxG.switchState(() -> new MainMenuState());
					});
				}
			} else skipIntro();
		}

		if (newTitle && !pressedEnter) {
			titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], titleTextTimer);
			titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], titleTextTimer);
		}
	}

	function createText(textArray:Array<String>, offset:Float = 0) {
		for (i in 0...textArray.length) addMoreText(textArray[i], offset, i);
	}

	function addMoreText(text:String, offset:Float = 0, i:Int = -1) {
		if (textGroup != null) {
			final txt:FlxText = new FlxText(0, ((i == -1 ? textGroup.length : i) * 60) + 200 + offset, FlxG.width, text, 48);
			txt.setFormat(Paths.font("babyshark.ttf"), 48, FlxColor.WHITE, CENTER);
			txt.screenCenter(X);
			textGroup.add(txt);
		}
	}

	inline function deleteText() while (textGroup.members.length > 0) textGroup.remove(textGroup.members[0], true);

	override function beatHit() {
		super.beatHit();
		
		if(!useIdle) {
			gf.animation.play(curBeat % 2 == 0 ? 'left' : 'right', true);
		} else if(curBeat % 2 == 0) gf.animation.play('idle', true);
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
				case 15: addMoreText('Big Funkin!');
				case 16: skipIntro();
			}
		}
	}

	function skipIntro() {
		FlxG.camera.flash(FlxColor.WHITE, 2);
		skippedIntro = true;

		gf.alpha = 1;
		logo.alpha = 1;
		titleText.visible = true;
		FlxTween.tween(logo, {y: titleStartY}, 1.4, {ease: FlxEase.expoInOut});

		deleteText();
	}

	#if CHECK_FOR_UPDATES
	function checkUpdate():Void {
		if(ClientPrefs.data.checkForUpdates && !skippedIntro) {
			trace('checking for update');
			var http:Http = new Http("https://raw.githubusercontent.com/system32unknown/FNF-BabyShark/main/CHANGELOG.md");
			var returnedData:Array<String> = [];

			http.onData = (data:String) -> {
    			var versionEndIndex:Int = data.indexOf(';');
    			returnedData[0] = data.substring(0, versionEndIndex);

    			// Extract the changelog after the version number
    			returnedData[1] = data.substring(versionEndIndex + 1, data.length);
				updateVersion = returnedData[0];
				final curVersion:String = Main.engineVer.version;
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					OutdatedState.curChanges = returnedData[1];
					mustUpdate = true;
				}
			}
			http.onError = (error:String) -> Logs.trace('Checking Update Error: $error', ERROR);
			http.request();
		}
	}
	#end
}
