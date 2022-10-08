package;
 
import flixel.system.FlxBasePreloader;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.Lib;
 
@:bitmap("assets/preload/images/logo.png") class LogoImage extends BitmapData {}
 
class FunkinPreloader extends FlxBasePreloader
{
    public function new(MinDisplayTime:Float = 3, ?AllowedURLs:Array<String>) {
        super(MinDisplayTime, AllowedURLs);
    }
     
    override function create():Void {
        this._width = Lib.current.stage.stageWidth;
        this._height = Lib.current.stage.stageHeight;
         
        var ratio:Float = this._width / 1400; //This allows us to scale assets depending on the size of the screen.
         
        var logo = new Sprite();
        logo.addChild(new Bitmap(new LogoImage(0, 0))); //Sets the graphic of the sprite to a Bitmap object, which uses our embedded BitmapData class.
        logo.scaleX = logo.scaleY = ratio;
        logo.x = (this._width / 2) - (logo.width / 2);
        logo.y = (this._height / 2) - (logo.height / 2);
        addChild(logo);
         
        super.create();
    }
}