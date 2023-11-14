package objects;

import backend.animation.PsychAnimationController;
import shaders.ColorSwap;

class NoteSplash extends FlxSprite {
	public var colorSwap:ColorSwap = null;
	var sc:Array<Float> = EK.splashScales;

	public static var defaultNoteSplash(default, never):String = 'noteSplashes/noteSplashes';

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		animation = new PsychAnimationController(this);

		var skin:String = null;
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		else skin = defaultNoteSplash + getSplashSkinPostfix();

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
		this.moves = false;
		scrollFactor.set();
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hsb:Array<Float> = null) {
		setPosition(x - (Note.swagWidth * .7) * .95, y - (Note.swagWidth * .7));
		aliveTime = 0;
		setGraphicSize(Std.int(width * sc[PlayState.mania]));
		alpha = ClientPrefs.getPref('splashOpacity');

		var texture:String = null;
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		else texture = defaultNoteSplash + getSplashSkinPostfix();

		if(hsb == null) hsb = [0, 0, 0];

		if(texture != null) loadAnims(texture);
		colorSwap.setHSB(hsb[0], hsb[1], hsb[2]);

		if(PlayState.isPixelStage || !ClientPrefs.getPref('antialiasing')) antialiasing = false;

		var mania:Int = PlayState.mania;
		offset.set(-34 * EK.scales[PlayState.mania], -23 * EK.scales[PlayState.mania]);
		if (PlayState.isPixelStage || texture != 'noteSplashes')
			offset.set(14 / EK.scales[mania], 14 / EK.scales[mania]);

		var animNum:Int = FlxG.random.int(1, 2);
		var animIndex:Int = Math.floor(Note.keysShit.get(mania).get('pixelAnimIndex')[note] % (EK.xmlMax + 1));
		animation.play('note$animIndex-$animNum', true);

		if(animation.curAnim != null)
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	override function destroy() {
		shader = null;
		colorSwap = null;
		super.destroy();
	}

	public static function getSplashSkinPostfix() {
		var skin:String = '';
		if(ClientPrefs.getPref('splashSkin') != ClientPrefs.defaultprefs.get('splashSkin'))
			skin = '-' + ClientPrefs.getPref('splashSkin').trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		if(frames == null) {
			skin = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(skin);
			if(frames == null) { //if you really need this, you really fucked something up
				skin = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(skin);
			}
		}
		for (splash_frame in 1...3) {
			for (gfx in 0...Note.gfxLetter.length)
				animation.addByPrefix('note$gfx-' + splash_frame, 'note splash ${Note.gfxLetter[gfx]} ' + splash_frame, 24, false);
		}
	}

	static var aliveTime:Float = 0;
	static var buggedKillTime:Float = .5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float) {
		aliveTime += elapsed;
		if((animation.curAnim != null && animation.curAnim.finished) || (animation.curAnim == null && aliveTime >= buggedKillTime))
			kill();

		super.update(elapsed);
	}
}