package states;

class ErrorState extends MusicBeatState {
	public var acceptCallback:Void->Void;
	public var backCallback:Void->Void;
	public var errorMsg:String;

	public function new(error:String, accept:Void->Void = null, back:Void->Void = null) {
		this.errorMsg = error;
		this.acceptCallback = accept;
		this.backCallback = back;

		super();
	}

	public var errorSine:Float = 0;
	public var errorText:FlxText;
	override function create() {
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.color = FlxColor.GRAY;
		bg.antialiasing = Settings.data.antialiasing;
		add(bg);
		bg.gameCenter();

		errorText = new FlxText(0, 0, FlxG.width - 300, errorMsg, 32);
		errorText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		errorText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		errorText.scrollFactor.set();
		errorText.gameCenter();
		add(errorText);
		super.create();
	}

	override function update(elapsed:Float) {
		errorSine += 180 * elapsed;
		errorText.alpha = 1 - Math.sin((Math.PI * errorSine) / 180);

		if (Controls.justPressed('accept') && acceptCallback != null) acceptCallback();
		else if (Controls.justPressed('back') && backCallback != null) backCallback();

		super.update(elapsed);
	}
}