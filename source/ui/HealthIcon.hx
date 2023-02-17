package ui;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import utils.ClientPrefs;
import utils.CoolUtil;

class HealthIcon extends FlxSprite
{
	static final prefix:String = 'icons/';
	static final credits:String = 'credits/';
	static final defaultIcon:String = 'unknown';

	public var animated:Bool;
	public var iconOffsets:Array<Float> = [0, 0];
	public var sprTracker:FlxSprite;
	var isPlayer:Bool = false;
	var isCredit:Bool;

	var char:String = '';
	
	public var isPsych:Bool = false;
	var availableStates:Int = 1;
	var state:Int = 0;
	
	public static function returnGraphic(char:String, ?folder:String, defaultIfMissing:Bool = false, creditIcon:Bool = false):FlxGraphic {
		var path:String;
		if (creditIcon) {
			path = credits + ((folder != null || folder == '') ? '$folder/' : '') + char;
			if ((folder != null || folder == '') && !Paths.fileExists('images/$path.png', IMAGE)) path = credits + char;
			if (Paths.fileExists('images/$path.png', IMAGE)) return Paths.image(path);
			if (defaultIfMissing) return Paths.image(prefix + defaultIcon);
			return null;
		}
		path = prefix + char;
		if (!Paths.fileExists('images/$path.png', IMAGE)) path = '${prefix}icon-$char'; //Older versions of psych engine's support
		if (!Paths.fileExists('images/$path.png', IMAGE)) { //Prevents crash from missing icon
			if (!defaultIfMissing) return null;
			path = prefix + defaultIcon;
		}
		return Paths.image(path);
	}

	public function new(?char:String, ?folder:String, isPlayer:Bool = false, isCredit = false)
	{
		this.isPlayer = isPlayer;
		this.isCredit = isCredit;
		super();
		scrollFactor.set();
		changeIcon(char == null ? (isCredit ? defaultIcon : 'bf') : char, folder);
	}

	var iconSize:Float = 0;
	public function changeIcon(char:String, ?folder:String, defaultIfMissing:Bool = true):Bool {
		if (this.char == char) return false;
		var graph:FlxGraphic = null;

		if (isCredit) graph = returnGraphic(char, folder, false, true);
		if (graph == null) graph = returnGraphic(char, defaultIfMissing);
		else {
			this.char = char;

			iconSize = (isPsych ? (width - 150) / 2 : 0);
			iconOffsets[1] = iconOffsets[0] = iconSize;

			loadGraphic(graph);
			updateHitbox();
			state = 0;

			antialiasing = ClientPrefs.getPref('globalAntialiasing');
			if (char.endsWith('-pixel')) antialiasing = false;
			return true;
		}

		if (graph == null) return false;
		availableStates = Math.round(graph.width / graph.height);
		this.char = char;
		
		var animd:Bool = Paths.exists('images/icons/$char.xml');
		var jsonAtlas:Bool = false;
		if (!animd) {
			animd = Paths.exists('images/icons/$char.json');
			jsonAtlas = animd;
		}
		animated = animd;

		iconSize = (isPsych ? (width - 150) / 2 : 0);
		iconOffsets[1] = iconOffsets[0] = iconSize;
		if (!animd) {
			loadGraphic(graph, true, Math.floor(graph.width / availableStates), graph.height);
			updateHitbox();

			animation.add(char, CoolUtil.numberArray(availableStates), 0, false, isPlayer);
			animation.play(char);
		} else {
			frames = jsonAtlas ? Paths.getJsonAtlas(name) : Paths.getSparrowAtlas(name);
			animation.addByPrefix('idle', 'idle');
			animation.addByPrefix('dead', 'dead');
			animation.play('idle');
		}

		antialiasing = ClientPrefs.getPref('globalAntialiasing');
		if (char.endsWith('-pixel')) antialiasing = false;

		return true;
	}

	override function updateHitbox() {
		if (!isPsych) {
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
			offset.set(-.5 * (width - frameWidth), -.5 * (height - frameHeight));
			centerOrigin();
			return;
		} 
		super.updateHitbox();
		offset.set(iconOffsets[0], iconOffsets[1]);
	}

	public function getCharacter():String
		return char;

	public function setState(state:Int) {
		if (state >= availableStates) state = 0;
		if (animation.curAnim == null) return;
		animation.curAnim.curFrame = this.state = state;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		switch (ClientPrefs.getPref('IconBounceType')) {
			case "DaveAndBambi" | "Purgatory" | "GoldenApple" | "StridentCrisis":
				offset.set(Std.int(FlxMath.bound(width - 150, 0)), Std.int(FlxMath.bound(height - 150, 0)));
		}

		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}
}