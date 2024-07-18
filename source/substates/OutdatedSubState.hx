package substates;

class OutdatedSubState extends MusicBeatSubstate {
	public static var leftState:Bool = false;

	override function create() {
		super.create();

		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0x75000000);
		bg.scrollFactor.set();
		add(bg);

		var warnText:FlxText = new FlxText(0, 0, FlxG.width,
			"Sup bro, looks like you're running an\n
			outdated version of Alter Engine (" + Main.engineVer.version + "),\n
			please update to " + states.TitleState.updateVersion + "!\n
			Press ESCAPE to proceed anyway.\n
			\nThank you for using the Engine!", 32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float) {
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad("https://github.com/system32unknown/FNF-BabyShark/releases");
			} else if(controls.BACK) leftState = true;

			if(leftState) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new states.MainMenuState());
			}
		}
		super.update(elapsed);
	}
}