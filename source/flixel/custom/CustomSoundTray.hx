package flixel.custom;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFormat;
import openfl.text.TextField;

class CustomSoundTray extends flixel.system.ui.FlxSoundTray {
	var text:TextField = new TextField();

	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;
	public function new() {
        super();
        removeChildren();

		visible = false;
		scaleX = scaleY = _defaultScale;
		
		var tmp:Bitmap = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000));
		gameCenter();
		addChild(tmp);

		text.width = tmp.width;
		text.height = tmp.height;
		text.wordWrap = text.multiline = true;
		text.selectable = false;

		var dtf:TextFormat = new TextFormat("VCR OSD Mono", 10, FlxColor.WHITE);
		dtf.align = openfl.text.TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "Volume: 100%";
		text.y = 14;

		var bx:Int = 10;
		var by:Int = 14;
		_bars = [];

		for (i in 0...10) {
			tmp = new Bitmap(new BitmapData(4, i + 1, false, FlxColor.GREEN));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}

		y = -height;
		visible = false;
		lerpYPos = y;
    }

	override function update(MS:Float):Void {
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
	
				// Save sound preferences
				#if FLX_SAVE
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
     * Makes the little volume tray slide out.
     *
     * @param	up Whether the volume is increasing.
     */
    override function show(up:Bool = false):Void {
		_timer = 1;
		lerpYPos = 0;
		visible = active = true;

		if (!silent) {
			var sound:openfl.media.Sound = flixel.system.FlxAssets.getSoundAddExtension(up ? volumeUpSound : volumeDownSound);
			if (sound != null) FlxG.sound.load(sound).play();
		}

		var globalVolume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.volume * 10);
		text.text = FlxG.sound.muted ? 'Muted' : 'Volume:${globalVolume * 10}%';

		for (i in 0..._bars.length) _bars[i].alpha = i < globalVolume ? 1 : .5;
	}
}