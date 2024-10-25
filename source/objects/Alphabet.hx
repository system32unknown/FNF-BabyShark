package objects;

import haxe.Json;
#if !MODS_ALLOWED import openfl.utils.Assets; #end
import flixel.util.FlxDestroyUtil;

enum abstract AlphabetAlignment(String) from String to String {
    var LEFT:AlphabetAlignment = 'left';
    var CENTER:AlphabetAlignment = 'center';
    var RIGHT:AlphabetAlignment = 'right';

	@:from
	public static function fromString(alignment:String):AlphabetAlignment {
		return switch (alignment.toLowerCase().trim()) {
			case 'right': RIGHT;
			case 'center', 'centered': CENTER;
			default: LEFT;
		}
	}
}

enum abstract AlphabetGlyphType(String) from String to String {
	var BOLD:AlphabetGlyphType = 'bold';
	var NORMAL:AlphabetGlyphType = 'normal';
}

class Alphabet extends FlxTypedSpriteGroup<AlphaCharacter> {
	public var text(default, set):String;

	public var type:AlphabetGlyphType;

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):AlphabetAlignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;

	public var distancePerItem:FlxPoint = FlxPoint.get(20, 120);
	public var startPosition:FlxPoint = FlxPoint.get(); //for the calculations

	public function new(x:Float, y:Float, text:String = "", ?type:AlphabetGlyphType = BOLD, ?alignment:AlphabetAlignment = LEFT) {
		super(x, y);

		this.startPosition.set(x, y);
		@:bypassAccessor this.alignment = alignment;
		this.type = type;
		this.text = text;
	}

	function set_alignment(align:AlphabetAlignment) {
		alignment = align;
		updateAlignment();
		return align;
	}

	function updateAlignment() {
		for (letter in members) {
			var newOffset:Float = switch (alignment) {
				case CENTER: letter.rowWidth * .5;
				case RIGHT: letter.rowWidth;
				default: 0;
			}
	
			letter.offset.x -= letter.alignOffset;
			letter.alignOffset = newOffset * scale.x;
			letter.offset.x += letter.alignOffset;
		}
	}

	function set_text(newText:String):String {
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		return text = newText;
	}

	public function clearLetters() {
		var i:Int = members.length;
		while (i > 0) {
			--i;
			var letter:AlphaCharacter = members[i];
			if (letter != null) {
				letter.kill();
				remove(letter);
			}
		}
		clear();
		rows = 0;
	}

	public function setScale(newX:Float, ?newY:Float = 0.0) {
		var lastX:Float = scale.x;
		var lastY:Float = scale.y;
		if (newY == 0.0) newY = newX;
		@:bypassAccessor scaleX = newX;
		@:bypassAccessor scaleY = newY;

		scale.set(newX, newY);
		softReloadLetters(newX / lastX, newY / lastY);
	}

	function set_scaleX(value:Float) {
		if (value == scaleX) return value;

		var ratio:Float = value / scale.x;
		scale.x = value;
		scaleX = value;
		softReloadLetters(ratio, 1);
		return value;
	}

	function set_scaleY(value:Float) {
		if (value == scaleY) return value;

		var ratio:Float = value / scale.y;
		scale.y = value;
		scaleY = value;
		softReloadLetters(1, ratio);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ratioY:Float = 0.0) {
		if (ratioY == 0.0) ratioY = ratioX;
		for (letter in members) if (letter != null) letter.setupAlphaCharacter((letter.x - x) * ratioX + x, (letter.y - y) * ratioY + y);
	}

	override function update(elapsed:Float) {
		if (!isMenuItem) {
			super.update(elapsed);
			return;
		}

		var lerpVal:Float = Math.exp(-elapsed * 9.6);
		if (changeX) x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x, x, lerpVal);
		if (changeY) y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y, y, lerpVal);
		super.update(elapsed);
	}

	override function destroy() {
		distancePerItem = FlxDestroyUtil.put(distancePerItem);
		startPosition = FlxDestroyUtil.put(startPosition);
		super.destroy();
	}

	public function snapToPosition() {
		if (!isMenuItem) return;

		if (changeX) x = (targetY * distancePerItem.x) + startPosition.x;
		if (changeY) y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
	}

	static var Y_PER_ROW:Float = 85;

	function createLetters(newText:String) {
		var consecutiveSpaces:Int = 0;

		var xPos:Float = 0;
		var rowData:Array<Float> = [];
		rows = 0;
		for (i in 0...newText.length) {
			var character:String = newText.charAt(i);
			if (character == '\n') {
				xPos = 0;
				rows++;
				continue;
			}
			
			var spaceChar:Bool = (character == " " || (type == BOLD && character == "_"));
			if (spaceChar) consecutiveSpaces++;

			if (AlphaCharacter.allLetters.exists(character.toLowerCase()) && (type == NORMAL || !spaceChar)) {
				if (consecutiveSpaces > 0) {
					xPos += 28 * consecutiveSpaces * scaleX;
					rowData[rows] = xPos;
					if (type == NORMAL && xPos >= FlxG.width * 0.65) {
						xPos = 0;
						rows++;
					}
				}
				consecutiveSpaces = 0;

				var letter:AlphaCharacter = cast recycle(AlphaCharacter, true);
				letter.scale.set(scaleX, scaleY);
				letter.rowWidth = 0;

				letter.setupAlphaCharacter(xPos, rows * Y_PER_ROW * scale.y, character, type);
				@:privateAccess letter.parent = this;

				letter.row = rows;
				var off:Float = 0;
				if (type == NORMAL) off = 2;
				xPos += letter.width + (letter.letterOffset[0] + off) * scale.x;
				rowData[rows] = xPos;

				add(letter);
			}
		}

		for (letter in members) letter.rowWidth = rowData[letter.row] / scale.x;
		if (members.length > 0) rows++;
	}
}


///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

typedef Letter = {
	?anim:Null<String>,
	?offsets:Array<Float>,
	?offsetsBold:Array<Float>
}

class AlphaCharacter extends FlxSprite {
	public var image(default, set):String;
	public static var allLetters:Map<String, Null<Letter>>;

	public static function loadAlphabetData(request:String = 'alphabet') {
		var path:String = Paths.getPath('images/$request.json');
		if(!#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT)#end)
			path = Paths.getPath('images/alphabet.json');

		allLetters = new Map<String, Null<Letter>>();
		try {
			var data:Dynamic = Json.parse(#if MODS_ALLOWED File.getContent #else Assets.getText #end(path));
			if (data.allowed != null && data.allowed.length > 0) {
				for (i in 0...data.allowed.length) {
					var char:String = data.allowed.charAt(i);
					if (char == ' ') continue;

					allLetters.set(char.toLowerCase(), null); //Allows character to be used in Alphabet
				}
			}

			if (data.characters != null) {
				for (char in Reflect.fields(data.characters)) {
					var letterData = Reflect.field(data.characters, char);
					var character:String = char.toLowerCase().substr(0, 1);
					if ((letterData.animation != null || letterData.normal != null) && allLetters.exists(character))
						allLetters.set(character, {anim: letterData.animation, offsets: letterData.normal, offsetsBold: letterData.type});
				}
			}
			trace('Reloaded members successfully ($path)!');
		} catch(e:Dynamic) FlxG.log.error('Error on loading alphabet data: $e');

		if (!allLetters.exists('?')) allLetters.set('?', {anim: 'question'});
	}

	var parent:Alphabet;
	public var alignOffset:Float = 0; //Don't change this
	public var letterOffset:Array<Float> = [0, 0];

	public var row:Int = 0;
	public var rowWidth:Float = 0;
	public var character:String = '?';
	public function new() {
		super(x, y);
		image = 'alphabet';
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public var curLetter:Letter = null;
	public function setupAlphaCharacter(x:Float, y:Float, ?character:String = null, ?type:AlphabetGlyphType) {
		this.x = x;
		this.y = y;

		if (parent != null) {
			if (type == null) type = parent.type;
			this.scale.set(parent.scaleX, parent.scaleY);
		}
		
		if (character != null) {
			this.character = character;
			curLetter = null;
			var lowercase:String = this.character.toLowerCase();
			if (allLetters.exists(lowercase)) curLetter = allLetters.get(lowercase);
			else curLetter = allLetters.get('?');

			var postfix:String = '';
			if (type == NORMAL) {
				if (isTypeAlphabet(lowercase)) {
					if (lowercase != this.character)
						postfix = ' uppercase';
					else postfix = ' lowercase';
				} else postfix = ' normal';
			} else postfix = ' bold';

			var alphaAnim:String = lowercase;
			if (curLetter != null && curLetter.anim != null) alphaAnim = curLetter.anim;

			var anim:String = alphaAnim + postfix;
			animation.addByPrefix(anim, anim, 24);
			animation.play(anim, true);
			if (animation.curAnim == null) {
				if (postfix != ' bold') postfix = ' normal';
				anim = 'question' + postfix;
				animation.addByPrefix(anim, anim, 24);
				animation.play(anim, true);
			}
		}
		updateHitbox();
	}

	public static function isTypeAlphabet(c:String):Bool { // thanks kade
		var ascii:Int = c.fastCodeAt(0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246) || (ascii >= 248 && ascii <= 255);
	}

	function set_image(name:String) {
		if (frames == null) {
			image = name;
			frames = Paths.getSparrowAtlas(name);
			return name;
		}

		var lastAnim:String = null;
		if (animation != null) lastAnim = animation.name;
		frames = Paths.getSparrowAtlas(image = name);
		this.scale.set(parent.scaleX, parent.scaleY);
		alignOffset = 0;
		
		if (lastAnim != null) {
			animation.addByPrefix(lastAnim, lastAnim, 24);
			animation.play(lastAnim, true);
			updateHitbox();
		}
		return name;
	}

	public function updateLetterOffset() {
		if (animation.curAnim == null) return;

		var add:Float = 110;
		if (animation.curAnim.name.endsWith('bold')) {
			if (curLetter != null && curLetter.offsetsBold != null) {
				letterOffset[0] = curLetter.offsetsBold[0];
				letterOffset[1] = curLetter.offsetsBold[1];
			}
			add = 70;
		} else {
			if (curLetter != null && curLetter.offsets != null) {
				letterOffset[0] = curLetter.offsets[0];
				letterOffset[1] = curLetter.offsets[1];
			}
		}
		add *= scale.y;
		offset.add(letterOffset[0] * scale.x, letterOffset[1] * scale.y - (add - height));
	}

	override public function updateHitbox() {
		super.updateHitbox();
		updateLetterOffset();
	}
}