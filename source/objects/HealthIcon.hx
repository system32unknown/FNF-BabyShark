package objects;

import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class HealthIcon extends FlxSprite
{
	static final prefix:String = 'icons/';
	static final credits:String = 'credits/';
	static final defaultIcon:String = 'icon-unknown';
	static final altDefaultIcon:String = 'icon-face';

	public var iconOffsets:Array<Float> = [0, 0];
	public var iconZoom:Float = 1;
	public var sprTracker:FlxSprite;
	public var isPixelIcon(get, null):Bool;
	var isPlayer:Bool = false;
	var isCredit:Bool;

	var char:String = '';
	
	public var iconType:String = 'vanilla';
	var availableStates:Int = 1;
	var state:Int = 0;
	var _scale:FlxPoint;
	
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
			path = prefix + altDefaultIcon;
			if (!Paths.fileExists('images/' + path + '.png', IMAGE, false, true)) path = prefix + defaultIcon;
		}
		return Paths.image(path);
	}

	public function new(?char:String, ?folder:String, isPlayer:Bool = false, isCredit = false) {
		this.isPlayer = isPlayer;
		this.isCredit = isCredit;
		super();
		scrollFactor.set();
		changeIcon(char == null ? (isCredit ? defaultIcon : 'bf') : char, folder);
	}

	@:noCompletion
	override function initVars():Void {
		super.initVars();
		_scale = FlxPoint.get();
	}

	override function destroy():Void {
		super.destroy();
		_scale = FlxDestroyUtil.put(_scale);
	}

	override function draw() {
		if (iconZoom == 1) return super.draw();
		_scale.copyFrom(scale);
		scale.scale(iconZoom);
		super.draw();
		_scale.copyTo(scale);
	}

	public function changeIcon(char:String, ?folder:String, defaultIfMissing:Bool = true):Bool {
		if (this.char == char) return false;
		var graph:FlxGraphic = null;

		if (isCredit) graph = returnGraphic(char, folder, false, true);
		if (graph == null) graph = returnGraphic(char, defaultIfMissing);
		else {
			availableStates = 1;
			this.char = char;
			state = 0;

			iconOffsets[1] = iconOffsets[0] = 0;
			loadGraphic(graph, true, graph.width, graph.height);
			iconZoom = isPixelIcon ? 150 / graph.height : 1;

			updateHitbox();
			antialiasing = iconZoom < 2.5 && ClientPrefs.getPref('Antialiasing');
			return true;
		}

		if (graph == null) return false;
		availableStates = Math.round(graph.width / graph.height);
		this.char = char;
		state = 0;

		iconOffsets[1] = iconOffsets[0] = 0;
		loadGraphic(graph, true, Math.floor(graph.width / availableStates), graph.height);
		iconZoom = isPixelIcon ? 150 / graph.height : 1;

		animation.add(char, CoolUtil.numberArray(availableStates), 0, false, isPlayer);
		animation.play(char);

		updateHitbox();
		antialiasing = iconZoom < 2.5 && ClientPrefs.getPref('Antialiasing');
		return true;
	}

	override function updateHitbox() {
		if (iconType.toLowerCase() == 'center') centerOrigin();
		else if (iconType.toLowerCase() == 'psych') {
			width = Math.abs(scale.x) * frameWidth * iconZoom;
			height = Math.abs(scale.y) * frameHeight * iconZoom;
			offset.set(-.5 * (frameWidth * iconZoom - frameWidth) + iconOffsets[0], -.5 * (frameHeight * iconZoom - frameHeight) + iconOffsets[1]);
		} else {
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
			offset.set(-.5 * (width - frameWidth), -.5 * (height - frameHeight));
		}
	}

	public function getCharacter():String
		return char;

	@:noCompletion
	inline function get_isPixelIcon():Bool
		return char.substr(-6, 6) == '-pixel';

	public function setState(state:Int) {
		if (state >= availableStates) state = 0;
		if (animation.curAnim == null) return;
		animation.curAnim.curFrame = this.state = state;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		switch (ClientPrefs.getPref('IconBounceType')) {
			case "Dave" | "GoldenApple":
				offset.set(Std.int(FlxMath.bound(width - 150, 0)), Std.int(FlxMath.bound(height - 150, 0)));
		}

		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}
}