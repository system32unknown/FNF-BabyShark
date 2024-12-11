package states;

class OutdatedState extends MusicBeatState {
	public static var leftState:Bool = false;
	public static var curChanges:String = "";

	override function create() {
		super.create();

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"Sup bro, looks like you're running an\n" +
			'outdated version of Alter Engine (${Main.engineVer.version}),\n' +
			'please update to ${TitleState.updateVersion}!'
			+ "\n\nWhat's new:\n\n"
			+ curChanges
			+ "\n& more changes and bugfixes in the full changelog"
			+ "\n\nPress ENTER to view the full changelog and update\nor ESCAPE to ignore this",
			32);
		txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txt.gameCenter(Y);
		add(txt);
	}

	override function update(elapsed:Float) {
		if(leftState) {
			super.update(elapsed);
			return;
		}

		if (Controls.justPressed('accept')) {
			leftState = true;
			CoolUtil.browserLoad("https://github.com/system32unknown/FNF-BabyShark/releases");
		} else if(Controls.justPressed('back')) leftState = true;

		if(leftState) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(() -> new MainMenuState());
		}
		super.update(elapsed);
	}
}