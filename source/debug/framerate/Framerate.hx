package debug.framerate;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;

class Framerate extends openfl.display.Sprite {
	public static var instance:Framerate;

	public static var textFormat:TextFormat;
	public static var fontName:String = "";
	public var fpsCounter:FPSCounter;

	public static var debugMode:Bool = false;
	public static var offset:FlxPoint = new FlxPoint();

	public var bgSprite:Bitmap;

	public var categories:Array<FramerateCategory> = [];

	@:isVar public static var __bitmap(get, null):BitmapData = null;

	static function get___bitmap():BitmapData {
		if (__bitmap == null) __bitmap = new BitmapData(1, 1, 0xFF000000);
		return __bitmap;
	}

	public function new() {
		super();
		if (instance != null) throw "Cannot create another instance";
		instance = this;
		fontName = openfl.utils.Assets.getFont("assets/fonts/Proggy.ttf").fontName;
		textFormat = new TextFormat(fontName, 12, -1);

		x = 0;
		y = 0;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, (e:KeyboardEvent) -> if (e.keyCode == openfl.ui.Keyboard.F3) debugMode = !debugMode);

		if (__bitmap == null) __bitmap = new BitmapData(1, 1, 0xFF000000);

		bgSprite = new Bitmap(__bitmap);
		bgSprite.alpha = 0;
		addChild(bgSprite);

		__addToList(fpsCounter = new FPSCounter());
		__addCategory(new FlixelInfo());
		__addCategory(new MusicBeatInfo());
		__addCategory(new SystemInfo());
	}

	function __addCategory(category:FramerateCategory) {
		categories.push(category);
		__addToList(category);
	}
	var __lastAddedSprite:DisplayObject = null;
	function __addToList(spr:DisplayObject) {
		spr.x = 0;
		spr.y = __lastAddedSprite != null ? (__lastAddedSprite.y + __lastAddedSprite.height) : 0;
		__lastAddedSprite = spr;
		addChild(spr);
	}

	var debugAlpha:Float = 0;
	public override function __enterFrame(t:Int) {
		debugAlpha = utils.system.FPSUtil.fpsLerp(debugAlpha, debugMode ? 1 : 0, .5);
		super.__enterFrame(t);
		bgSprite.alpha = debugAlpha * 0.5;

		x = offset.x;
		y = offset.y;

		var width = Math.max(fpsCounter.width, fpsCounter.width) + (x * 2);
		var height = fpsCounter.y + fpsCounter.height;
		bgSprite.x = -x;
		bgSprite.y = offset.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;

		var y:Float = height + 4;

		for(c in categories) {
			c.alpha = debugAlpha;
			c.x = FlxMath.lerp(-c.width - offset.x, 0, debugAlpha);
			c.y = y;
			y = c.y + c.height + 4;
		}
	}
}