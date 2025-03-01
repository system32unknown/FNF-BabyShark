package flixel.custom;

#if FLX_SOUND_SYSTEM
import flixel.system.FlxAssets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:allow(flixel.system.frontEnds.SoundFrontEnd)
class CustomSoundTray extends flixel.system.ui.FlxSoundTray {
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	public function new() {
        super();
        removeChildren();

		visible = false;
		scaleX = scaleY = _defaultScale;

		_bg = new Bitmap(new BitmapData(_minWidth, 30, true, 0x7F000000));
		screenCenter();
		addChild(_bg);

		_label = new TextField();
		_label.width = _bg.width;
		_label.multiline = true;
		_label.selectable = false;

		var dtf:TextFormat = new TextFormat("VCR OSD Mono", 10, FlxColor.WHITE);
		dtf.align = openfl.text.TextFormatAlign.CENTER;
		_label.defaultTextFormat = dtf;
		addChild(_label);
		_label.text = "Volume: 100%";
		_label.y = 14;

		_bars = [];

		var tmp:Bitmap;
		for (i in 0...10) {
			tmp = new Bitmap(new BitmapData(4, i + 1, false, FlxColor.GREEN));
			addChild(tmp);
			_bars.push(tmp);
		}
		updateSize();

		y = -height;
		visible = false;
		lerpYPos = y;
	}

	/**
	 * This function updates the soundtray object.
	 */
	public override function update(MS:Float):Void {
		var elapsed:Float = MS / 1000;

		// Animate sound tray thing
		if (_timer > 0) {
		    _timer -= elapsed;
		    alphaTarget = 1;
		} else if (lerpYPos > -height) {
		    lerpYPos -= elapsed * height * 4;
		    alphaTarget = 0;

			if (lerpYPos <= -height) {
				visible = active = false;

				#if FLX_SAVE
				// Save sound preferences
				if (FlxG.save.isBound) {
					FlxG.save.data.mute = FlxG.sound.muted;
					FlxG.save.data.volume = FlxG.sound.volume;
					FlxG.save.flush();
				}
				#end
			}
		}

		y = FlxMath.lerp(lerpYPos, y, Math.exp(-elapsed * 24));
		alpha = FlxMath.lerp(alphaTarget, alpha, Math.exp(-elapsed * 30));
	}

	/**
	 * Shows the volume animation for the desired settings
	 * @param   volume    The volume, 1.0 is full volume
	 * @param   sound     The sound to play, if any
	 * @param   duration  How long the tray will show
	 * @param   label     The test label to display
	 */
	public override function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, ?label:String):Void {
		if (sound != null) FlxG.sound.play(FlxG.assets.getSoundAddExt(sound));

		_timer = duration;
		lerpYPos = 0;
		visible = active = true;

		var globalVolume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * 10);
		for (i in 0..._bars.length) _bars[i].alpha = i < globalVolume ? 1 : .5;

		_label.text = FlxG.sound.muted ? 'Muted' : (label ?? 'Volume: ${globalVolume * 10}%');
		updateSize();
	}
}
#end