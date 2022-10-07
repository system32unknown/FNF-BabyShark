package ui;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import utils.ClientPrefs;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var icontype:String = 'classic';
	private var iconnum:Int = 0;
	private var iconarray:Array<Int>;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);

			loadGraphic(file);
			switch (width) {
				case 150: 
					icontype = 'single';
					iconnum = 1;
					iconarray = [0];
				case 300: 
					icontype = 'classic';
					iconnum = 2;
					iconarray = [0, 1];
				case 450: 
					icontype = 'winning';
					iconnum = 3;
					iconarray = [0, 1, 2];
			}
			
			loadGraphic(file, true, Math.floor(width / iconnum), Math.floor(height)); //Then load it fr
			if (ClientPrefs.getPref('HealthTypes') != 'Vanilla' || ClientPrefs.getPref('HealthTypes') != "Exe") {
				iconOffsets[0] = (width - 150) / iconnum;
				iconOffsets[1] = (width - 150) / iconnum;
				updateHitbox();
			}

			animation.add(char, iconarray, 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.getPref('globalAntialiasing');
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	override function updateHitbox() {
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (ClientPrefs.getPref('IconBounceType') == "DaveAndBambi" || ClientPrefs.getPref('IconBounceType') == "Purgatory" || ClientPrefs.getPref('IconBounceType') == "GoldenApple")
			offset.set(Std.int(FlxMath.bound(width - 150, 0)), Std.int(FlxMath.bound(height - 150, 0)));

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}
}