package states;

class OutdatedState extends MusicBeatState {
	public static var leftState:Bool = false;

    var logo:FlxSprite;
    var foundXml:Bool = false;

	var warnText:FlxText;
	override function create() {
		super.create();

		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK));

		logo = new FlxSprite();
		logo.antialiasing = ClientPrefs.data.antialiasing;
		if(!FileSystem.exists(Paths.modsXml('logobumpin'))) {
			logo.loadGraphic(Paths.image('logobumpin'));
			logo.setGraphicSize(Std.int(logo.width * 1.5));
		} else {
			foundXml = true;
			logo.frames = Paths.getSparrowAtlas('logobumpin');
			logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logo.animation.play('bump');
		}
		logo.updateHitbox();
		logo.alpha = .8;
		logo.angle = -4;
        logo.screenCenter();
		add(logo);

		warnText = new FlxText(0, 0, FlxG.width,
			"Sup bro, looks like you're running an \n
			outdated version of Alter Engine (" + Main.engineVer.version + "),\n
			please update to " + TitleState.updateVersion + "!\n
			Press ESCAPE to proceed anyway.\n
			\nThank you for using the Engine!", 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

        new FlxTimer().start(2, (tmr:FlxTimer) -> {
            if (logo.angle == -10)
                FlxTween.angle(logo, logo.angle, 10, 2, {ease: FlxEase.quartInOut});
            else FlxTween.angle(logo, logo.angle, -10, 2, {ease: FlxEase.quartInOut});
        }, 0);
	}

	override function update(elapsed:Float) {
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad("https://github.com/system32unknown/FNF-BabyShark/releases");
			} else if(controls.BACK) leftState = true;

			if(leftState) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {onComplete: (twn:FlxTween) -> FlxG.switchState(() -> new MainMenuState())});
			}
		}
		super.update(elapsed);
	}

	override function beatHit() {
		super.beatHit();
		if(foundXml) logo.animation.play('bump', true);
	}
}