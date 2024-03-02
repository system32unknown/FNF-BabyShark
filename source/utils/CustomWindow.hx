package utils;

import lime.ui.Window;
import lime.app.Application;

import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.display.Sprite;

class CustomWindow {
    public var window:Window;
    public function new(title:String, width:Int, height:Int, x:Int, y:Int) {
        window = Application.current.createWindow({
			title: title,
			width: width,
			height: height,
			borderless: false,
			alwaysOnTop: false
		});
        window.x = x;
        window.y = y;
    }

    public function addSprite(spr:FlxSprite, x:Float, y:Float):Sprite {
        var openflSprite:Sprite = new Sprite();

		var m:Matrix = new Matrix();
		m.translate(0, 0);

		openflSprite.graphics.beginBitmapFill(spr.pixels, m);
		openflSprite.graphics.drawRect(0, 0, spr.pixels.width, spr.pixels.height);
		openflSprite.graphics.endFill();

        openflSprite.x = x;
        openflSprite.y = y;

        window.stage.addChild(openflSprite);

        return openflSprite;
    }
}