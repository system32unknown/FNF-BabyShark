package ui;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.utils.Assets;

import ui.framerate.*;
import flixel.util.FlxColor;
import utils.ClientPrefs;

class Overlay extends Sprite {
	public static var instance:Overlay;

    public var fpsCounter:FPSCounter;
    public var memoryCounter:MEMCounter;

	public var fontName:String = Assets.getFont("assets/fonts/vcr.ttf").fontName;
 	@:noCompletion @:noPrivateAccess var timeColor = 0;

	public var color(default, set):FlxColor;

	public function new(x:Float = 0, y:Float = 0) {
		super();
		if (instance == null) instance = this;
		else throw "Cannot create another instance.";

		this.x = x;
		this.y = y;

        __addToList(fpsCounter = new FPSCounter());
        __addToList(memoryCounter = new MEMCounter());
	}

    var __lastAddedSprite:DisplayObject = null;
    function __addToList(spr:DisplayObject) {
        spr.x = x;
        spr.y = __lastAddedSprite != null ? (__lastAddedSprite.y + __lastAddedSprite.height) : y;
        __lastAddedSprite = spr;
        addChild(spr);
    }

	override function __enterFrame(dt:Int):Void {
		super.__enterFrame(dt);

		if (ClientPrefs.getPref('RainbowFps')) {
			timeColor = (timeColor % 360) + 1;
			color = FlxColor.fromHSB(timeColor, 1, 1);
		} else color = FlxColor.WHITE;

		if (!ClientPrefs.getPref('showFPS'))
            memoryCounter.memtxt.y = memoryCounter.__init_y - memoryCounter.height;
        else memoryCounter.memtxt.y = 0;

		visible = ClientPrefs.getPref('showFPS');
	}

	function set_color(value) {
		for (text in [fpsCounter])
		fpsCounter.fpsText.textColor = value;
		fpsCounter.fpsNum.textColor = value;
		memoryCounter.memtxt.textColor = value;

		return color = value;
	}
}
