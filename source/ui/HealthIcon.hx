package ui;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import utils.ClientPrefs;
import utils.CoolUtil;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	
	public var icontype:String = 'classic';
	public var isPsych:Bool = false;
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
			final iconTypes:Array<String> = ['single', 'classic', 'winning'];
			var index:Int = Math.floor(width / 150);
			if (index - 1 <= iconTypes.length) {
				icontype = iconTypes[index - 1];
				iconnum = index; // Thanks to EyeDaleHim#8508 for Improving code!
				iconarray = CoolUtil.numberArray(index);
			}
			
			loadGraphic(file, true, Math.floor(width / iconnum), Math.floor(height)); //Then load it fr
			iconOffsets[0] = (width - 150) / iconnum;
			iconOffsets[1] = (width - 150) / iconnum;
			
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