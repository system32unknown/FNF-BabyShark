package ui;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.text.TextFormat;
import openfl.utils.Assets;

import ui.framerate.*;
import flixel.util.FlxColor;
import utils.ClientPrefs;

class Overlay extends Sprite {
	public static var instance:Overlay;
	public static var textFormat:TextFormat;

    public var fpsCounter:FPSCounter;
    public var memoryCounter:MEMCounter;
	public var fontName:String = Assets.getFont("assets/fonts/vcr.ttf").fontName;
 	@:noCompletion @:noPrivateAccess var timeColor = 0;

	public var color(default, set):FlxColor;
	public var textAlpha(default, set):Float = 0;

	public function new(x:Float = 4, y:Float = 2) {
		super();
		if (instance == null) instance = this;
		else throw "Cannot create another instance.";

		textFormat = new TextFormat(fontName, 12, -1);

		this.x = x;
		this.y = y;

        __addToList(fpsCounter = new FPSCounter());
        __addToList(memoryCounter = new MEMCounter());
	}

    var __lastAddedSprite:DisplayObject = null;
    function __addToList(spr:DisplayObject) {
        spr.x = 0;
        spr.y = __lastAddedSprite != null ? (__lastAddedSprite.y + __lastAddedSprite.height) : 4;
        __lastAddedSprite = spr;
        addChild(spr);
    }

	override function __enterFrame(dt:Int):Void {
		super.__enterFrame(dt);

		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + ClientPrefs.getPref('RainbowSpeed');
			color = FlxColor.fromHSB(timeColor, 1, 1);
		} else color = FlxColor.WHITE;
	}

	function set_color(value) {
		fpsCounter.fpsText.textColor = value;
		fpsCounter.fpsNum.textColor = value;
		memoryCounter.memtxt.textColor = value;

		return color = value;
	}

	function set_textAlpha(value) {
		fpsCounter.fpsText.alpha = textAlpha;
		fpsCounter.fpsNum.alpha = textAlpha;
		memoryCounter.memtxt.alpha = textAlpha;
		alpha = textAlpha;

		return textAlpha = value;
	}
}
