package objects;

#if AWARDS_ALLOWED
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.Lib;

class AchievementPopup extends openfl.display.Sprite {
	var lastScale:Float = 1;

	public function new(achieve:String) {
		super();

		// bg
		graphics.beginFill(FlxColor.BLACK);
		graphics.drawRoundRect(0, 0, 420, 130, 16, 16);

		// achievement icon
		var graphic:flixel.graphics.FlxGraphic = null;
		var hasAntialias:Bool = Settings.data.antialiasing;
		var image:String = 'achievements/$achieve';

		var achievement:Award = null;
		if (Awards.exists(achieve)) achievement = Awards.get(achieve);

		#if MODS_ALLOWED
		var lastMod:String = Mods.currentModDirectory;
		if (achievement != null) Mods.currentModDirectory = achievement.mod ?? '';
		#end

		if (Paths.fileExists('images/$image-pixel.png', IMAGE)) {
			graphic = Paths.image('$image-pixel', false);
			hasAntialias = false;
		} else graphic = Paths.image(image, false);

		#if MODS_ALLOWED
		Mods.currentModDirectory = lastMod;
		#end

		if (graphic == null) graphic = Paths.image('unknownMod', false);

		var sizeX:Int = 100;
		var sizeY:Int = 100;

		var imgX:Int = 15;
		var imgY:Int = 15;
		var image:BitmapData = graphic.bitmap;
		graphics.beginBitmapFill(image, new Matrix(sizeX / image.width, 0, 0, sizeY / image.height, imgX, imgY), false, hasAntialias);
		graphics.drawRect(imgX, imgY, sizeX + 10, sizeY + 10);

		// achievement name/description
		var name:String = 'Unknown';
		var desc:String = 'Description not found';
		if (achievement != null) {
			if (achievement.name != null) name = Language.getPhrase('achievement_$achieve', achievement.name);
			if (achievement.description != null) desc = Language.getPhrase('description_$achieve', achievement.description);
		}

		var textX:Int = sizeX + imgX + 15;
		var textY:Int = imgY + 20;

		var text:FlxText = new FlxText(0, 0, 270, 'TEST!!!', 16);
		text.setFormat(Paths.font("vcr.ttf"), 16);
		drawTextAt(text, name, textX, textY);
		drawTextAt(text, desc, textX, textY + 30);
		graphics.endFill();

		text.graphic.bitmap.dispose();
		text.graphic.bitmap.disposeImage();
		text.destroy();

		// other stuff
		FlxG.stage.addEventListener(Event.RESIZE, onResize);
		addEventListener(Event.ENTER_FRAME, update);

		FlxG.game.addChild(this); // Don't add it below mouse, or it will disappear once the game changes states

		// fix scale
		lastScale = (FlxG.stage.stageHeight / FlxG.height);
		this.x = 20 * lastScale;
		this.y = -130 * lastScale;
		this.scaleX = lastScale;
		this.scaleY = lastScale;
		intendedY = 20;
	}

	var bitmaps:Array<BitmapData> = [];
	function drawTextAt(text:FlxText, str:String, textX:Float, textY:Float) {
		text.text = str;
		text.updateHitbox();

		var clonedBitmap:BitmapData = text.graphic.bitmap.clone();
		bitmaps.push(clonedBitmap);
		graphics.beginBitmapFill(clonedBitmap, new Matrix(1, 0, 0, 1, textX, textY), false, false);
		graphics.drawRect(textX, textY, text.width + textX, text.height + textY);
	}

	var lerpTime:Float = 0;
	var countedTime:Float = 0;
	var timePassed:Float = -1;

	public var intendedY:Float = 0;

	function update(_:Event) {
		if (timePassed < 0) {
			timePassed = Lib.getTimer();
			return;
		}

		var time:Int = Lib.getTimer();
		var elapsed:Float = (time - timePassed) / 1000;
		timePassed = time;

		if (elapsed >= .5) return; // most likely passed through a loading

		countedTime += elapsed;
		if (countedTime < 3) {
			lerpTime = Math.min(1, lerpTime + elapsed);
			y = ((FlxEase.elasticOut(lerpTime) * (intendedY + 130)) - 130) * lastScale;
		} else {
			y -= FlxG.height * 2 * elapsed * lastScale;
			if (y <= -130 * lastScale) destroy();
		}
	}

	function onResize(_:Event) {
		var mult:Float = (FlxG.stage.stageHeight / FlxG.height);
		scaleX = mult;
		scaleY = mult;

		x = (mult / lastScale) * x;
		y = (mult / lastScale) * y;
		lastScale = mult;
	}

	public function destroy() {
		Awards._popups.remove(this);

		if (FlxG.game.contains(this)) FlxG.game.removeChild(this);
		FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		removeEventListener(Event.ENTER_FRAME, update);
		deleteClonedBitmaps();
	}

	function deleteClonedBitmaps() {
		for (clonedBitmap in bitmaps) if (clonedBitmap != null) clonedBitmap.dispose();
		bitmaps = null;
	}
}
#end