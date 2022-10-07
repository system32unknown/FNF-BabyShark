package ;
 
import flixel.system.FlxBasePreloader;
import openfl.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.Lib;
import flixel.FlxG;
 
@:bitmap("art/preloaderArt.png") class LogoImage extends BitmapData {}
 
class Preloader extends FlxBasePreloader
{
    public function new(MinDisplayTime:Float = 3, ?AllowedURLs:Array<String>) 
    {
        super(MinDisplayTime, AllowedURLs);
    }
     
    var logo:Sprite;
     
    override function create():Void 
    {
        this._width = Lib.current.stage.stageWidth;
        this._height = Lib.current.stage.stageHeight;
         
        var ratio:Float = this._width / 2560; //This allows us to scale assets depending on the size of the screen.
         
        logo = new Sprite();
        logo.addChild(new Bitmap(new LogoImage(0, 0))); //Sets the graphic of the sprite to a Bitmap object, which uses our embedded BitmapData class.
        logo.scaleX = logo.scaleY = ratio;
        logo.x = ((this._width) / 2) - ((logo.width) / 2);
        logo.y = (this._height / 2) - ((logo.height) / 2);
        addChild(logo);
         
        super.create();
    }
     
    override function update(percent:Float):Void  {
        if(percent < 69) {
            logo.scaleX += percent / 1920;
            logo.scaleY += percent / 1920;
            logo.x -= percent * 0.6;
            logo.y -= percent / 2;
        } else {
            logo.scaleX = this._width / 1280;
            logo.scaleY = this._width / 1280;
            logo.x = ((this._width) / 2) - ((logo.width) / 2);
            logo.y = (this._height / 2) - ((logo.height) / 2);
        }
        
        super.update(percent);
    }
}