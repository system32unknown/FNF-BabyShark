package objects;

import flixel.graphics.FlxGraphic;

class HealthIcon extends FlxSprite {
	static final prefix:String = 'icons/';
	static final defaultIcon:String = 'icon-face';

	public var iconZoom:Float = 1;
	public var sprTracker:FlxSprite;
	public var isPixelIcon(get, null):Bool;
	var isPlayer:Bool = false;
	public var animated:Bool;

	var char:String = '';
	
	public var iconType:String = 'vanilla';
	var availableStates:Int = 1;
	var state:Int = 0;
	var _scale:FlxPoint;
	final animatediconstates:Array<String> = ['normal', 'lose', 'win'];
	
	public static function returnGraphic(char:String, defaultIfMissing:Bool = false, ?allowGPU:Bool = true):FlxGraphic {
		var path:String = prefix + char;
		if (!Paths.fileExists('images/$path.png', IMAGE)) path = '${prefix}icon-$char'; //Older versions of psych engine's support
		if (!Paths.fileExists('images/$path.png', IMAGE)) { //Prevents crash from missing icon
			if (!defaultIfMissing) return null;
			path = prefix + defaultIcon;
			if (!Paths.fileExists('images/$path.png', IMAGE)) path = prefix + defaultIcon;
		}
		return Paths.image(path, allowGPU);
	}

	public function new(?char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true) {
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	@:noCompletion override function initVars():Void {
		super.initVars();
		_scale = FlxPoint.get();
	}

	override function destroy():Void {
		super.destroy();
		_scale = flixel.util.FlxDestroyUtil.put(_scale);
	}

	override function draw() {
		if (iconZoom == 1) return super.draw();
		_scale.copyFrom(scale);
		scale.scale(iconZoom);
		super.draw();
		_scale.copyTo(scale);
	}

	public function changeIcon(char:String, defaultIfMissing:Bool = true, ?allowGPU:Bool = true):Bool {
		if (this.char == char) return false;
		var graph:FlxGraphic = null;
		var name:String = 'icons/$char';

		animated = Paths.exists('images/$name.xml');

		if (graph == null) graph = returnGraphic(char, defaultIfMissing, allowGPU);
		else {
			availableStates = 1;
			this.char = char;
			state = 0;

			loadGraphic(graph, true, graph.width, graph.height);
			iconZoom = isPixelIcon ? 150 / graph.height : 1;

			updateHitbox();
			antialiasing = iconZoom < 2.5 && ClientPrefs.data.antialiasing;
			return true;
		}

		if (graph == null) return false;
		availableStates = Math.round(graph.width / graph.height);
		this.char = char;
		state = 0;

		if (!animated) {
			loadGraphic(graph, true, Math.floor(graph.width / availableStates), graph.height);
			iconZoom = isPixelIcon ? 150 / graph.height : 1;

			animation.add(char, [for (i in 0...availableStates) i], 0, false, isPlayer);
			animation.play(char);
		} else {
			frames = Paths.getSparrowAtlas(name);
			for (animstate in animatediconstates) if(getIconAnims(name).contains(animstate))
				animation.addByPrefix(animstate, animstate, 24, true, isPlayer, false);
			animation.play(animatediconstates[0]);
		}

		updateHitbox();
		antialiasing = iconZoom < 2.5 && ClientPrefs.data.antialiasing;
		return true;
	}

	override function updateHitbox() {
		if (iconType.toLowerCase() == 'center') centerOrigin();
		else if (iconType.toLowerCase() == 'psych') {
			super.updateHitbox();
			width *= iconZoom;
			height *= iconZoom;
			offset.set(-.5 * (frameWidth * iconZoom - frameWidth), -.5 * (frameHeight * iconZoom - frameHeight));
		} else super.updateHitbox();
	}

	public function getCharacter():String return char;

	@:noCompletion inline function get_isPixelIcon():Bool
		return char.endsWith('-pixel');

	public function setStateIndex(state:Int) {
		if (state >= availableStates) state = 0;
		if (this.state == state || animation.curAnim == null) return;
		animation.curAnim.curFrame = this.state = state;
	}

	public function setState(state:Int) {
		if (!animated) setStateIndex(state);
		else if (animation.exists(animatediconstates[state])) animation.play(animatediconstates[state]);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Std.isOfType(FlxG.state, PlayState) && (ClientPrefs.data.iconBounceType == 'Dave' || ClientPrefs.data.iconBounceType == 'GoldenApple'))
			offset.set(Std.int(FlxMath.bound(width - 150, 0)), Std.int(FlxMath.bound(height - 150, 0)));
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	function getIconAnims(file:String):Array<String> {
		final regNum:EReg = ~/[\d-]/;
		return CoolUtil.removeDupString([for (icon in new haxe.xml.Access(Xml.parse(Paths.getTextFromFile('images/$file.xml')).firstElement()).nodes.SubTexture) regNum.split(icon.att.name)[0]]);
	}
}