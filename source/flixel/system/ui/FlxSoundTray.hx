package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 90;

	var _defaultScale:Float = 2;
	var text:TextField = new TextField();
	/**The sound used when decreasing the volume.**/
	final volumeSound:String = 'flixel/sounds/beep';

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

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
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "Volume: 100%";
		text.y = 14;

		var bx:Int = 10;
		var by:Int = 14;
		_bars = new Array();

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
	}

	/**
	 * This function just updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (_timer > 0) {
			_timer -= MS / 1000;
		} else if (y > -height) {
			y -= (MS / 1000) * FlxG.height * 2;

			if (y <= -height) {
				visible = false;
				active = false;

				// Save sound preferences
				FlxG.save.data.mute = FlxG.sound.muted;
				FlxG.save.data.volume = FlxG.sound.volume;
				FlxG.save.flush();
			}
		}
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param slient Whether the volume is increasing.
	 */
	public function show(Silent:Bool = false):Void
	{
		if (!Silent) {
			FlxG.sound.load(volumeSound).play();
		}

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted) {
			globalVolume = 0;
		}

		for (i in 0..._bars.length) {
			_bars[i].alpha = i < globalVolume ? 1 : .5;
		}

		text.text = 'Volume: ' + (FlxG.sound.muted ? 'Muted' : globalVolume * 10 + '%');
	}

	public function screenCenter():Void {
		scaleX = scaleY = _defaultScale;
		x = .5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x;
	}
}
#end