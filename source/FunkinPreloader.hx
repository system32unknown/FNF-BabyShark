package;
 
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Lib;
import flixel.system.FlxAssets;
import flixel.system.FlxBasePreloader;
import flixel.FlxG;

@:bitmap("assets/preload/images/logo.png") // easter egg >:)
class OldFunkinLogoImage extends BitmapData {}

@:bitmap("assets/preload/images/logos/funkinlogo.png") 
class FunkinLogoImage extends BitmapData {}
@:bitmap("assets/preload/images/logos/bslogo.png") 
class BsLogoImage extends BitmapData {}
@:bitmap("assets/preload/images/logos/vdnblogo.png") 
class DaveLogoImage extends BitmapData {}

@:bitmap("assets/preload/images/flixel/light.png")
class GraphicLogoLight extends BitmapData {} 
@:bitmap("assets/preload/images/flixel/corners.png")
class GraphicLogoCorners extends BitmapData {}

class FunkinPreloader extends FlxBasePreloader {
    var _logo:Array<Sprite> = [
		new Sprite(),
		new Sprite(),
		new Sprite()
	];
	var _logoGlow:Array<Sprite> = [
		new Sprite(),
		new Sprite(),
		new Sprite()
	];

    var _text = new TextField();
	var _flxtext = new TextField();
	var _flxlogo = new Sprite(); 
    var _buffer = new Sprite();
    var _bmpBar:Bitmap;

    public function new(MinDisplayTime:Float = 3) {
        super(MinDisplayTime);
    }
     
    override function create():Void {
		final logoList:Array<BitmapData> = [(FlxG.random.int(0, 999) == 1 ? new OldFunkinLogoImage(0, 0) : new FunkinLogoImage(0, 0)), new BsLogoImage(0, 0), new DaveLogoImage(0, 0)];

		_buffer.scaleX = _buffer.scaleY = 2;
		addChild(_buffer);
		this._width = Std.int(Lib.current.stage.stageWidth / _buffer.scaleX);
		this._height = Std.int(Lib.current.stage.stageHeight / _buffer.scaleY);
		_buffer.addChild(new Bitmap(new BitmapData(_width, _height, false, 0x00345e)));
         
        var ratio:Float = this._width / 1400; //This allows us to scale assets depending on the size of the screen.
         
		_bmpBar = new Bitmap(new BitmapData(1, 7, false, 0x5f6aff));
		_bmpBar.x = 4;
		_bmpBar.y = _height - 11;
		_buffer.addChild(_bmpBar);

		_text.defaultTextFormat = new TextFormat("VCR OSD Mono", 12, 0xffffff);
		_text.embedFonts = true;
		_text.selectable = false;
		_text.multiline = false;
		_text.x = 2;
		_text.y = _bmpBar.y - 14;
		_text.width = 200;
		_buffer.addChild(_text);

		_flxtext.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 14, 0xffffff);
		_flxtext.text = Std.string(FlxG.VERSION);
		_flxtext.embedFonts = true;
		_flxtext.selectable = false;
		_flxtext.multiline = false;
		_flxtext.width = 200;
		_flxtext.x = _text.x;
		_flxtext.y = _text.y - 338;
		_buffer.addChild(_flxtext);

		FlxAssets.drawLogo(_flxlogo.graphics);
		_flxlogo.scaleX = _flxlogo.scaleY = .2;
		_flxlogo.x = _flxtext.width + 30;
		_flxlogo.y = _flxtext.y;
		_buffer.addChild(_flxlogo);

		for (_index => _bitmaps in logoList) {
			_logo[_index] = makeSpriteBitmap(_bitmaps, ratio * .65, 180);
			var logox:Float = _logo[_index].x + (_index * 190);
			_logo[_index].x = logox;
			_buffer.addChild(_logo[_index]);

			_logoGlow[_index] = makeSpriteBitmap(_bitmaps, ratio * .65, 180);
			_logoGlow[_index].x = logox;
			_logoGlow[_index].blendMode = BlendMode.SCREEN;
			_buffer.addChild(_logoGlow[_index]);
		}

		var corners = createBitmap(GraphicLogoCorners, function(corners) {
			corners.width = _width;
			corners.height = height;
		});
		corners.smoothing = true;
		_buffer.addChild(corners);

		var bitmap = new Bitmap(new BitmapData(_width, _height, false, 0xffffff));
		var i:Int = 0, j:Int = 0;
		while (i < _height) {
			j = 0;
			while (j < _width)
				bitmap.bitmapData.setPixel(j++, i, 0);
			i += 2;
		}
		bitmap.blendMode = BlendMode.OVERLAY;
		bitmap.alpha = .25;
		_buffer.addChild(bitmap);

        super.create();
    }

	function makeSpriteBitmap(bitmap:BitmapData, scale:Float, x:Float = 0, y:Float = 0) {
		var _sprite = new Sprite();
        _sprite.addChild(new Bitmap(bitmap));
        _sprite.scaleX = _sprite.scaleY = scale;
        _sprite.x = ((this._width / 2) - (_sprite.width / 2)) - x;
        _sprite.y = ((this._height / 2) - (_sprite.height / 2)) - y;
        return _sprite;
	}

    override function destroy() {
		if (_buffer != null)
            removeChild(_buffer);
		
		_buffer = null;
		_bmpBar = null;
		_text = null;
		_flxtext = null;
		_flxlogo = null;
		for (i in 0...3) {
			_logo[i] = null;
			_logoGlow[i] = null;
		}
        super.destroy();
    }

	override public function update(percent:Float):Void {
		_bmpBar.scaleX = percent * (_width - 8);
		_text.text = "BSF 0.1 - " + Std.int(percent * 100) + "%";
    }
}