package game;

import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;
import states.PlayState;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	var sc:Array<Float> = Note.noteSplashScales;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = 'noteSplashes';
		if((PlayState.SONG.splashSkin != null || PlayState.SONG.splashSkin != '') && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.getPref('globalAntialiasing');
		this.moves = false;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * .95, y - Note.swagWidth);
		setGraphicSize(Std.int(width * sc[PlayState.mania]));
		alpha = ClientPrefs.getPref('splashOpacity');

		if(texture == null || texture.length < 1) {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if(texture != null) loadAnims(texture);
		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		var mania:Int = PlayState.mania;
		if (PlayState.isPixelStage || texture != 'noteSplashes')
			offset.set(14 / Note.scales[mania], 14 / Note.scales[mania]);

		var animNum:Int = FlxG.random.int(1, 2);
		var animIndex:Int = Math.floor(Note.keysShit.get(mania).get('pixelAnimIndex')[note] % (Note.xmlMax + 1));
		animation.play('note$animIndex-$animNum', true);
		if(animation.curAnim != null)
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		animation.finishCallback = name -> {
			kill();
			if (PlayState.instance != null)
				PlayState.instance.grpNoteSplashes.remove(this, true);
			destroy();
		}
	}

	override function destroy() {
		shader = null;
		colorSwap = null;
		super.destroy();
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		for (splash_frame in 1...3) {
			for (gfx in 0...Note.gfxLetter.length) {
				animation.addByPrefix('note$gfx-' + splash_frame, 'note splash ${Note.gfxLetter[gfx]} ' + splash_frame, 24, false);
			}
		}
	}
}