package states;

@:structInit class TitleData {
	public var titlex:Float = 0;
	public var titley:Float = 1500;
	public var titlesize:Float = 1.5;
	public var starty:Float = 50;
	public var gfx:Float = 512;
	public var gfy:Float = 40;
	public var backgroundSprite:String = '';
	public var bpm:Float = 148;
}

class TitleState extends MusicBeatState {
	public static var skippedIntro:Bool = false;
	
	var gf:FlxSprite;
	var foundXml:Bool = false;
	
	var logo:FlxSprite;
	var titleText:FlxSprite;

	var textGroup:FlxTypedGroup<FlxText>;

	final titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	final titleTextAlphas:Array<Float> = [1, .64];

	var randomPhrase:Array<String> = [];
	var titleJson:TitleData;
	var titletimer:Float = 0;

	public static var updateVersion:String;
	var mustUpdate:Bool = false;

	override function create():Void {
		Paths.clearStoredMemory();
		FlxTransitionableState.skipNextTransOut = false;
		FlxG.mouse.visible = false;
		persistentUpdate = persistentDraw = true;
		super.create();

		#if CHECK_FOR_UPDATES checkUpdate(); #end

		final balls:Dynamic = tjson.TJSON.parse(Paths.getTextFromFile('data/titleData.json'));
		titleJson = {
			titlex: balls.titlex,
			titley: balls.titley,
			titlesize: balls.titlesize,
			starty: balls.starty,
			gfx: balls.gfx,
			gfy: balls.gfy,
			backgroundSprite: balls.backgroundSprite,
			bpm: balls.bpm
		}

		Conductor.bpm = titleJson.bpm;

		if (titleJson.backgroundSprite != null && titleJson.backgroundSprite.length > 0 && titleJson.backgroundSprite != "none") {
			final bg:FlxSprite = new FlxSprite(Paths.image(titleJson.backgroundSprite));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.active = false;
			add(bg);
		}

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
			FlxTween.num(0, 1, 2, {type: PINGPONG, ease: FlxEase.quadInOut}, num -> titleTextTimer = num);
		} else {
			newTitle = false;
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.active = false;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		add(textGroup = new FlxTypedGroup<FlxText>());

		randomPhrase = getIntroTextShit();

		if (!skippedIntro) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		} else skipIntro();

		Paths.clearUnusedMemory();
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

					FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
					FlxG.sound.play(Paths.sound('confirmMenu'), .7);
	
					FlxTimer.wait(1.5, () -> {
						FlxTransitionableState.skipNextTransIn = false;
						if (mustUpdate) openSubState(new substates.OutdatedSubState());
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

		FlxTween.tween(logo, {y: titleJson.starty}, 1.4, {ease: FlxEase.expoInOut});

		deleteText();
	}

	#if CHECK_FOR_UPDATES
	function checkUpdate():Void {
		if(ClientPrefs.data.checkForUpdates && !skippedIntro) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/system32unknown/FNF-BabyShark/main/gitVersion.txt");
			http.onData = (data:String) -> {
				updateVersion = data.split('\n')[0].trim();
				final curVersion:String = Main.engineVer.version.trim();
				trace('version online: $updateVersion, your version: $curVersion');
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}
			http.onError = (error:String) -> Logs.trace('error: $error', ERROR);
			http.request();
		}
	}
	#end
}
