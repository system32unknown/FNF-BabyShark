package flixel.custom;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFormat;
import openfl.text.TextField;

class CustomSoundTray extends flixel.system.ui.FlxSoundTray {
	var text:TextField = new TextField();
	var _intendedY:Float;
	public function new() {
        super();
        removeChildren();

		visible = false;
		scaleX = scaleY = _defaultScale;
		
		var tmp:Bitmap = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000));
		screenCenter();
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
		_intendedY = y;
    }

	override function update(MS:Float):Void {
		var elapsed:Float = MS / 1000;
		// Animate sound tray thing
		if (_timer > 0) _timer -= elapsed;
		else if (_intendedY > -height) {
			_intendedY -= elapsed * height * 4;

			if (_intendedY <= -height) {
				visible = false;
				active = false;

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

		y = FlxMath.lerp(_intendedY, y, Math.exp(-elapsed * 24));
	}

    override function show(up:Bool = false):Void {
		if (!silent) {
			var sound = flixel.system.FlxAssets.getSound(up ? volumeUpSound : volumeDownSound);
			if (sound != null) FlxG.sound.load(sound).play();
		}

		_timer = 1;
		_intendedY = 0;
		visible = true;
		active = true;

		var globalVolume:Int = FlxG.sound.muted ? 0 : Math.round(FlxG.sound.logToLinear(FlxG.sound.volume) * 10);
		text.text = FlxG.sound.muted ? 'Muted' : 'Volume:${globalVolume * 10}%';

		for (i in 0..._bars.length) _bars[i].alpha = i < globalVolume ? 1 : .5;
	}
}