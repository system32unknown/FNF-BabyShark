package backend;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Lib;
import flixel.system.FlxAssets;

@:bitmap("assets/shared/images/logobumpin.png")
class FunkinLogoImage extends BitmapData {}
@:keep @:bitmap("assets/images/preloader/light.png")
class GraphicLogoLight extends BitmapData {}
@:keep @:bitmap("assets/images/preloader/corners.png")
class GraphicLogoCorners extends BitmapData {}

class FunkinPreloader extends flixel.system.FlxBasePreloader {
    var _logo:Sprite = new Sprite();
	var _logoGlow:Sprite = new Sprite();

    var _text = new TextField();
	var _flxtext = new TextField();
	var _flxlogo = new Sprite(); 
    var _buffer = new Sprite();
    var _bmpBar:Bitmap;

    public function new(MinDisplayTime:Float = 3) super(MinDisplayTime);

    override function create():Void {
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
		_text.x = 2;
		_text.y = _bmpBar.y - 14;
		_text.width = 200;
		_buffer.addChild(_text);

		_flxtext.defaultTextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 14, 0xffffff);
		_flxtext.text = Std.string(FlxG.VERSION);
		_flxtext.embedFonts = true;
		_flxtext.selectable = false;
		_flxtext.width = 200;
		_flxtext.x = _text.x;
		_flxtext.y = _text.y - 338;
		_buffer.addChild(_flxtext);

		FlxAssets.drawLogo(_flxlogo.graphics);
		_flxlogo.scaleX = _flxlogo.scaleY = .2;
		_flxlogo.x = _flxtext.width + 10;
		_flxlogo.y = _flxtext.y;
		_buffer.addChild(_flxlogo);

		_logo = makeSpriteBitmap(new FunkinLogoImage(0, 0), ratio * 2, ratio / 2);
		_buffer.addChild(_logo);
		_logoGlow = makeSpriteBitmap(new FunkinLogoImage(0, 0), ratio * 2, ratio / 2);
		_buffer.addChild(_logoGlow);

		var corners:Bitmap = createBitmap(GraphicLogoCorners, (crns:Bitmap) -> {
			crns.width = _width;
			crns.height = height;
		});
		corners.smoothing = true;
		_buffer.addChild(corners);

		var bitmap = new Bitmap(new BitmapData(_width, _height, false, 0xffffff));
		var i:Int = 0, j:Int = 0;
		while (i < _height) {
			j = 0;
			while (j < _width) bitmap.bitmapData.setPixel(j++, i, 0);
			i += 2;
		}
		bitmap.blendMode = openfl.display.BlendMode.OVERLAY;
		bitmap.alpha = .25;
		_buffer.addChild(bitmap);

        super.create();
    }

	function makeSpriteBitmap(bitmap:BitmapData, scale:Float, x:Float = 0, y:Float = 0) {
		var _sprite:Sprite = new Sprite();
        _sprite.addChild(new Bitmap(bitmap));
        _sprite.scaleX = _sprite.scaleY = scale;
        _sprite.x = (this._width - _sprite.width) / 2 - x;
        _sprite.y = (this._height - _sprite.height) / 2 - y;
        return _sprite;
	}

    override function destroy() {
		if (_buffer != null) removeChild(_buffer);
		for (remove_spr in [_buffer, _bmpBar, _text, _flxtext, _flxlogo, _logo, _logoGlow]) remove_spr = null;
        super.destroy();
    }

	override public function update(percent:Float):Void {
		_bmpBar.scaleX = percent * (_width - 8);
		_text.text = 'BSBF v${lime.app.Application.current.meta.get('version')} - ' + Std.int(percent * 100) + "%";
    }
}