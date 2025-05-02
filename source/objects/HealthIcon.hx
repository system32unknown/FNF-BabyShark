package objects;

import flixel.graphics.FlxGraphic;

typedef BopInfo = {
	var curBeat:Int;
	var ?playbackRate:Float;
	var ?gfSpeed:Int;
	var ?percent:Float;
}

class HealthIcon extends FlxSprite {
	static final prefix:String = 'icons/';
	static final defaultIcon:String = 'icon-face';

	public var iconZoom:Float = 1;
	public var sprTracker:FlxSprite;
	public var isPixelIcon(get, null):Bool;
	public var animated:Bool;

	var isPlayer:Bool = false;
	var char:String = '';
	
	public var iconType:String = 'vanilla';
	public var iSize:Int = 1;

	var state:Int = 0;
	var _scale:FlxPoint;
	final animatediconstates:Array<String> = ['normal', 'lose', 'win'];
	var iconOffsets:Array<Float> = [0.0, 0.0];

	public static function returnGraphic(char:String, defaultIfMissing:Bool = false, ?allowGPU:Bool = true):FlxGraphic {
		var path:String = prefix + char;
		if (!Paths.fileExists('images/$path.png', IMAGE)) path = prefix + 'icon-$char'; //Older versions of psych engine's support
		if (!Paths.fileExists('images/$path.png', IMAGE)) { // Prevents crash from missing icon
			if (!defaultIfMissing) return null;
			path = prefix + defaultIcon;
			if (!Paths.fileExists('images/$path.png', IMAGE)) path = prefix + defaultIcon;
		}
		return Paths.image(path, allowGPU);
	}

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true) {
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
		_scale.put();
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

		animated = Paths.exists(Paths.getPath('images/$name.xml'));

		if (graph == null) graph = returnGraphic(char, defaultIfMissing, allowGPU);
		else {
			iSize = 1;
			this.char = char;
			state = 0;

			iconOffsets = [.0, .0];
			loadGraphic(graph, true, graph.width, graph.height);
			iconZoom = isPixelIcon ? 150 / graph.height : 1;

			updateHitbox();
			antialiasing = iconZoom < 2.5 && Settings.data.antialiasing;
			return true;
		}

		if (graph == null) return false;
		iSize = Math.round(graph.width / graph.height);
		this.char = char;
		state = 0;

		if (!animated) {
			loadGraphic(graph, true, Math.floor(graph.width / iSize), Math.floor(graph.height));
			iconZoom = isPixelIcon ? 150 / graph.height : 1;

			animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
			iconOffsets = [(width - 150) / iSize, (height - 150) / iSize];
			animation.play(char);
		} else {
			frames = Paths.getSparrowAtlas(name);
			for (animstate in animatediconstates) if (getIconAnims(name).contains(animstate))
				animation.addByPrefix(animstate, animstate, 24, true, isPlayer, false);
			animation.play(animatediconstates[0]);
		}

		updateHitbox();
		antialiasing = iconZoom < 2.5 && Settings.data.antialiasing;
		return true;
	}

	public var autoOffset:Bool = false;
	override function updateHitbox() {
		if (iconType.toLowerCase() == 'center') centerOrigin();
		else if (iconType.toLowerCase() == 'psych') {
			super.updateHitbox();
			width *= iconZoom;
			height *= iconZoom;
			offset.set(-.5 * (frameWidth * iconZoom - frameWidth), -.5 * (frameHeight * iconZoom - frameHeight));
		} else super.updateHitbox();
		if (autoOffset) offset.set(iconOffsets[0], iconOffsets[1]);
	}

	public function getCharacter():String return char;

	@:noCompletion inline function get_isPixelIcon():Bool
		return char.endsWith('-pixel');

	public function setStateIndex(state:Int):Void {
		if (state >= iSize) state = 0;
		if (this.state == state || animation.curAnim == null) return;
		animation.curAnim.curFrame = this.state = state;
	}

	public function setState(state:Int):Void {
		if (!animated) setStateIndex(state);
		else if (animation.exists(animatediconstates[state])) animation.play(animatediconstates[state]);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Std.isOfType(FlxG.state, PlayState) && (Settings.data.iconBopType == 'Dave' || Settings.data.iconBopType == 'GoldenApple'))
			offset.set(Std.int(FlxMath.bound(width - 150, 0)), Std.int(FlxMath.bound(height - 150, 0)));
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public var curBopType(default, set):String = "None";

	public dynamic function bopUpdate(e:Float, rate:Float):Void {
		switch (curBopType.toLowerCase()) {
			case "old": setGraphicSize(Std.int(FlxMath.lerp(150, width, .5)));
			case "psych":
				var mult:Float = FlxMath.lerp(1, scale.x, Math.exp(-e * 9 * rate));
				scale.set(mult, mult);
			case "dave": setGraphicSize(Std.int(FlxMath.lerp(150, width, .88)), Std.int(FlxMath.lerp(150, height, .88)));
		}
		updateHitbox();
	}

	/**
	 * Internal function to animate the Icon.
	 * @param bopInfo {curBeat, playbackRate, gfSpeed, healthBarPercent} curBeat is mandatory, the rest are limited to PlayState.
	 * @param iconAnim The name of the Animation, set to "Client"
	 * @param type (0 = BF, 1 = DAD)
	 * Values are necessary for proper calculations!!
	 */
	public dynamic function bop(bopInfo:BopInfo, iconAnim:String = "Settings", type:Int = 0):Void {
		if (iconAnim.toLowerCase() == "settings" || iconAnim.toLowerCase() == "clientPrefs" || iconAnim.toLowerCase() == "client") iconAnim = Settings.data.iconBopType;
		if (iconAnim == "None") return;
		if (curBopType != iconAnim) curBopType = iconAnim;

		final info:BopInfo = checkInfo(bopInfo);
		if (info.curBeat % info.gfSpeed == 0) {
			switch (iconAnim.toLowerCase()) { // Messy Math hell jumpscare (it is more customizeable though)
				case "old": setGraphicSize(Std.int(width + 30));
				case "psych": scale.set(1.2, 1.2);
				case "dave":
					var funny:Float = Math.max(Math.min(info.percent, 1.9), .1);
					if (type == 0) setGraphicSize(Std.int(width + (50 * (funny + .1))), Std.int(height - (25 * funny)));
					else if (type == 1) setGraphicSize(Std.int(width + (50 * ((2 - funny) + .1))), Std.int(height - (25 * ((2 - funny) + .1))));
				case "goldenapple":
					var iconAngle:Float = (info.curBeat % (info.gfSpeed * 2) == 0 * info.playbackRate ? -15 : 15);
					if (type == 0) {
						scale.set(1.1, (info.curBeat % (info.gfSpeed * 2) == 0 * info.playbackRate ? .8 : 1.3));
						FlxTween.angle(this, iconAngle, 0, Conductor.crochet / 1300 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
					} else if (type == 1) {
						scale.set(1.1, (info.curBeat % (info.gfSpeed * 2) == 0 * info.playbackRate ? 1.3 : .8));
						FlxTween.angle(this, -iconAngle, 0, Conductor.crochet / 1300 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
					}
					FlxTween.tween(this, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
			}
		}
		updateHitbox();
	}

	function set_curBopType(newType:String):String { // Resets values
		curBopType = newType;
		angle = 0;
		scale.set(1, 1);
		setGraphicSize(150, 150);
		updateHitbox();
		return curBopType;
	}

	inline function checkInfo(oldInfo:BopInfo):BopInfo {
		return {
			curBeat: oldInfo.curBeat,
			playbackRate: oldInfo.playbackRate ?? 1,
			gfSpeed: oldInfo.gfSpeed ?? 1,
			percent: oldInfo.percent ?? 50
		};
	}

	function getIconAnims(file:String):Array<String> {
		final regNum:EReg = ~/[\d-]/;
		return Util.removeDupString([for (icon in new haxe.xml.Access(Xml.parse(Paths.getTextFromFile('images/$file.xml')).firstElement()).nodes.SubTexture) regNum.split(icon.att.name)[0]]);
	}
}