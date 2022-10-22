package;
 
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Lib;
import flixel.system.FlxBasePreloader;
 
@:bitmap("assets/preload/images/logo.png") 
class LogoImage extends BitmapData {}
@:bitmap("assets/preload/images/flixel/light.png")
class GraphicLogoLight extends BitmapData {} 
@:bitmap("assets/preload/images/flixel/corners.png")
class GraphicLogoCorners extends BitmapData {}

class FunkinPreloader extends FlxBasePreloader {
    var _logo = new Sprite();
	var _logoGlow = new Sprite();
    var _text = new TextField();
    var _buffer = new Sprite();
    var _bmpBar:Bitmap;

    public function new(MinDisplayTime:Float = 3, ?AllowedURLs:Array<String>) {
        super(MinDisplayTime, AllowedURLs);
    }
     
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

		_text = new TextField();
		_text.defaultTextFormat = new TextFormat("VCR OSD Mono", 12, 0xffffff);
		_text.embedFonts = true;
		_text.selectable = false;
		_text.multiline = false;
		_text.x = 2;
		_text.y = _bmpBar.y - 14;
		_text.width = 200;
		_buffer.addChild(_text);

        _logo.addChild(new Bitmap(new LogoImage(0, 0))); //Sets the graphic of the sprite to a Bitmap object, which uses our embedded BitmapData class.
        _logo.scaleX = _logo.scaleY = ratio;
        _logo.x = (this._width / 2) - (_logo.width / 2);
        _logo.y = (this._height / 2) - (_logo.height / 2);
        _buffer.addChild(_logo);

		_logoGlow.blendMode = BlendMode.SCREEN;
		_logoGlow.scaleX = _logoGlow.scaleY = _height / 8 * 0.04;
		_logoGlow.x = (_width - _logoGlow.width) / 2;
		_logoGlow.y = (_height - _logoGlow.height) / 2;
		_buffer.addChild(_logoGlow);

		var corners = createBitmap(GraphicLogoCorners, function(corners) {
			corners.width = _width;
			corners.height = height;
		});
		corners.smoothing = true;
		_buffer.addChild(corners);

		var bitmap = new Bitmap(new BitmapData(_width, _height, false, 0xffffff));
		var i:Int = 0;
		var j:Int = 0;
		while (i < _height){
			j = 0;
			while (j < _width)
				bitmap.bitmapData.setPixel(j++, i, 0);
			i += 2;
		}
		bitmap.blendMode = BlendMode.OVERLAY;
		bitmap.alpha = 0.25;
		_buffer.addChild(bitmap);

        super.create();
    }

    override function destroy() {
		if (_buffer != null)
            removeChild(_buffer);
		_buffer = null;
		_bmpBar = null;
		_text = null;
		_logo = null;
		_logoGlow = null;
        super.destroy();
    }

	override public function update(Percent:Float):Void {
		_bmpBar.scaleX = Percent * (_width - 8);
		_text.text = "BSF 0.0.1 - " + Std.int(Percent * 100) + "%";
    }
}